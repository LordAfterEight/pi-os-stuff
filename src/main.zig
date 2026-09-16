const build_config = @import("build_config");
const std = @import("std");
const os = @import("root.zig");

export fn kernel_main() noreturn {
    os.drivers.uart0.init();
    os.uartprint("Hello World from {s}", .{"Raspi4 OS :3\n"});

    while (true) {
        asm volatile ("wfe");
    }
}
