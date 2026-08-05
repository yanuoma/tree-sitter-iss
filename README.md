# tree-sitter-iss

A [tree-sitter] grammar for **Inno Setup** (`.iss`) scripts.

[![crates.io](https://img.shields.io/crates/v/tree-sitter-iss.svg)](https://crates.io/crates/tree-sitter-iss)

Inno Setup had no tree-sitter grammar before this one. It is not a trivial
config format: a single `.iss` file mixes a line-oriented INI-like syntax, a C
style preprocessor, and a complete Pascal program.

## Status

| Check | Result |
| --- | --- |
| Official example scripts ([`jrsoftware/issrc`]) | **22 / 22** parse, 0 errors |
| Real-world scripts scraped from public GitHub repos | **48 / 48** parse, 0 errors |
| `tree-sitter test` corpus | **8 / 8** pass |
| Highlight patterns that match something | **44 / 44** |
| `cargo test` | **14 / 14** pass |
| Throughput | ~16 MB/s |
| Error recovery | localized (`MISSING` node, no cascade) |

The 70-script corpus is other projects' code under their own licenses, so it is
fetched on demand by `scripts/fetch-corpus.ps1` rather than vendored here. The
tests do not depend on it: `examples/patterns.iss` is a self-authored fixture
that exercises every highlight pattern, so the checks above hold on a fresh
clone and in CI.

## Installing in Neovim

The repository is also a Neovim plugin, so no configuration is required:

```lua
-- lazy.nvim
{
  "yanuoma/tree-sitter-iss",
  version = "*",
  lazy = false,
  dependencies = { "nvim-treesitter/nvim-treesitter" },
}
```

`plugin/tree-sitter-iss.lua` registers the parser with nvim-treesitter against
this checkout, installs both `iss` and `pascal`, and starts highlighting for the
`iss` filetype (which Neovim already maps `*.iss` and `*.isl` to). `version = "*"`
tracks the latest release tag, so updates only ever land on a released version.

Set `vim.g.tree_sitter_iss_auto_install = false` to register the parser without
installing anything automatically.

## Dependency: tree-sitter-pascal

A `[Code]` section is a complete Pascal Script program, and
[`queries/injections.scm`](queries/injections.scm) hands it to
[`tree-sitter-pascal`]. Treat that as a **dependency, not an optional extra**:
across the 70-script corpus, `[Code]` is roughly two fifths of the total volume,
and without the Pascal parser installed that entire region renders as plain
text. The plugin above installs it for you.

Measured on the corpus, 19 of 26 `[Code]` blocks parse with no errors under
`tree-sitter-pascal`. The remainder still highlight: tree-sitter recovers
locally, so a block with an error keeps most of its captures (one 387-byte
block with a parse error still produced 72 captures across 10 capture kinds).
The known gaps are Inno-specific extensions such as the `<event('...')>`
attribute, which upstream Pascal does not model.

## Usage from Rust

```toml
[dependencies]
tree-sitter = "0.26"
tree-sitter-iss = "0.1"
```

```rust
let code = r#"
[Setup]
AppName=My Program
DefaultDirName={autopf}\My Program

[Files]
Source: "MyProg.exe"; DestDir: "{app}"; Flags: ignoreversion
"#;

let mut parser = tree_sitter::Parser::new();
parser.set_language(&tree_sitter_iss::LANGUAGE.into())?;

let tree = parser.parse(code, None).unwrap();
assert!(!tree.root_node().has_error());
```

The crate also re-exports the bundled queries as
`tree_sitter_iss::HIGHLIGHTS_QUERY` and `tree_sitter_iss::INJECTIONS_QUERY`.

## Usage from the CLI

```bash
tree-sitter parse examples/realistic.iss
tree-sitter query queries/highlights.scm examples/realistic.iss
```

## Why this grammar is not trivial

Four specific problems have to be solved. Each has a dedicated regression test
in [`tests/parser_test.rs`](tests/parser_test.rs).

### 1. The same character means different things in different sections

```ini
[Setup]
AppName=My Program                   ; Directive=Value, value runs to end of line

[Files]
Source: "a.exe"; DestDir: "{app}"    ; Name: value; Name: value
```

`;` is a **comment** at the start of a line and a **parameter separator** in the
middle of one.

**Solution:** no hack required. Tree-sitter's lexer is *state driven* — it only
attempts tokens valid in the current LR state. Because `[Setup]` and `[Files]`
are distinct keyword tokens, the parser lands in different states and the right
entry grammar is selected automatically. The one requirement is that newlines
are **real tokens**, not `extras`.

The same mechanism makes `AppPublisherURL=https://example.com` work: `//` is a
comment token, but it is not *valid* inside a value, so it is never considered
there.

### 2. `[Code]` is an entire second language

The `[Code]` section is a full Pascal Script program. A context-free rule cannot
express "everything up to the next line beginning with `[`", and a naive rule
breaks on `MsgBox('[Setup] is not a section here')`.

**Solution:** an external scanner ([`src/scanner.c`](src/scanner.c)) consumes the
block, tracking whether a `[` is genuinely at the start of a line. The region is
then handed to [`tree-sitter-pascal`] through
[`queries/injections.scm`](queries/injections.scm).

### 3. Setup constants nest

```ini
Name: "{group}\{cm:UninstallProgram,{cm:MyAppName}}"
```

Braces nest arbitrarily, and **no regular expression can balance brackets** — a
`{[^{}]*}` token silently truncates at the first inner `}`.

**Solution:** the external scanner counts brace depth, and distinguishes `{app}`
(constant) from `{#Macro}` (ISPP expansion) from `{{` (escaped literal brace) by
peeking at the character after the opening brace.

### 4. ISPP macros span lines

```ini
#define ExecPowerShell(str Command) \
  Local[0] = PowerShellCommandParam + " " + AddQuotes(Command), \
  Local[0]
```

**Solution:** a `\` immediately before a newline is a line-continuation `extra`,
and the macro-argument token deliberately refuses to consume a backslash at end
of line so the argument resumes on the next line.

### Bonus: strings escape quotes by doubling them

```ini
Source: "a ""quoted"" name.dll"
```

Modelling the string as one regex token is wrong — longest-match would swallow
`"a"; DestDir: "` as a single string. Modelling it as a *rule* whose body is
`repeat(choice(content, '""', constant, ...))` resolves correctly, and gets
constants highlighted *inside* strings for free.

## Layout

```
grammar.js               the grammar source (see note below)
src/parser.c             generated parser, committed so consumers need no tooling
src/scanner.c            external scanner: [Code] blob, nested braces, EOF
queries/highlights.scm   syntax highlighting
queries/injections.scm   hands [Code] to tree-sitter-pascal
plugin/                  Neovim integration (auto-registers + installs)
bindings/rust/           the Rust crate
bindings/c/              C headers and pkg-config template
tests/parser_test.rs     Rust integration tests
test/corpus/iss.txt      tree-sitter corpus tests
examples/realistic.iss   a self-contained sample script
scripts/fetch-corpus.ps1 downloads the real-world validation corpus
```

### Why is there a `.js` file in a Rust crate?

Tree-sitter's grammar DSL *is* JavaScript — every tree-sitter grammar, including
all the official ones, is authored in a `grammar.js`. It is used only at author
time:

```
grammar.js  --(tree-sitter generate)-->  src/grammar.json  -->  src/parser.c
```

Because `src/parser.c` is committed, **building or using this crate needs no
Node.js and no tree-sitter CLI** — `bindings/rust/build.rs` simply compiles
`src/parser.c` and `src/scanner.c` with `cc`. You only need the CLI if you want
to change the grammar itself.

This repository ships Rust and C bindings. Node, Python, Go, Swift and Zig
bindings are disabled in `tree-sitter.json`; re-enable any of them there and run
`tree-sitter init` if you want them.

## Development

```bash
tree-sitter generate      # after editing grammar.js
tree-sitter test          # corpus tests
cargo test                # Rust tests

pwsh scripts/fetch-corpus.ps1   # optional: 70 real-world scripts
cargo test                      # now also validates against the corpus
```

## Known gaps

Deliberate scope limits, not blockers:

- `#if` / `#endif` are **flat** (sibling nodes), not nested. This is the same
  pragmatic choice most C grammars make, and it keeps the grammar robust when
  directives straddle section boundaries.
- A `\` at the end of an *unquoted* section value is treated as a literal
  backslash rather than a continuation. Trailing backslashes in paths are far
  more common than continuations in that position.
- `[Code]` is handed to `tree-sitter-pascal`; see the dependency note above.
  ISPP directives *inside* a `[Code]` section are part of the injected region
  rather than being parsed as preprocessor directives.

## License

MIT

[tree-sitter]: https://tree-sitter.github.io/tree-sitter/
[`jrsoftware/issrc`]: https://github.com/jrsoftware/issrc
[`tree-sitter-pascal`]: https://github.com/Isopod/tree-sitter-pascal
