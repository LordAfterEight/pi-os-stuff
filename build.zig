// NOTE: This file was written by Claude Sonnet 5 High on 14.09.2026.
// Following edits are documented at the very bottom of this file.

const std = @import("std");

// ---------------------------------------------------------------------------
// Board support table
//
// Every Raspberry Pi model is, to the compiler, just a different
// (CPU, load address, image name) triple. Keeping that fact in one table
// instead of scattered through build.zig is what makes "support another
// board" a one-line change instead of a refactor.
//
// To add a new board later:
//   1. Add a tag to `Board`.
//   2. Add its row to `boardConfig`.
//   3. If it's a different bitness (32-bit arm vs 64-bit aarch64), give it
//      its own linker/<name>.ld and src/boot_<arch>.S. Same-bitness boards
//      (e.g. pi3 -> pi4) reuse both as-is.
// ---------------------------------------------------------------------------

const Board = enum {
    pi3,
    pi4,
    // pi_zero, pi1, pi2 (armv6/armv7, 32-bit) go here once you need them —
    // they'll need arch = .arm and a 32-bit linker script + boot stub.
    // pi5 (BCM2712) also goes here — its boot chain (TF-A/u-boot handoff)
    // differs enough from pi3/4's firmware handoff that it deserves its
    // own linker script rather than reusing rpi-64.ld unmodified.
};

const BoardConfig = struct {
    arch: std.Target.Cpu.Arch,
    cpu_model: std.Target.Query.CpuModel,
    load_addr: u64,
    peripheral_base: u64, // GPIO/UART/etc. all sit at fixed offsets from this
    image_name: []const u8,
    linker_script: []const u8,
    qemu_machine: ?[]const u8, // null = no QEMU machine type for this board yet
    qemu_mem: []const u8, // QEMU's raspi* machines require an exact RAM match
};

fn boardConfig(board: Board) BoardConfig {
    return switch (board) {
        .pi3 => .{
            .arch = .aarch64,
            .cpu_model = .{ .explicit = &std.Target.aarch64.cpu.cortex_a53 },
            .load_addr = 0x80000,
            .peripheral_base = 0x3F000000,
            .image_name = "kernel8.img",
            .linker_script = "linker/rpi-64.ld",
            .qemu_machine = "raspi3b",
            .qemu_mem = "1G",
        },
        .pi4 => .{
            .arch = .aarch64,
            .cpu_model = .{ .explicit = &std.Target.aarch64.cpu.cortex_a72 },
            .load_addr = 0x80000,
            .peripheral_base = 0xFE000000, // BCM2711 low-peripheral mode
            .image_name = "kernel8-rpi4.img",
            .linker_script = "linker/rpi-64.ld",
            // Mainline since QEMU 9.0 (early 2024). Rougher than raspi3b:
            // it hardcodes RAM to exactly 2G and doesn't hand a DTB pointer
            // to x0 yet — the second doesn't matter to us since boot.S
            // never reads x0, but the RAM size below must match exactly.
            .qemu_machine = "raspi4b",
            .qemu_mem = "2G",
        },
    };
}

pub fn build(b: *std.Build) void {
    const board = b.option(Board, "board", "Target Raspberry Pi board") orelse .pi4;
    const optimize = b.standardOptimizeOption(.{});
    const cfg = boardConfig(board);

    // freestanding + abi none: no OS underneath us, no libc, no hosted
    // assumptions. We pin an explicit cpu_model rather than "native" or
    // "baseline" because the entire point of the board table is that we
    // *know* exactly which core we're compiling for.
    const target = b.resolveTargetQuery(.{
        .cpu_arch = cfg.arch,
        .cpu_model = cfg.cpu_model,
        .os_tag = .freestanding,
        .abi = .none,
    });

    // Make the board choice visible inside the kernel too, so src/*.zig
    // never has to re-hardcode a load address or duplicate this table.
    const opts = b.addOptions();
    opts.addOption(Board, "board", board);
    opts.addOption(u64, "load_addr", cfg.load_addr);
    opts.addOption(u64, "peripheral_base", cfg.peripheral_base);

    // As of Zig 0.16, addExecutable no longer takes root_source_file /
    // target / optimize directly — those live on a Module now, and
    // Compile (the exe/lib step) just wraps a root_module plus link-time
    // settings (linker script, entry point, objcopy). Build the module
    // first, attach its sources and imports to it, then hand it over.
    const kernel_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    kernel_mod.addAssemblyFile(b.path("src/boot.s"));
    kernel_mod.addOptions("build_config", opts);

    const kernel = b.addExecutable(.{
        .name = "kernel.elf",
        .root_module = kernel_mod,
    });

    kernel.setLinkerScript(b.path(cfg.linker_script));
    kernel.entry = .{ .symbol_name = "_start" };

    b.installArtifact(kernel);

    // The Pi's firmware wants a raw binary, not an ELF.
    const img = kernel.addObjCopy(.{ .format = .bin });
    const install_img = b.addInstallFile(img.getOutput(), cfg.image_name);
    b.getInstallStep().dependOn(&install_img.step);

    // `zig build run` — only wired up for boards QEMU actually emulates.
    if (cfg.qemu_machine) |machine| {
        const run = b.addSystemCommand(&.{
            "qemu-system-aarch64", "-M", machine, "-m", cfg.qemu_mem, "-serial", "stdio", "-kernel",
        });
        run.addFileArg(img.getOutput());
        b.step("run", "Run PiOS in QEMU").dependOn(&run.step);
    }
}
