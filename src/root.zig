const std = @import("std");

pub const drivers = struct {
    pub const uart0 = @import("drivers/uart0.zig");
};

pub fn print(comptime fmt: []const u8, args: anytype) void {
    var buf: [128]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, fmt, args) catch "Error while formatting";
    drivers.uart0.write(msg);
}
