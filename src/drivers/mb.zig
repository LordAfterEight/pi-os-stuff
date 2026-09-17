const mmio = @import("mmio.zig");
const vidcore = @import("../constants.zig").VidCore;

pub var mbox: [36]u32 align(16) = undefined;

pub fn call(ch: u8) bool {
    const addr = @intFromPtr(&mbox) & ~@as(usize, 0xF);
    const r: u32 = @intCast(addr | @as(usize, ch & 0xF));

    while ((mmio.read(vidcore.MBOX_STATUS) & vidcore.MBOX_FULL) != 0) {}
    mmio.write(vidcore.MBOX_WRITE, r);

    while (true) {
        while ((mmio.read(vidcore.MBOX_STATUS) & vidcore.MBOX_EMPTY) != 0) {}
        if (r == mmio.read(vidcore.MBOX_READ)) {
            return mbox[1] == vidcore.MBOX_RESPONSE;
        }
    }
}
