const std = @import("std");

pub const Value = union(enum) {
    Number: f64,

    pub fn format(value: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        return switch (value) {
            .Number => |n| writer.print("{d}", .{n}),
        };
    }
};
