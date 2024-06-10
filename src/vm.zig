const std = @import("std");
const Chunk = @import("./chunk.zig").Chunk;
const OpCode = @import("./chunk.zig").OpCode;
const Value = @import("./value.zig").Value;
const disassembleInstruction = @import("./debug.zig").disassembleInstruction;
const debugStack = @import("./debug.zig").debugStack;
const compile = @import("./compiler.zig").compile;

const STACK_SIZE = 256;

const InterpretError = error{
    CompileError,
    RuntimeError,
};

pub const VM = struct {
    chunk: ?*Chunk = null,
    stack: [STACK_SIZE]?Value = [_]?Value{null} ** STACK_SIZE,
    ip: usize = 0,
    sp: usize = 0, // points to the next available hole

    pub fn init() VM {
        return VM{};
    }
    pub fn deinit(_: *VM) void {}
    pub fn interpret(self: *VM, source: []u8) InterpretError!void {
        _ = self;
        try compile(source);
    }

    fn readConstant(self: *VM) Value {
        self.ip += 1;
        const idx = self.chunk.?.codes.items[self.ip];
        return self.chunk.?.values.items[idx];
    }

    fn push(self: *VM, value: Value) void {
        self.stack[self.sp] = value;
        self.sp += 1;
    }
    fn peek(self: *VM) Value {
        return self.stack[self.sp - 1].?;
    }
    fn pop(self: *VM) Value {
        self.sp -= 1;
        return self.stack[self.sp].?;
    }

    fn updateHead(self: *VM, comptime update: fn (old: Value) Value) void {
        self.stack[self.sp - 1] = update(self.stack[self.sp - 1].?);
    }

    fn run(self: *VM) InterpretError!void {
        if (self.chunk == null) return InterpretError.CompileError;
        while (self.ip < self.chunk.?.codes.items.len) : (self.ip += 1) {
            _ = debugStack(&self.stack, self.sp);
            _ = disassembleInstruction(self.chunk.?, self.ip);
            const instruction: OpCode = @enumFromInt(self.chunk.?.codes.items[self.ip]);
            switch (instruction) {
                .OP_RETURN => return,
                .OP_CONSTANT => {
                    const constant = self.readConstant();
                    self.push(constant);
                },
                .OP_NEGATE => {
                    self.updateHead(negate);
                },
                .OP_ADD => {
                    const op2 = switch (self.pop()) {
                        .Number => |num| num,
                    };
                    const op1 = switch (self.pop()) {
                        .Number => |num| num,
                    };
                    self.push(.{ .Number = op2 + op1 });
                },
                .OP_SUB => {
                    const op2 = switch (self.pop()) {
                        .Number => |num| num,
                    };
                    const op1 = switch (self.pop()) {
                        .Number => |num| num,
                    };
                    self.push(.{ .Number = op2 - op1 });
                },
                .OP_MUL => {
                    const op2 = switch (self.pop()) {
                        .Number => |num| num,
                    };
                    const op1 = switch (self.pop()) {
                        .Number => |num| num,
                    };
                    self.push(.{ .Number = op2 * op1 });
                },
                .OP_DIV => {
                    const op2 = switch (self.pop()) {
                        .Number => |num| num,
                    };
                    const op1 = switch (self.pop()) {
                        .Number => |num| num,
                    };
                    self.push(.{ .Number = op2 / op1 });
                },
                else => {},
            }
        }
    }
};

fn negate(old: Value) Value {
    switch (old) {
        .Number => |num| return .{ .Number = -num },
    }
}
