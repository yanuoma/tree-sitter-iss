; The [Code] section is a complete Pascal Script program. Rather than
; duplicating a Pascal grammar, hand the region to tree-sitter-pascal.
;
; This is the key composition trick: Inno Setup is really two languages in one
; file, and tree-sitter's injection mechanism is designed exactly for that.
;
; Treat tree-sitter-pascal as a dependency rather than an optional extra. A
; [Code] section is a whole program, and it accounts for roughly two fifths of
; a typical script by volume, so without the Pascal parser installed that whole
; region renders as plain text.

((pascal_code) @injection.content
  (#set! injection.language "pascal"))