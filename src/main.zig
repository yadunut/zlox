const std = @import("std");

const Chunk = @import("./chunk.zig").Chunk;
const Value = @import("./chunk.zig").Value;
const OpCode = @import("./chunk.zig").OpCode;
const VM = @import("./vm.zig").VM;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("TEST FAIL");
    }

    var c = Chunk.init(allocator);
    defer c.deinit();

    var vm = VM.init(allocator);
    defer vm.deinit();

    var constant = try c.addConst(Value{ .Float = 1.2 });
    try c.writeChunk(OpCode{ .CONSTANT = constant }, 123);

    constant = try c.addConst(Value{ .Float = 3.4 });
    try c.writeChunk(OpCode{ .CONSTANT = constant }, 123);

    try c.writeChunk(OpCode.ADD, 123);

    constant = try c.addConst(Value{ .Float = 5.6 });
    try c.writeChunk(OpCode{ .CONSTANT = constant }, 123);

    try c.writeChunk(OpCode.DIVIDE, 123);
    try c.writeChunk(OpCode.NEGATE, 123);

    try c.writeChunk(OpCode.RETURN, 123);

    var res = vm.interpret(c);
    res = try vm.run();

    // try c.disassemble(allocator);
}

test "simple test" {
    var c = Chunk.init(std.testing.allocator);
    defer c.deinit();

    try std.testing.expectEqual(OpCode.RETURN, c.codes.items[0]);
}
