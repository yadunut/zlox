const std = @import("std");
const log = std.log;
const Scanner = @import("./scanner.zig").Scanner;
const TokenType = @import("./tokens.zig").TokenType;

pub fn compile(source: []u8) !void {
    var line: usize = 0;
    var scanner = Scanner.init(source);
    while (true) {
        const token = scanner.scan();
        if (token.line != line) {
            log.debug("{d:0>4} {d} {s}", .{ token.line, @intFromEnum(token.type), token.source });
            line = token.line;
        } else {
            log.debug("  |  {d} {s}", .{ @intFromEnum(token.type), token.source });
        }

        if (token.type == TokenType.EOF) {
            break;
        }
    }
}
