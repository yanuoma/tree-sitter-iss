#include "tree_sitter/parser.h"

// External tokens for the Inno Setup grammar.
//
// PASCAL_CODE    - raw body of a [Code] section. A context-free rule cannot say
//                  "everything up to the next line beginning with '['", so it is
//                  scanned here and handed to tree-sitter-pascal via injection.
// CONSTANT       - `{app}`, `{cm:Msg,{cm:Other}}`. Setup constants *nest*, and a
//                  regular expression cannot balance brackets, so the scanner
//                  counts brace depth.
// PREPROC_INLINE - `{#MyMacro}`; same nesting rules, different node type.
// ESCAPED_BRACE  - `{{`, Inno's escape for a literal `{`.
// EOF_TOKEN      - zero-width token matching only at end of input, so a final
//                  line without a trailing newline still terminates cleanly.
enum TokenType {
  PASCAL_CODE,
  CONSTANT,
  PREPROC_INLINE,
  ENV_CONSTANT,
  ESCAPED_BRACE,
  EOF_TOKEN,
  ERROR_SENTINEL,
};

void *tree_sitter_iss_external_scanner_create(void) { return NULL; }
void tree_sitter_iss_external_scanner_destroy(void *payload) { (void)payload; }

unsigned tree_sitter_iss_external_scanner_serialize(void *payload, char *buffer) {
  (void)payload;
  (void)buffer;
  return 0;
}

void tree_sitter_iss_external_scanner_deserialize(void *payload, const char *buffer,
                                                   unsigned length) {
  (void)payload;
  (void)buffer;
  (void)length;
}

static bool scan_pascal_code(TSLexer *lexer) {
  bool has_content = false;
  bool at_line_start = true;

  for (;;) {
    int32_t c = lexer->lookahead;

    if (c == 0) {
      break; // end of file
    }

    // A '[' at the start of a line begins the next section, so the [Code] body
    // ends here without consuming it. A '[' anywhere else (for example inside a
    // Pascal string literal) is ordinary code.
    if (at_line_start && c == '[') {
      break;
    }

    if (c == '\n') {
      at_line_start = true;
    } else if (c != ' ' && c != '\t' && c != '\r') {
      // Indentation does not clear "line start", so an indented section header
      // still terminates the block.
      at_line_start = false;
    }

    lexer->advance(lexer, false);
    has_content = true;
    lexer->mark_end(lexer);
  }

  if (!has_content) {
    return false;
  }

  lexer->result_symbol = PASCAL_CODE;
  return true;
}

// Scan a balanced brace group: a Setup constant, an environment variable
// reference, or an ISPP inline expansion.
static bool scan_brace_group(TSLexer *lexer, const bool *valid_symbols) {
  if (lexer->lookahead != '{') {
    return false;
  }
  lexer->advance(lexer, false);

  // "{{" is an escaped literal brace, not the start of a constant.
  if (lexer->lookahead == '{') {
    if (!valid_symbols[ESCAPED_BRACE]) {
      return false;
    }
    lexer->advance(lexer, false);
    lexer->mark_end(lexer);
    lexer->result_symbol = ESCAPED_BRACE;
    return true;
  }

  // Distinguish the three kinds here, by the character after the brace, rather
  // than with a `#match?` predicate in the highlight query. That matters:
  // Neovim compiles query regexes as very-magic Vim patterns, where a bare `%`
  // is an operator prefix, so a pattern like `^\{%` fails to compile and takes
  // the entire highlighter down with it.
  enum TokenType kind = CONSTANT;
  if (lexer->lookahead == '#') {
    kind = PREPROC_INLINE;
  } else if (lexer->lookahead == '%') {
    kind = ENV_CONSTANT;
  }

  if (!valid_symbols[kind]) {
    return false;
  }

  unsigned depth = 1;
  while (depth > 0) {
    int32_t c = lexer->lookahead;
    // Constants never span lines. An unterminated group is not a constant, so
    // bail out and let the ordinary text tokens handle the stray brace.
    if (c == 0 || c == '\n' || c == '\r') {
      return false;
    }
    if (c == '{') {
      depth++;
    } else if (c == '}') {
      depth--;
    }
    lexer->advance(lexer, false);
  }

  lexer->mark_end(lexer);
  lexer->result_symbol = kind;
  return true;
}

bool tree_sitter_iss_external_scanner_scan(void *payload, TSLexer *lexer,
                                            const bool *valid_symbols) {
  (void)payload;

  // Never run during error recovery: the sentinel being valid means the parser
  // is trying every token, and greedily eating input would mask real errors.
  if (valid_symbols[ERROR_SENTINEL]) {
    return false;
  }

  if (valid_symbols[PASCAL_CODE] && scan_pascal_code(lexer)) {
    return true;
  }

  if (valid_symbols[CONSTANT] || valid_symbols[PREPROC_INLINE] ||
      valid_symbols[ENV_CONSTANT] || valid_symbols[ESCAPED_BRACE]) {
    // Skip leading blanks so the token starts at the brace. Without this the
    // node would begin before the whitespace, and any exact-text predicate in
    // a highlight query would silently fail to match.
    while (lexer->lookahead == ' ' || lexer->lookahead == '\t') {
      lexer->advance(lexer, true);
    }
    if (scan_brace_group(lexer, valid_symbols)) {
      return true;
    }
  }

  if (valid_symbols[EOF_TOKEN] && lexer->lookahead == 0) {
    lexer->result_symbol = EOF_TOKEN;
    return true;
  }

  return false;
}
