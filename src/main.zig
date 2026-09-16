const build_config = @import("build_config");
const os = @import("root.zig");

export fn kernel_main() noreturn {
    os.drivers.uart0.init();
    os.drivers.uart0.write("A\n");
    os.print("Hello World!\n{s}", .{"Raspi4 OS :3\n"});
    os.drivers.uart0.write("B\n");
    while (true) {
        asm volatile ("wfe");
    }
}
