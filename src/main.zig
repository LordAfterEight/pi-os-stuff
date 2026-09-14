const build_config = @import("build_config");
const os = @import("root.zig");

export fn kernel_main() noreturn {
    os.drivers.uart0.init();
    os.drivers.uart0.write("Hello World!\r\n");
    while (true) {
        asm volatile ("wfe");
    }
}
