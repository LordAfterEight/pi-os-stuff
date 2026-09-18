const os = @import("root.zig");

export fn kernel_main() noreturn {
    os.drivers.uart.init();
    os.drivers.vidcore.fb.init();
    os.uartprint("Hello World from {s} :3\n", .{"\x1b[1;3;38;2;255;150;255mRaspi4 OS\x1b[0m"});

    var test_window = os.ui.window.Window.new(20, 20, 500, 500, "TestWindow", .Light);

    while (true) {
        test_window.update();
        os.drivers.uart.update();
    }
}
