const std = @import("std");

const Value = @import("./value.zig").Value;

pub const OpCode = enum(usize) {
    OP_RETURN,
    OP_CONSTANT,
    OP_NEGATE,
    OP_ADD,
    OP_SUB,
    OP_MUL,
    OP_DIV,
    OP_UNHANDLED,
};

pub const Chunk = struct {
    codes: std.ArrayList(usize),
    lines: std.ArrayList(usize),
    values: std.ArrayList(Value),
    pub fn init(allocator: std.mem.Allocator) Chunk {
        return Chunk{
            .codes = std.ArrayList(usize).init(allocator),
            .lines = std.ArrayList(usize).init(allocator),
            .values = std.ArrayList(Value).init(allocator),
        };
    }

    pub fn deinit(self: *Chunk) void {
        self.codes.deinit();
        self.lines.deinit();
        self.values.deinit();
    }

    pub fn writeCode(self: *Chunk, code: OpCode, line: usize) !void {
        try self.write(@intFromEnum(code), line);
    }

    fn write(self: *Chunk, data: usize, line: usize) !void {
        try self.codes.append(data);
        try self.lines.append(line);
    }

    fn addConstant(self: *Chunk, value: Value) !usize {
        try self.values.append(value);
        return self.values.items.len - 1;
    }

    pub fn writeConstant(self: *Chunk, value: Value, line: usize) !void {
        const idx = try self.addConstant(value);
        try self.writeCode(OpCode.OP_CONSTANT, line);
        try self.write(idx, line);
    }
};

test "detect leaks" {
    var chunk = Chunk.init(std.testing.allocator);
    try chunk.write(@intFromEnum(OpCode.OP_RETURN));
    chunk.deinit();
}
