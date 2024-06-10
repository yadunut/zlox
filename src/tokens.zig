pub const TokenType = enum(usize) {
    PAREN_LEFT,
    PAREN_RIGHT,
    BRACE_LEFT,
    BRACE_RIGHT,
    COMMA,
    DOT,
    MINUS,
    PLUS,
    SEMICOLON,
    SLASH,
    STAR,
    // One or two character tokens.
    BANG,
    BANG_EQUAL,
    EQUAL,
    EQUAL_EQUAL,
    GREATER,
    GREATER_EQUAL,
    LESS,
    LESS_EQUAL,
    // Literals.
    IDENTIFIER,
    STRING,
    NUMBER,
    // Keywords.
    AND,
    CLASS,
    ELSE,
    FALSE,
    FOR,
    FUN,
    IF,
    NIL,
    OR,
    PRINT,
    RETURN,
    SUPER,
    THIS,
    TRUE,
    VAR,
    WHILE,
    ERROR,
    EOF,
};

pub const Token = struct {
    type: TokenType,
    source: []const u8,
    line: usize,

    pub fn init(tokenType: TokenType, source: []const u8, line: usize) Token {
        return Token{
            .type = tokenType,
            .source = source,
            .line = line,
        };
    }
};
