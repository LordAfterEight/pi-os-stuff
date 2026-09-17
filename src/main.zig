const os = @import("root.zig");

export fn kernel_main() noreturn {
    os.drivers.uart.init();
    os.drivers.vidcore.fb.init();
    os.uartprint("Hello World from {s} :3\n", .{"\x1b[1;3;38;2;255;150;255mRaspi4 OS\x1b[0m"});
    os.drivers.vidcore.fb.drawString(10, 10, "Hello World", 0x0F);

    while (true) {
        os.drivers.uart.update();
    }
}
