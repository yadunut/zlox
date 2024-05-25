const std = @import("std");
const Chunk = @import("chunk.zig").Chunk;
const OpCode = @import("chunk.zig").OpCode;
const log = @import("std").log;
const Value = @import("value.zig").Value;

pub fn disassembleChunk(chunk: *Chunk, name: []const u8) void {
    log.debug("== {s} ==", .{name});
    var offset: usize = 0;
    while (offset < chunk.codes.items.len) {
        offset = disassembleInstruction(chunk, offset);
    }
}

pub fn disassembleInstruction(chunk: *Chunk, offset: usize) usize {
    const instruction: OpCode = @enumFromInt(chunk.codes.items[offset]);
    return switch (instruction) {
        OpCode.OP_RETURN => simpleInstruction(@tagName(instruction), chunk, offset),
        OpCode.OP_CONSTANT => constantInstruction(@tagName(instruction), chunk, offset),
        OpCode.OP_NEGATE => simpleInstruction(@tagName(instruction), chunk, offset),
        OpCode.OP_ADD => simpleInstruction(@tagName(instruction), chunk, offset),
        OpCode.OP_SUB => simpleInstruction(@tagName(instruction), chunk, offset),
        OpCode.OP_MUL => simpleInstruction(@tagName(instruction), chunk, offset),
        OpCode.OP_DIV => simpleInstruction(@tagName(instruction), chunk, offset),
        else => blk: {
            log.debug("Unknown OpCode: {s}", .{@tagName(instruction)});
            break :blk offset + 1;
        },
    };
}

fn simpleInstruction(name: []const u8, chunk: *Chunk, offset: usize) usize {
    if (offset > 0 and chunk.lines.items[offset] == chunk.lines.items[offset - 1]) {
        log.debug("{d:0>4}    | {s}", .{ offset, name });
    } else {
        log.debug("{d:0>4} {d: >4} {s}", .{ offset, chunk.lines.items[offset], name });
    }
    return offset + 1;
}
fn constantInstruction(name: []const u8, chunk: *Chunk, offset: usize) usize {
    const constantIdx = chunk.codes.items[offset + 1];
    if (offset > 0 and chunk.lines.items[offset] == chunk.lines.items[offset - 1]) {
        log.debug("{d:0>4}    | {s} {any}", .{ offset, name, chunk.values.items[constantIdx] });
    } else {
        log.debug("{d:0>4} {d: >4} {s} {any}", .{ offset, chunk.lines.items[offset], name, chunk.values.items[constantIdx] });
    }
    return offset + 2;
}

test "print chunk" {
    var c = Chunk.init(std.testing.allocator);
    defer c.deinit();
    try c.writeCode(OpCode.OP_RETURN);
    disassembleChunk(&c, "test");
}

pub fn debugStack(stack: []?Value, sp: usize) void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var str = std.ArrayList(u8).init(allocator);
    defer str.deinit();
    var writer = str.writer();
    _ = writer.write("          ") catch 0;
    for (0..sp) |idx| {
        if (stack[idx] == null) {
            continue;
        }
        writer.print("[ {any} ]", .{stack[idx].?}) catch unreachable;
    }
    log.debug("{s}", .{str.items});
}
