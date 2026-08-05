; The [Code] section is a complete Pascal Script program. Rather than
; duplicating a Pascal grammar, hand the region to tree-sitter-pascal.
;
; This is the key composition trick: Inno Setup is really two languages in one
; file, and tree-sitter's injection mechanism is designed exactly for that.

((pascal_code) @injection.content
 (#set! injection.language "pascal"))
