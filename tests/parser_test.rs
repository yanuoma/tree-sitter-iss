//! Integration tests for the Inno Setup grammar.
//!
//! These cover the features that make Inno Setup awkward to parse, so a
//! regression in the external scanner or in the section dispatch shows up here
//! rather than in an editor.

use tree_sitter::{Parser, Query, QueryCursor, StreamingIterator};

fn parser() -> Parser {
    let mut parser = Parser::new();
    parser
        .set_language(&tree_sitter_iss::LANGUAGE.into())
        .expect("Error loading Inno Setup parser");
    parser
}

fn parse(source: &str) -> tree_sitter::Tree {
    parser().parse(source, None).expect("parse returned None")
}

/// Collect the source text of every node captured by `pattern`.
fn captured_text<'a>(source: &'a str, tree: &tree_sitter::Tree, pattern: &str) -> Vec<&'a str> {
    let language = tree_sitter_iss::LANGUAGE.into();
    let query = Query::new(&language, pattern).expect("test query failed to compile");
    let mut cursor = QueryCursor::new();
    let mut matches = cursor.matches(&query, tree.root_node(), source.as_bytes());

    let mut out = Vec::new();
    while let Some(m) = matches.next() {
        for cap in m.captures {
            out.push(&source[cap.node.byte_range()]);
        }
    }
    out
}

#[test]
fn parses_a_complete_script_without_errors() {
    let tree = parse(include_str!("../examples/realistic.iss"));
    assert!(
        !tree.root_node().has_error(),
        "expected a clean parse:\n{}",
        tree.root_node().to_sexp()
    );
}

#[test]
fn setup_and_files_sections_use_different_entry_syntax() {
    // The same `;` character is a comment at the start of a line and a
    // parameter separator in the middle of one. This only works because the
    // parser is in a different state inside each section.
    let tree =
        parse("[Setup]\nAppName=My Program\n\n[Files]\nSource: \"a.exe\"; DestDir: \"{app}\"\n");
    let sexp = tree.root_node().to_sexp();

    assert!(!tree.root_node().has_error(), "{sexp}");
    assert!(sexp.contains("directive_entry"), "{sexp}");
    assert!(sexp.contains("parameter_entry"), "{sexp}");
}

#[test]
fn semicolon_at_line_start_is_a_comment_not_a_separator() {
    let tree = parse("[Files]\n; just a comment\nSource: \"a.exe\"; DestDir: \"{app}\"\n");
    let sexp = tree.root_node().to_sexp();

    assert!(!tree.root_node().has_error(), "{sexp}");
    assert!(sexp.contains("comment"), "{sexp}");
}

#[test]
fn constants_nest() {
    // `{cm:UninstallProgram,{cm:MyAppName}}` cannot be matched by a regular
    // expression, because braces have to be balanced. The external scanner
    // counts depth, so the whole thing must come back as ONE constant node.
    let source = "[Icons]\nName: \"{group}\\{cm:UninstallProgram,{cm:MyAppName}}\"\n";
    let tree = parse(source);
    assert!(
        !tree.root_node().has_error(),
        "{}",
        tree.root_node().to_sexp()
    );

    let constants = captured_text(source, &tree, "(constant) @c");
    assert!(
        constants.contains(&"{cm:UninstallProgram,{cm:MyAppName}}"),
        "nested constant was not captured as a single node, got: {constants:?}"
    );
}

#[test]
fn code_section_is_captured_whole_and_brackets_inside_do_not_end_it() {
    // A `[` inside a Pascal string literal must NOT be treated as the start of
    // the next section.
    let source = concat!(
        "[Code]\n",
        "function Foo(): Boolean;\n",
        "begin\n",
        "  MsgBox('[Setup] is not a section here', mbError, MB_OK);\n",
        "end;\n"
    );
    let tree = parse(source);
    assert!(
        !tree.root_node().has_error(),
        "{}",
        tree.root_node().to_sexp()
    );

    let blocks = captured_text(source, &tree, "(pascal_code) @c");
    let text = blocks.first().expect("no pascal_code node produced");
    assert!(
        text.contains("[Setup] is not a section here"),
        "the [Code] block was truncated early: {text:?}"
    );
    assert!(
        text.contains("end;"),
        "the [Code] block is missing its tail"
    );
}

#[test]
fn ispp_macros_span_lines_with_backslash_continuations() {
    let tree = parse(concat!(
        "#define Exec(str Cmd) \\\n",
        "  Local[0] = Param + \" \" + AddQuotes(Cmd), \\\n",
        "  Local[0]\n"
    ));
    assert!(
        !tree.root_node().has_error(),
        "{}",
        tree.root_node().to_sexp()
    );
}

#[test]
fn a_url_in_a_value_is_not_a_comment() {
    // `//` starts a comment, but only where an entry may begin.
    let tree = parse("[Setup]\nAppPublisherURL=https://example.com/path\n");
    let sexp = tree.root_node().to_sexp();

    assert!(!tree.root_node().has_error(), "{sexp}");
    assert!(
        !sexp.contains("comment"),
        "the URL was misparsed as a comment: {sexp}"
    );
}

#[test]
fn strings_escape_quotes_by_doubling_them() {
    let tree = parse("[Files]\nSource: \"a \"\"quoted\"\" name.dll\"; DestDir: \"{app}\"\n");
    let sexp = tree.root_node().to_sexp();

    assert!(!tree.root_node().has_error(), "{sexp}");
    assert!(sexp.contains("escaped_quote"), "{sexp}");
}

#[test]
fn recovers_locally_from_a_malformed_section_header() {
    // A broken header should not cascade: later sections must still parse.
    let tree = parse(concat!(
        "[Setup]\n",
        "AppName=Good\n",
        "\n",
        "[Files\n",
        "Source: \"a.exe\"; DestDir: \"{app}\"\n",
        "\n",
        "[Icons]\n",
        "Name: \"{group}\\Still Parsed\"\n"
    ));
    let sexp = tree.root_node().to_sexp();

    // Three section headers survive even though the middle one is malformed.
    assert_eq!(
        sexp.matches("section_header").count(),
        3,
        "error recovery did not resynchronise: {sexp}"
    );
}

#[test]
fn bundled_queries_are_valid() {
    let language = tree_sitter_iss::LANGUAGE.into();

    Query::new(&language, tree_sitter_iss::HIGHLIGHTS_QUERY)
        .expect("queries/highlights.scm failed to compile");
    Query::new(&language, tree_sitter_iss::INJECTIONS_QUERY)
        .expect("queries/injections.scm failed to compile");
}

/// Parse every script in the local validation corpus.
///
/// The corpus is third-party code from other projects, so it is **not**
/// vendored into this repository (see `.gitignore`). Populate it locally with
/// `scripts/fetch-corpus.ps1`; when it is absent this test reports that it was
/// skipped rather than failing a fresh clone.
#[test]
fn parses_the_whole_local_corpus() {
    let mut parser = parser();
    let mut checked = 0;

    for dir in ["examples/real", "examples/wild"] {
        let Ok(entries) = std::fs::read_dir(dir) else {
            continue;
        };
        for entry in entries.flatten() {
            let path = entry.path();
            if path.extension().and_then(|e| e.to_str()) != Some("iss") {
                continue;
            }
            let Ok(source) = std::fs::read_to_string(&path) else {
                continue; // skip files that are not valid UTF-8
            };
            let tree = parser.parse(&source, None).expect("parse returned None");
            assert!(
                !tree.root_node().has_error(),
                "{} failed to parse cleanly",
                path.display()
            );
            checked += 1;
        }
    }

    if checked == 0 {
        eprintln!("local corpus not present, skipping (run scripts/fetch-corpus.ps1)");
    } else {
        eprintln!("parsed {checked} real-world scripts without errors");
    }
}
