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
    chunk: ?Chunk,
    ip: ?*OpCode,
    pub fn init(allocator: std.mem.Allocator) VM {
        _ = allocator;
        return VM{
            .chunk = null,
            .ip = null,
        };
    }
    pub fn deinit(self: *VM) void {
        _ = self;
        // for (self.chunks.items) |item| item.deinit();
        // self.chunks.deinit();
    }
    pub fn interpret(self: *VM, chunk: *Chunk) InterpretResult {
        self.chunk = chunk;
        self.ip = &chunk.codes.items[0];
        return InterpretResult.OK;
    }

    pub fn run(self: *VM) InterpretResult {
        if (self.chunk == null) return InterpretResult.RUNTIME_ERROR;
        if (self.ip == null) return InterpretResult.RUNTIME_ERROR;
        while (true) {
            const instr = *self.ip;
            (*self.ip) += 1;
            switch (instr) {
                .CONSTANT => |i| {
                    const c = self.chunk.?.getConst(i);
                    c.disassemble();
                },
                .RETURN => {
                    return InterpretResult.OK;
                },
            }
        }
    }
};
