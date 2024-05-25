const std = @import("std");
const Chunk = @import("./chunk.zig").Chunk;
const VM = @import("./vm.zig").VM;
const Value = @import("./value.zig").Value;
const OpCode = @import("./chunk.zig").OpCode;
const disassembleChunk = @import("./debug.zig").disassembleChunk;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var vm = VM.init();
    defer vm.deinit();

    var chunk = Chunk.init(allocator);
    defer chunk.deinit();
    try chunk.writeConstant(Value{ .Number = 1.2 }, 123);
    try chunk.writeConstant(Value{ .Number = -2.5 }, 123);

    try chunk.writeCode(OpCode.OP_NEGATE, 123);
    try chunk.writeCode(OpCode.OP_ADD, 123);

    try chunk.writeCode(OpCode.OP_RETURN, 124);

    try vm.interpret(&chunk);
}
