// NOTE: This file was written by Claude Sonnet 5 High on the 13th of September 2026.
// Following edits are documented at the very bottom of this file.

const build_config = @import("build_config");

export fn kernel_main() noreturn {
    // build_config.board / build_config.load_addr are available here.
    // This is where board-specific peripheral base addresses (UART, GPIO,
    // mailbox, ...) will branch on build_config.board once real drivers
    // exist — comptime `switch (build_config.board) { ... }` is enough,
    // no runtime detection needed since the board is chosen at build time.
    while (true) {
        asm volatile ("wfe");
    }
}
