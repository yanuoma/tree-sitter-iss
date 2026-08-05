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

function sectionHeader(names) {
  const keyword =
    names.length === 1 ? ci(names[0]) : choice(...names.map(ci));
  return seq(
    '[',
    field('name', alias(token(prec(2, keyword)), 'section_name')),
    ']',
  );
}

export default grammar({
  name: 'iss',

  // Only horizontal whitespace is insignificant. Newlines are real tokens,
  // because a newline is what distinguishes `;` as a comment (line start) from
  // `;` as a parameter separator (mid line). A backslash immediately before a
  // newline is an ISPP line continuation and is likewise skipped.
  extras: ($) => [/[ \t]/, /\\\r?\n/],

  externals: ($) => [
    $.pascal_code,   // raw [Code] body, consumed until the next section header
    $.constant,      // `{app}`, `{cm:A,{cm:B}}` - needs brace counting
    $.preproc_inline, // `{#MyMacro}`
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

    _directive_section_header: ($) => sectionHeader(DIRECTIVE_SECTIONS),
    _parameter_section_header: ($) => sectionHeader(PARAMETER_SECTIONS),
    _code_section_header: ($) => sectionHeader(['Code']),
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

    // e.g. `AppName`, or a localized message key like `en.WelcomeLabel`
    directive_name: ($) => token(/[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)?/),

    value: ($) => repeat1($._value_piece),

    _value_piece: ($) =>
      choice($.constant, $.preproc_inline, $.escaped_brace, $.text, $._stray_brace),

    text: ($) => token(prec(-1, /[^{\r\n]+/)),

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
      choice($.string, $.constant, $.preproc_inline, $.escaped_brace, $.bare_value, $._stray_bare_brace),

    bare_value: ($) => token(prec(-1, /[^;"{\r\n]+/)),

    _stray_bare_brace: ($) => alias(token(prec(-2, '{')), $.bare_value),

    // ------------------------------------------------------------- literals

    // Strings use doubled double-quotes ("") to embed a quote. Modelling the
    // string as a *rule* (not one token) keeps longest-match from swallowing
    // several strings at once, and lets constants nest inside for highlighting.
    string: ($) =>
      seq(
        '"',
        repeat(choice($.string_content, $.escaped_quote, $.constant, $.preproc_inline, $.escaped_brace, $._stray_string_brace)),
        '"',
      ),

    string_content: ($) => token(prec(-1, /[^"{]+/)),

    _stray_string_brace: ($) => alias(token(prec(-2, '{')), $.string_content),

    escaped_quote: ($) => '""',

    // `{{` is Inno's escape for a literal `{`.
    escaped_brace: ($) => token(prec(3, '{{')),

    // ISPP inline macro expansion, e.g. `{#MyAppVersion}`
    preproc_inline: ($) => token(prec(2, seq('{#', /[^}\r\n]*/, '}'))),

    // Setup constants, e.g. `{app}`, `{sys}`, `{code:GetDir}`, `{param:X|d}`
    constant: ($) => token(prec(1, seq('{', /[^{}\r\n]*/, '}'))),

    // --------------------------------------------------------- preprocessor

    preproc_directive: ($) =>
      seq(
        field('directive', $.preproc_keyword),
        field('argument', optional($.preproc_argument)),
        $._line_end,
      ),

    preproc_keyword: ($) => token(seq('#', /[ \t]*/, /[a-zA-Z_]+/)),

    // An ISPP macro body may span lines via a trailing `\`. The argument token
    // therefore accepts any character except a backslash that sits immediately
    // before a line break, leaving that backslash to be consumed as the
    // line-continuation extra so the argument resumes on the next line.
    preproc_argument: ($) => prec.right(repeat1($._preproc_argument_part)),

    _preproc_argument_part: ($) => token(prec(-1, /([^\r\n\\]|\\[^\r\n])+/)),

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
