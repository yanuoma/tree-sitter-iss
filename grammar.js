/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

/**
 * @file Inno Setup (.iss) grammar for tree-sitter
 * @author yanuoma
 * @license MIT
 *
 * Tree-sitter grammar for Inno Setup (.iss) scripts.
 *
 * Design notes
 * ------------
 * Inno Setup is a *context-sensitive*, line-oriented format: the meaning of a
 * line depends on which [Section] encloses it.
 *
 *   [Setup]   -> Directive=Value          (free-form value to end of line)
 *   [Files]   -> Name: "value"; Name: v   (semicolon-separated parameters)
 *   [Code]    -> a whole Pascal program   (handled as an injection region)
 *
 * Tree-sitter handles this without hacks because its lexer is *state driven*:
 * it only attempts to match tokens that are valid in the current LR state.
 * Since `[Setup]` and `[Files]` are distinct keyword tokens, the parser lands
 * in different states and the correct entry grammar is selected automatically.
 *
 * Newlines are significant tokens (NOT in `extras`) because they are what
 * disambiguates `;` as a comment-start (line start) from `;` as a parameter
 * separator (mid line).
 */

// Build a case-insensitive regex for a literal word (Inno section names and
// directives are case-insensitive; tree-sitter tokens are not).
function ci(word) {
  return new RegExp(
    [...word]
      .map((c) => (/[a-zA-Z]/.test(c) ? `[${c.toLowerCase()}${c.toUpperCase()}]` : c))
      .join(''),
  );
}

// Sections whose entries are `Directive=Value`.
const DIRECTIVE_SECTIONS = ['Setup', 'Messages', 'CustomMessages', 'LangOptions'];

// Sections whose entries are `Name: value; Name: value`.
const PARAMETER_SECTIONS = [
  'Types', 'Components', 'Tasks', 'Dirs', 'Files', 'Icons', 'INI',
  'InstallDelete', 'Languages', 'Registry', 'Run', 'UninstallDelete',
  'UninstallRun', 'UninstallRegistry', 'UninstallIcons',
];

function sectionHeader($, names) {
  const keyword =
    names.length === 1 ? ci(names[0]) : choice(...names.map(ci));
  return seq(
    '[',
    // Aliasing to the `$.section_name` *symbol* (not the string
    // 'section_name') is what makes this a named node. With a string it is
    // anonymous, and `(section_name)` in a query silently matches nothing.
    field('name', alias(token(prec(2, keyword)), $.section_name)),
    ']',
  );
}

export default grammar({
  name: 'iss',

  // Only horizontal whitespace is insignificant. Newlines are real tokens,
  // because a newline is what distinguishes `;` as a comment (line start) from
  // `;` as a parameter separator (mid line).
  //
  // A backslash continues the line only when it is *preceded by whitespace*.
  // That matches ISPP.Preprocessor.pas, which requires `LineRead[L - 1] <= #32`
  // before treating the trailing character as its span symbol. Without that
  // condition an ordinary Windows path ending in a backslash, such as
  // `OutputDir=D:\`, would silently swallow the following line.
  extras: ($) => [/[ \t]/, /[ \t]\\\r?\n/],

  externals: ($) => [
    $.pascal_code,   // raw [Code] body, consumed until the next section header
    $.constant,      // `{app}`, `{cm:A,{cm:B}}` - needs brace counting
    $.preproc_inline, // `{#MyMacro}`
    $.env_constant,  // `{%ENV}` and `{%ENV|default}`
    $.escaped_brace, // `{{`
    $._eof,          // zero-width token matching only at end of input
    $._error_sentinel,
  ],

  conflicts: ($) => [],

  rules: {
    source_file: ($) => repeat($._top_level),

    _top_level: ($) =>
      choice(
        $.comment,
        $.preproc_directive,
        $.section,
        $._newline,
      ),

    // ---------------------------------------------------------------- sections

    section: ($) =>
      choice(
        $.code_section,
        $.directive_section,
        $.parameter_section,
        $.unknown_section,
      ),

    directive_section: ($) =>
      prec.right(
        seq(
          alias($._directive_section_header, $.section_header),
          $._line_end,
          repeat($._directive_line),
        ),
      ),

    parameter_section: ($) =>
      prec.right(
        seq(
          alias($._parameter_section_header, $.section_header),
          $._line_end,
          repeat($._parameter_line),
        ),
      ),

    code_section: ($) =>
      seq(
        alias($._code_section_header, $.section_header),
        $._line_end,
        optional($.pascal_code),
      ),

    _directive_section_header: ($) => sectionHeader($, DIRECTIVE_SECTIONS),
    _parameter_section_header: ($) => sectionHeader($, PARAMETER_SECTIONS),
    _code_section_header: ($) => sectionHeader($, ['Code']),
    _unknown_section_header: ($) =>
      seq('[', field('name', $.section_name), ']'),

    // Any section we do not recognise is parsed with parameter syntax, which is
    // the most common shape, so unknown/future sections degrade gracefully.
    unknown_section: ($) =>
      prec.right(
        seq(
          alias($._unknown_section_header, $.section_header),
          $._line_end,
          repeat($._parameter_line),
        ),
      ),

    section_name: ($) => $.identifier,

    // ------------------------------------------------- [Setup]-style entries

    _directive_line: ($) =>
      choice($.comment, $.preproc_directive, $.directive_entry, $._newline),

    directive_entry: ($) =>
      seq(
        field('name', $.directive_name),
        '=',
        field('value', optional($.value)),
        $._line_end,
      ),

    // e.g. `AppName`, or a localized message key like `english.WelcomeLabel`.
    // The language prefix is a separate node so it can be highlighted apart
    // from the key it qualifies, which is what [CustomMessages] and
    // [Messages] entries look like. The plain case deliberately produces no
    // child node, to keep the common tree shape flat.
    directive_name: ($) =>
      choice(
        seq(
          field('language', $.language_name),
          '.',
          field('key', $.directive_key),
        ),
        $._name,
      ),

    language_name: ($) => $._name,

    directive_key: ($) => $._name,

    _name: ($) => token(/[A-Za-z_][A-Za-z0-9_]*/),

    value: ($) => repeat1($._value_piece),

    _value_piece: ($) =>
      choice(
        $.constant,
        $.preproc_inline,
        $.env_constant,
        $.escaped_brace,
        $.message_placeholder,
        $.number,
        $.word,
        $.text,
        $._stray_brace,
      ),

    // Values are split into words and numbers rather than kept as one opaque
    // run, so that highlight queries can pick out the enumerated values the
    // language defines: `yes`/`no`, `lzma2/max`, `admin`, architecture names
    // and so on. `text` is only the leftover punctuation between them.
    // Space and tab are excluded so that whitespace is handled solely by
    // `extras`; otherwise it gets absorbed into the following token and every
    // word ends up prefixed with a space, breaking `#eq?`/`#any-of?`.
    text: ($) => token(prec(-1, /[^{\r\n\t A-Za-z0-9_]+/)),

    // A `{` that does not open a balanced group is literal text.
    _stray_brace: ($) => alias(token(prec(-2, '{')), $.text),

    // ------------------------------------------------ [Files]-style entries

    _parameter_line: ($) =>
      choice($.comment, $.preproc_directive, $.parameter_entry, $._newline),

    parameter_entry: ($) =>
      seq(
        $.parameter,
        repeat(seq(';', $.parameter)),
        optional(';'),
        $._line_end,
      ),

    parameter: ($) =>
      seq(
        field('name', $.parameter_name),
        ':',
        field('value', optional($.parameter_value)),
      ),

    parameter_name: ($) => token(/[A-Za-z_][A-Za-z0-9_]*/),

    parameter_value: ($) => repeat1($._parameter_value_piece),

    _parameter_value_piece: ($) =>
      choice(
        $.string,
        $.constant,
        $.preproc_inline,
        $.env_constant,
        $.escaped_brace,
        $.message_placeholder,
        $.number,
        $.word,
        $.bare_value,
        $._stray_bare_brace,
      ),

    // As with `text`, this is only the punctuation between words, so that each
    // flag in `Flags: ignoreversion recursesubdirs` is its own node and can be
    // highlighted individually. Whitespace is excluded for the same reason.
    bare_value: ($) => token(prec(-1, /[^;"{\r\n\t A-Za-z0-9_]+/)),

    _stray_bare_brace: ($) => alias(token(prec(-2, '{')), $.bare_value),

    // Shared across both entry styles. An alphanumeric run counts as a word as
    // long as it contains at least one letter or underscore, so that flags
    // which begin with a digit -- `32bit`, `64bit` -- stay a single token
    // instead of splitting into a number followed by a word.
    word: ($) => token(/[0-9]*[A-Za-z_][A-Za-z0-9_]*/),

    // Covers plain integers and dotted version numbers such as `1.5.3`.
    number: ($) => token(/\d+(\.\d+)*/),

    // `%1`..`%9` and `%n` placeholders in [Messages]/[CustomMessages].
    // Modelled as a token rather than a `#match?` predicate: predicate regexes
    // are compiled by whatever engine the host embeds, and those disagree on
    // metacharacters, so a pattern like `%[0-9n]` can mean something entirely
    // different from one host to the next. A token means the same everywhere.
    message_placeholder: ($) => token(prec(2, /%[0-9n]/)),

    // ------------------------------------------------------------- literals

    // Strings use doubled double-quotes ("") to embed a quote. Modelling the
    // string as a *rule* (not one token) keeps longest-match from swallowing
    // several strings at once, and lets constants nest inside for highlighting.
    string: ($) =>
      seq(
        '"',
        repeat(choice($.string_content, $.escaped_quote, $.constant, $.env_constant, $.preproc_inline, $.escaped_brace, $._stray_string_brace)),
        '"',
      ),

    // token.immediate keeps a space in front of a """ escape from being
    // absorbed into it, which would shift the escape's highlight one column.
    string_content: ($) => token.immediate(prec(-1, /[^"{]+/)),

    _stray_string_brace: ($) => alias(token(prec(-2, '{')), $.string_content),

    escaped_quote: ($) => token.immediate('""'),

    // `{{` is Inno's escape for a literal `{`.
    escaped_brace: ($) => token(prec(3, '{{')),

    // ISPP inline macro expansion, e.g. `{#MyAppVersion}`
    preproc_inline: ($) => token(prec(2, seq('{#', /[^}\r\n]*/, '}'))),

    // Setup constants, e.g. `{app}`, `{sys}`, `{code:GetDir}`, `{param:X|d}`
    constant: ($) => token(prec(1, seq('{', /[^{}\r\n]*/, '}'))),

    // --------------------------------------------------------- preprocessor

    preproc_directive: ($) =>
      choice($._preproc_expr_directive, $._preproc_message_directive),

    // The ordinary case: the argument is an ISPP expression.
    _preproc_expr_directive: ($) =>
      seq(
        field('directive', $.preproc_keyword),
        field('argument', optional($.preproc_argument)),
        $._line_end,
      ),

    // `#error` takes free text, not an expression. Tokenising it like an
    // expression shreds an English sentence into identifiers and operators,
    // which reads considerably worse than leaving it as one run.
    _preproc_message_directive: ($) =>
      seq(
        field('directive', alias($._message_keyword, $.preproc_keyword)),
        field('argument', optional(alias($._rest_of_line, $.preproc_text))),
        $._line_end,
      ),

    _message_keyword: ($) => token(prec(3, seq('#', /[ \t]*/, ci('error')))),

    // Cannot begin with whitespace, so the message node starts at the first
    // real character rather than at the space after the directive.
    _rest_of_line: ($) => token(prec(-1, /[^\r\n \t][^\r\n]*/)),

    preproc_keyword: ($) => token(seq('#', /[ \t]*/, /[a-zA-Z_]+/)),

    // ISPP directive arguments are a small expression language. Tokenising them
    // means `#define MyAppVersion "1.5"` and `#if Len(X) >= 2` get highlighted
    // instead of being one opaque run of text.
    //
    // The line continuation is matched inside the pieces that can precede it,
    // because a piece would otherwise consume the whitespace that the
    // continuation rule in `extras` needs to see before the backslash.
    preproc_argument: ($) => prec.right(repeat1($._preproc_piece)),

    _preproc_piece: ($) =>
      choice(
        $.preproc_string,
        $.number,
        $.preproc_identifier,
        $.preproc_operator,
        $.preproc_inline,
        $._preproc_punctuation,
        $._preproc_other,
      ),

    // ISPP accepts both quoting styles, and both use a doubled quote to embed
    // one. Without the single-quoted form, `#define X 'KeyNote file'` tokenises
    // as two identifiers and the prose gets highlighted as code.
    preproc_string: ($) =>
      choice(
        seq(
          '"',
          repeat(choice(alias($._preproc_string_text, $.string_content), $.escaped_quote)),
          '"',
        ),
        seq(
          "'",
          repeat(
            choice(
              alias($._preproc_string_text_sq, $.string_content),
              alias(token.immediate("''"), $.escaped_quote),
            ),
          ),
          "'",
        ),
      ),

    _preproc_string_text: ($) => token.immediate(prec(1, /[^"\r\n]+/)),

    _preproc_string_text_sq: ($) => token.immediate(prec(1, /[^'\r\n]+/)),

    preproc_identifier: ($) => token(prec(1, /[A-Za-z_][A-Za-z0-9_]*/)),

    preproc_operator: ($) =>
      token(
        prec(
          1,
          choice(
            '==', '!=', '<=', '>=', '&&', '||', '<<', '>>',
            '+', '-', '*', '/', '%', '<', '>', '=', '!', '?', ':', '.', '&', '|', '^',
          ),
        ),
      ),

    _preproc_punctuation: ($) =>
      alias(token(prec(1, choice('(', ')', '[', ']', ','))), $.punctuation),

    // Anything else on the line. Whitespace is excluded so it is handled only
    // by `extras`; including it makes the neighbouring token absorb a leading
    // space, which breaks exact-text predicates.
    _preproc_other: ($) =>
      alias(
        token(prec(-1, /([^\r\n\t \\"(),\[\]A-Za-z0-9_+\-*\/%<>=!?:.&|^]|\\[^\r\n])+/)),
        $.preproc_text,
      ),

    // -------------------------------------------------------------- trivia

    // A comment is a `;` or (under ISPP) a `//` that begins a line. Because the
    // token is only valid where an entry may start, a `//` inside a value such
    // as `AppPublisherURL=https://example.com` is correctly *not* a comment.
    comment: ($) =>
      seq(
        token(
          prec(1, choice(seq(';', /[^\r\n]*/), seq('//', /[^\r\n]*/))),
        ),
        $._line_end,
      ),

    identifier: ($) => /[A-Za-z_][A-Za-z0-9_]*/,

    _newline: ($) => token(/\r?\n/),

    _line_end: ($) => choice($._newline, $._eof),
  },
});
