const std = @import("std");
const Token = @import("./tokens.zig").Token;
const TT = @import("./tokens.zig").TokenType;

const isDigit = std.ascii.isDigit;

pub const Scanner = struct {
    source: []const u8,
    start: usize = 0,
    current: usize = 0,
    line: usize = 1,

    pub fn init(source: []const u8) Scanner {
        return Scanner{ .source = source };
    }
    pub fn scan(sc: *Scanner) Token {
        sc.skipWhitespace();
        sc.start = sc.current;
        if (sc.isAtEnd()) return sc.makeToken(TT.EOF);

        const c = sc.advance();

        if (isAlpha(c)) return sc.identifier();
        if (isDigit(c)) return sc.number();

        return switch (c) {
            '(' => sc.makeToken(TT.PAREN_LEFT),
            ')' => sc.makeToken(TT.PAREN_RIGHT),
            '{' => sc.makeToken(TT.BRACE_LEFT),
            '}' => sc.makeToken(TT.BRACE_RIGHT),
            ';' => sc.makeToken(TT.SEMICOLON),
            ',' => sc.makeToken(TT.COMMA),
            '.' => sc.makeToken(TT.DOT),
            '-' => sc.makeToken(TT.MINUS),
            '+' => sc.makeToken(TT.PLUS),
            '/' => sc.makeToken(TT.SLASH),
            '*' => sc.makeToken(TT.STAR),
            '!' => if (sc.match('=')) sc.makeToken(TT.BANG_EQUAL) else sc.makeToken(TT.BANG),
            '=' => if (sc.match('=')) sc.makeToken(TT.EQUAL_EQUAL) else sc.makeToken(TT.EQUAL),
            '<' => if (sc.match('=')) sc.makeToken(TT.LESS_EQUAL) else sc.makeToken(TT.LESS),
            '>' => if (sc.match('=')) sc.makeToken(TT.GREATER_EQUAL) else sc.makeToken(TT.GREATER),
            '"' => sc.string(),

            else => sc.errorToken("Unhandled Token Type"),
        };
    }

    fn identifier(sc: *Scanner) Token {
        while (isAlpha(sc.peek()) or isDigit(sc.peek())) _ = sc.advance();
        return sc.makeToken(sc.identifierType());
    }

    fn identifierType(sc: *Scanner) TT {
        return switch (sc.source[sc.start]) {
            'a' => sc.checkKeyword(1, "nd", TT.AND),
            'c' => sc.checkKeyword(1, "lass", TT.CLASS),
            'e' => sc.checkKeyword(1, "lse", TT.ELSE),
            'f' => if (sc.current - sc.start > 1)
                switch (sc.source[sc.start + 1]) {
                    'a' => sc.checkKeyword(2, "lse", TT.FALSE),
                    'o' => sc.checkKeyword(2, "r", TT.FOR),
                    'u' => sc.checkKeyword(2, "n", TT.FUN),
                    else => TT.IDENTIFIER,
                }
            else
                TT.IDENTIFIER,
            'i' => sc.checkKeyword(1, "f", TT.IF),
            'n' => sc.checkKeyword(1, "il", TT.NIL),
            'o' => sc.checkKeyword(1, "r", TT.OR),
            'p' => sc.checkKeyword(1, "rint", TT.PRINT),
            'r' => sc.checkKeyword(1, "eturn", TT.RETURN),
            's' => sc.checkKeyword(1, "uper", TT.SUPER),
            't' => if (sc.current - sc.start > 1)
                switch (sc.source[sc.start + 1]) {
                    'h' => sc.checkKeyword(2, "is", TT.THIS),
                    'r' => sc.checkKeyword(2, "ue", TT.TRUE),
                    else => TT.IDENTIFIER,
                }
            else
                TT.IDENTIFIER,
            'v' => sc.checkKeyword(1, "ar", TT.VAR),
            'w' => sc.checkKeyword(1, "hile", TT.WHILE),
            else => TT.IDENTIFIER,
        };
    }

    fn checkKeyword(sc: *Scanner, start: usize, rest: []const u8, tType: TT) TT {
        if (sc.current - sc.start == start + rest.len and std.mem.eql(u8, sc.source[(sc.start + start)..(sc.start + start + rest.len)], rest)) return tType;
        return TT.IDENTIFIER;
    }

    fn number(sc: *Scanner) Token {
        while (isDigit(sc.peek())) _ = sc.advance();

        if (sc.peek() == '.' and isDigit(sc.peekNext())) _ = sc.advance();
        while (isDigit(sc.peek())) _ = sc.advance();
        return sc.makeToken(TT.NUMBER);
    }

    fn string(sc: *Scanner) Token {
        while (!sc.isAtEnd() and sc.peek() != '"') {
            if (sc.peek() == '\n') sc.line += 1;
            _ = sc.advance();
        }

        if (sc.isAtEnd()) return sc.errorToken("Unterminated String");
        _ = sc.advance();
        return sc.makeToken(TT.STRING);
    }

    fn match(scanner: *Scanner, char: u8) bool {
        if (scanner.isAtEnd()) return false;
        if (scanner.source[scanner.current] != char) return false;
        scanner.current += 1;
        return true;
    }

    fn peek(sc: *Scanner) u8 {
        if (sc.isAtEnd()) return 0;
        return sc.source[sc.current];
    }
    fn peekNext(sc: *Scanner) u8 {
        if (sc.isAtEnd()) return 0;
        return sc.source[sc.current + 1];
    }

    fn advance(scanner: *Scanner) u8 {
        scanner.current += 1;
        return scanner.source[scanner.current - 1];
    }

    fn isAtEnd(scanner: *Scanner) bool {
        return scanner.current == scanner.source.len;
    }

    fn makeToken(scanner: *Scanner, tType: TT) Token {
        return Token.init(tType, scanner.source[scanner.start..scanner.current], scanner.line);
    }

    fn errorToken(scanner: *Scanner, message: []const u8) Token {
        return Token.init(TT.ERROR, message, scanner.line);
    }
    fn skipWhitespace(sc: *Scanner) void {
        while (true) {
            const c = sc.peek();
            _ = switch (c) {
                ' ', '\r', '\t' => sc.advance(),
                '\n' => {
                    sc.line += 1;
                    _ = sc.advance();
                },
                '/' => {
                    if (sc.peekNext() == '/') {
                        while (sc.peek() != '\n' and !sc.isAtEnd()) _ = sc.advance();
                    } else {
                        return;
                    }
                },
                else => return,
            };
        }
    }
};

fn isAlpha(c: u8) bool {
    return std.ascii.isAlphabetic(c) or c == '_';
}

test "init scanner with immutable string" {
    const str = "hello";
    const scanner = Scanner.init(str);
    try std.testing.expect(scanner.line == 1);
}

test "init scanner with mutable string" {
    var buffer: [5]u8 = [_]u8{ 'h', 'e', 'l', 'l', 'o' };
    const scanner = Scanner.init(&buffer);
    try std.testing.expect(scanner.line == 1);
}

test "Scanning token" {
    const str = "+-*/ ! != = == < <= > >=";
    var scanner = Scanner.init(str);
    try std.testing.expectEqual(TT.PLUS, scanner.scan().type);
    try std.testing.expectEqual(TT.MINUS, scanner.scan().type);
    try std.testing.expectEqual(TT.STAR, scanner.scan().type);
    try std.testing.expectEqual(TT.SLASH, scanner.scan().type);
    try std.testing.expectEqual(TT.BANG, scanner.scan().type);
    try std.testing.expectEqual(TT.BANG_EQUAL, scanner.scan().type);
    try std.testing.expectEqual(TT.EQUAL, scanner.scan().type);
    try std.testing.expectEqual(TT.EQUAL_EQUAL, scanner.scan().type);
    try std.testing.expectEqual(TT.LESS, scanner.scan().type);
    try std.testing.expectEqual(TT.LESS_EQUAL, scanner.scan().type);
    try std.testing.expectEqual(TT.GREATER, scanner.scan().type);
    try std.testing.expectEqual(TT.GREATER_EQUAL, scanner.scan().type);
}

test "scan comment" {
    const str = "// this is a comment\n +";
    var scanner = Scanner.init(str);
    try std.testing.expectEqual(TT.PLUS, scanner.scan().type);
}
test "scan unterminated string" {
    const str = "\"This string is unterminated";
    var scanner = Scanner.init(str);
    try std.testing.expectEqual(TT.ERROR, scanner.scan().type);
}
test "scan string" {
    const str = "\"This is a terminated string\"";
    var scanner = Scanner.init(str);
    try std.testing.expectEqual(TT.STRING, scanner.scan().type);
}

test "Scan number" {
    const str = "123 456 7.89";
    var scanner = Scanner.init(str);
    var res = scanner.scan();
    try std.testing.expectEqual(TT.NUMBER, res.type);
    try std.testing.expectEqualStrings("123", res.source);
    res = scanner.scan();
    try std.testing.expectEqual(TT.NUMBER, res.type);
    try std.testing.expectEqualStrings("456", res.source);
    res = scanner.scan();
    try std.testing.expectEqual(TT.NUMBER, res.type);
    try std.testing.expectEqualStrings("7.89", res.source);
}

test "Scan identifiers" {
    const str = "else if for fun this true";
    var scanner = Scanner.init(str);
    var res = scanner.scan();
    try std.testing.expectEqual(TT.ELSE, res.type);
    res = scanner.scan();
    try std.testing.expectEqual(TT.IF, res.type);
    res = scanner.scan();
    try std.testing.expectEqual(TT.FOR, res.type);
    res = scanner.scan();
    try std.testing.expectEqual(TT.FUN, res.type);
    res = scanner.scan();
    try std.testing.expectEqual(TT.THIS, res.type);
    res = scanner.scan();
    try std.testing.expectEqual(TT.TRUE, res.type);
}
