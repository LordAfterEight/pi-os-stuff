const std = @import("std");

pub const drivers = struct {
    pub const uart0 = @import("drivers/uart0.zig");
};

/// Print text to UART0 (Serial debug output)
///
/// Used the same as regular printing
pub fn uartprint(comptime fmt: []const u8, args: anytype) void {
    var buf: [128]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, fmt, args) catch "Error while formatting";
    drivers.uart0.write(msg);
}
