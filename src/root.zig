const std = @import("std");

pub const drivers = struct {
    pub const uart = @import("drivers/uart.zig");
    pub const mmio = @import("drivers/mmio.zig");
    pub const vidcore = struct {
        pub const mb = @import("drivers/mb.zig");
        pub const fb = @import("drivers/fb.zig");
    };
};

pub const ui = struct {
    pub const color = @import("ui/color.zig");
    pub const text = @import("ui/text.zig");
    pub const window = @import("ui/window.zig");
};

pub const constants = struct {
    pub const uart0 = @import("constants.zig").UART0;
    pub const uart1 = @import("constants.zig").UART1;
    pub const gpio = @import("constants.zig").GPIO;
    pub const gpio_mode = @import("constants.zig").GPIOMode;
    pub const vidcore = @import("constants.zig").VidCore;
};

pub fn uartprint(comptime fmt: []const u8, args: anytype) void {
    var buf: [128]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, fmt, args) catch "Error while formatting";
    drivers.uart.write_text(msg);
}
