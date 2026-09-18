const std = @import("std");
const os = @import("root.zig");

export fn kernel_main() noreturn {
    os.drivers.uart.init();
    os.drivers.vidcore.fb.init();
    os.uartprint("Hello World from {s} :3\n", .{"\x1b[1;3;38;2;255;150;255mRaspi4 OS\x1b[0m"});

    var window_pixels: [720 * 480]u32 = undefined;
    const test_window = os.ui.window.Window.new(&window_pixels, 50, 100, 720, 480, "Test Window", .Light);

    while (true) {
        os.drivers.uart.update();
    }
    _ = test_window;
}
