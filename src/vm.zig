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
    ip: usize,
    stack: std.ArrayList(Value),
    pub fn init(allocator: std.mem.Allocator) VM {
        log.debug("initialized VM", .{});
        return VM{
            .allocator = allocator,
            .chunk = null,
            .stack = std.ArrayList(Value).init(allocator),
            .ip = 0,
        };
    }
    pub fn deinit(self: *VM) void {
        for (self.stack.items) |item| item.deinit();
        self.stack.deinit();
    }
    pub fn interpret(self: *VM, chunk: Chunk) InterpretResult {
        self.chunk = chunk;
        self.ip = 0;
        return InterpretResult.OK;
    }

    pub fn debugStack(self: VM) !void {
        var strings = std.ArrayList(u8).init(self.allocator);
        try strings.appendSlice("Stack [ ");
        for (self.stack.items) |item| {
            const res = try item.toString(self.allocator);
            defer self.allocator.free(res);
            try strings.appendSlice(res);
            try strings.append(' ');
        }
        try strings.appendSlice("]");
        std.log.scoped(.stack).info("{s}", .{strings.items});
        strings.deinit();
    }

    pub fn run(self: *VM) !InterpretResult {
        // might want to rewrite this to an iterator
        if (self.chunk == null) return InterpretResult.RUNTIME_ERROR;
        while (true) {
            const instr = self.chunk.?.codes.items[self.ip];
            try self.debugStack();
            try self.chunk.?.disassembleInstr(self.allocator, self.ip);
            switch (instr) {
                .CONSTANT => |i| {
                    const c = self.chunk.?.getConst(i);
                    self.stack.append(c) catch return InterpretResult.RUNTIME_ERROR;
                    // const res = c.toString(self.allocator) catch return InterpretResult.RUNTIME_ERROR;
                    // log.info("{s}", .{res});
                    // defer self.allocator.free(res);
                },
                .RETURN => {
                    const c = self.stack.pop();
                    const res = try c.toString(self.allocator);
                    log.info("{s}", .{res});
                    defer self.allocator.free(res);
                    return InterpretResult.OK;
                },
                .NEGATE => {
                    try self.stack.append(switch (self.stack.pop()) {
                        .Integer => |i| Value{ .Integer = -i },
                        .Float => |f| Value{ .Float = -f },
                    });
                },
                .ADD => {
                    const b = self.stack.pop();
                    const a = self.stack.pop();
                    try self.stack.append(switch (a) {
                        .Integer => |i| switch (b) {
                            .Integer => |j| Value{ .Integer = i + j },
                            .Float => |f| Value{ .Float = f + @as(f32, @floatFromInt(i)) },
                        },
                        .Float => |f| switch (b) {
                            .Integer => |j| Value{ .Float = f + @as(f32, @floatFromInt(j)) },
                            .Float => |g| Value{ .Float = f + g },
                        },
                    });
                },
                .SUBTRACT => {
                    const b = self.stack.pop();
                    const a = self.stack.pop();
                    try self.stack.append(switch (a) {
                        .Integer => |i| switch (b) {
                            .Integer => |j| Value{ .Integer = i - j },
                            .Float => |f| Value{ .Float = f - @as(f32, @floatFromInt(i)) },
                        },
                        .Float => |f| switch (b) {
                            .Integer => |j| Value{ .Float = f - @as(f32, @floatFromInt(j)) },
                            .Float => |g| Value{ .Float = f - g },
                        },
                    });
                },
                .MULTIPLY => {
                    const b = self.stack.pop();
                    const a = self.stack.pop();
                    try self.stack.append(switch (a) {
                        .Integer => |i| switch (b) {
                            .Integer => |j| Value{ .Integer = i * j },
                            .Float => |f| Value{ .Float = f * @as(f32, @floatFromInt(i)) },
                        },
                        .Float => |f| switch (b) {
                            .Integer => |j| Value{ .Float = f * @as(f32, @floatFromInt(j)) },
                            .Float => |g| Value{ .Float = f * g },
                        },
                    });
                },
                .DIVIDE => {
                    const b = self.stack.pop();
                    const a = self.stack.pop();
                    try self.stack.append(switch (a) {
                        .Integer => |i| switch (b) {
                            .Integer => |j| Value{ .Float = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(j)) },
                            .Float => |f| Value{ .Float = f / @as(f32, @floatFromInt(i)) },
                        },
                        .Float => |f| switch (b) {
                            .Integer => |j| Value{ .Float = f / @as(f32, @floatFromInt(j)) },
                            .Float => |g| Value{ .Float = f / g },
                        },
                    });
                },
                else => return InterpretResult.RUNTIME_ERROR,
            }
            self.ip += 1;
        }
    }
};
