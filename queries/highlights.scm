; Highlighting for Inno Setup (.iss)
(comment) @comment

; ---------------------------------------------------------------- sections
(section_header
  name: (section_name) @type)

(section_header
  [
    "["
    "]"
  ] @punctuation.bracket)

; --------------------------------------------------------------- entries
(directive_entry
  name: (directive_name) @property)

(parameter
  name: (parameter_name) @property)

; --------------------------------------------------------------- literals
(string) @string

(string_content) @string

(escaped_quote) @string.escape

(escaped_brace) @string.escape

; `{app}`, `{sys}`, `{cm:Msg}` - Setup constants
(constant) @constant.builtin

; `{#MyMacro}` - ISPP compile-time expansion
(preproc_inline) @constant.macro

; ----------------------------------------------------------- preprocessor
(preproc_directive
  directive: (preproc_keyword) @keyword.directive)

(preproc_directive
  argument: (preproc_argument) @none)

; --------------------------------------------------------------- operators
[
  "="
  ":"
] @operator

";" @punctuation.delimiter
