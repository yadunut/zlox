const std = @import("std");

const log = std.log.scoped(.chunk);

pub const OpCode = union(enum) {
    CONSTANT: usize,
    RETURN,
    NIL,

    pub fn toString(self: OpCode, alloc: std.mem.Allocator) ![]u8 {
        return switch (self) {
            .CONSTANT => |i| std.fmt.allocPrint(alloc, "{s: <16}{d: >4}", .{ "CONSTANT", i }),
            .RETURN => std.fmt.allocPrint(alloc, "{s: <16}", .{"RETURN"}),
            else => "",
        };
    }
};

pub const Value = union(enum) {
    Float: f32,
    Integer: u32,

    pub fn toString(self: Value, alloc: std.mem.Allocator) ![]u8 {
        return switch (self) {
            .Float => |v| std.fmt.allocPrint(alloc, "{d:.2}", .{v}),
            .Integer => |v| std.fmt.allocPrint(alloc, "{d}", .{v}),
            // else => "",
        };
    }
};

pub const Chunk = struct {
    codes: std.ArrayList(OpCode),
    values: std.ArrayList(Value),
    lines: std.ArrayList(usize),

    pub fn init(allocator: std.mem.Allocator) Chunk {
        return Chunk{
            .codes = std.ArrayList(OpCode).init(allocator),
            .values = std.ArrayList(Value).init(allocator),
            .lines = std.ArrayList(usize).init(allocator),
        };
    }

    pub fn deinit(self: *Chunk) void {
        self.codes.deinit();
        self.values.deinit();
        self.lines.deinit();
    }

    pub fn writeChunk(self: *Chunk, code: OpCode, line: usize) !void {
        try self.codes.append(code);
        try self.lines.append(line);
    }

    pub fn addConst(self: *Chunk, val: Value) !usize {
        try self.values.append(val);
        return self.values.items.len - 1;
    }

    pub fn getConst(self: *Chunk, idx: usize) Value {
        return self.values.items[idx];
    }

    pub fn disassemble(self: Chunk, alloc: std.mem.Allocator) !void {
        for (self.lines.items, 0..) |line, index| {
            const idxStr = try std.fmt.allocPrint(alloc, "{X:0>4}  ", .{index});
            defer alloc.free(idxStr);
            const lineStr = if (index > 0 and self.lines.items[index] == self.lines.items[index - 1]) try std.fmt.allocPrint(alloc, "   |  ", .{}) else try std.fmt.allocPrint(alloc, "{d: >4}  ", .{line});
            defer alloc.free(lineStr);
            const instr = try self.codes.items[index].toString(alloc);
            defer alloc.free(instr);
            log.debug("{s}{s}{s}", .{ idxStr, lineStr, instr });
        }
    }
};
