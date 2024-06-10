const std = @import("std");
const Chunk = @import("./chunk.zig").Chunk;
const VM = @import("./vm.zig").VM;
const Value = @import("./value.zig").Value;
const OpCode = @import("./chunk.zig").OpCode;
const disassembleChunk = @import("./debug.zig").disassembleChunk;

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer std.debug.assert(gpa.deinit() == .ok);
    // const allocator = gpa.allocator();

    var vm = VM.init();
    defer vm.deinit();

    return repl(&vm);
}

fn repl(vm: *VM) !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    var line: [1024]u8 = undefined;

    while (true) {
        try stdout.print("> ", .{});
        _ = stdin.readUntilDelimiter(&line, '\n') catch |err| {
            if (err != error.EndOfStream) {
                return err;
            }
            try stdout.print("\n", .{});
            break;
        };
        try vm.interpret(&line);
    }
}
