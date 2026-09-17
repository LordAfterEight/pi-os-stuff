const os = @import("root.zig");

const mbox: [36]u32 = undefined;

pub fn call(ch: u8) !void {
    const r = (&mbox & ~0xF) | (ch & 0xF);
    while ((os.drivers.mmio.read(os.constants.vidcore.MBOX_STATUS) & os.constants.vidcore.MBOX_FULL) != 0) {}
    os.drivers.mmio.write(os.constants.vidcore.MBOX_WRITE, r);

    while (1) {
        while (os.drivers.mmio.read(os.constants.vidcore.MBOX_STATUS) & os.constants.vidcore.MBOX_EMPTY) {}
        if (r == os.drivers.mmio.read(os.constants.vidcore.MBOX_READ)) return mbox[1] == os.constants.vidcore.MBOX_RESPONSE;
    }
}
