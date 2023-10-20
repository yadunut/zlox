const std = @import("std");

const Chunk = @import("./chunk.zig").Chunk;
const Value = @import("./chunk.zig").Value;
const OpCode = @import("./chunk.zig").OpCode;

const InterpretResult = enum {
    OK,
    COMPILE_ERROR,
    RUNTIME_ERROR,
};

const log = std.log.scoped(.vm);

pub const VM = struct {
    allocator: std.mem.Allocator,
    chunk: ?Chunk,
    ip: ?[*]OpCode,
    pub fn init(allocator: std.mem.Allocator) VM {
        log.debug("initialized VM", .{});
        return VM{
            .allocator = allocator,
            .chunk = null,
            .ip = null,
        };
    }
    pub fn deinit(self: *VM) void {
        _ = self;
    }
    pub fn interpret(self: *VM, chunk: Chunk) InterpretResult {
        self.chunk = chunk;
        var ptr: [*]OpCode = chunk.codes.items.ptr;
        self.ip = ptr;
        return InterpretResult.OK;
    }

    pub fn run(self: *VM) InterpretResult {
        // might want to rewrite this to an iterator
        if (self.chunk == null) return InterpretResult.RUNTIME_ERROR;
        if (self.ip == null) return InterpretResult.RUNTIME_ERROR;
        while (true) {
            const instr = self.ip.?[0];
            self.ip.? += 1;
            switch (instr) {
                .CONSTANT => |i| {
                    const c = self.chunk.?.getConst(i);
                    const res = c.toString(self.allocator) catch return InterpretResult.RUNTIME_ERROR;
                    log.info("{s}", .{res});
                    defer self.allocator.free(res);
                },
                .RETURN => {
                    return InterpretResult.OK;
                },
                else => return InterpretResult.RUNTIME_ERROR,
            }
        }
    }
};
