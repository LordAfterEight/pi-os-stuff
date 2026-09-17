// NOTE: This file was directly translated from C to Zig using GPT-5.6 Luna on 17.09.2026
// Original code is from https://github.com/sypstraw/rpi4-osdev/blob/master/part5-framebuffer/fb.c

const mb = @import("mb.zig");
const vidcore = @import("../constants.zig").VidCore;
const text = @import("../ui/text.zig");

pub const FONT_WIDTH = 8;
pub const FONT_HEIGHT = 8;
pub const FONT_BPG = 8;
pub const FONT_BPL = 1;
pub const FONT_NUMGLYPHS = 224;

pub const vgapal = [_]u32{
    0x000000,
    0x0000AA,
    0x00AA00,
    0x00AAAA,
    0xAA0000,
    0xAA00AA,
    0xAA5500,
    0xAAAAAA,
    0x555555,
    0x5555FF,
    0x55FF55,
    0x55FFFF,
    0xFF5555,
    0xFF55FF,
    0xFFFF55,
    0xFFFFFF,
};

var width: u32 = 0;
var height: u32 = 0;
var pitch: u32 = 0;
var isrgb: u32 = 0;
var fb: [*]volatile u8 = undefined;

pub fn init() void {
    mb.mbox[0] = 35 * 4;
    mb.mbox[1] = vidcore.MBOX_REQUEST;

    mb.mbox[2] = vidcore.MBOX_TAG_SETPHYWH;
    mb.mbox[3] = 8;
    mb.mbox[4] = 0;
    mb.mbox[5] = 1920;
    mb.mbox[6] = 1080;

    mb.mbox[7] = vidcore.MBOX_TAG_SETVIRTWH;
    mb.mbox[8] = 8;
    mb.mbox[9] = 8;
    mb.mbox[10] = 1920;
    mb.mbox[11] = 1080;

    mb.mbox[12] = vidcore.MBOX_TAG_SETVIRTOFF;
    mb.mbox[13] = 8;
    mb.mbox[14] = 8;
    mb.mbox[15] = 0;
    mb.mbox[16] = 0;

    mb.mbox[17] = vidcore.MBOX_TAG_SETDEPTH;
    mb.mbox[18] = 4;
    mb.mbox[19] = 4;
    mb.mbox[20] = 32;

    mb.mbox[21] = vidcore.MBOX_TAG_SETPXLORDR;
    mb.mbox[22] = 4;
    mb.mbox[23] = 4;
    mb.mbox[24] = 0;

    mb.mbox[25] = vidcore.MBOX_TAG_GETFB;
    mb.mbox[26] = 8;
    mb.mbox[27] = 8;
    mb.mbox[28] = 4096;
    mb.mbox[29] = 0;

    mb.mbox[30] = vidcore.MBOX_TAG_GETPITCH;
    mb.mbox[31] = 4;
    mb.mbox[32] = 4;
    mb.mbox[33] = 0;

    mb.mbox[34] = vidcore.MBOX_TAG_LAST;

    if (mb.call(vidcore.MBOX_CH_PROP) and
        mb.mbox[20] == 32 and
        mb.mbox[28] != 0)
    {
        mb.mbox[28] &= 0x3FFFFFFF;
        width = mb.mbox[10];
        height = mb.mbox[11];
        pitch = mb.mbox[33];
        isrgb = mb.mbox[24];
        fb = @ptrFromInt(@as(usize, mb.mbox[28]));
    }
}

pub fn drawPixel(x: i32, y: i32, attr: u8) void {
    if (x < 0 or y < 0 or
        x >= @as(i32, @intCast(width)) or
        y >= @as(i32, @intCast(height)))
        return;

    const offs = @as(usize, @intCast(y)) * @as(usize, pitch) +
        @as(usize, @intCast(x)) * 4;

    const color = vgapal[attr & 0x0f];
    const pixel: *volatile u32 = @ptrCast(@alignCast(&fb[offs]));
    pixel.* = color;
}

pub fn drawRect(x1: i32, y1: i32, x2: i32, y2: i32, attr: u8, fill: bool) void {
    var y = y1;

    while (y <= y2) {
        var x = x1;

        while (x <= x2) {
            if ((x == x1 or x == x2) or (y == y1 or y == y2)) {
                drawPixel(x, y, attr);
            } else if (fill) {
                drawPixel(x, y, (attr & 0xf0) >> 4);
            }

            x += 1;
        }

        y += 1;
    }
}

pub fn drawLine(x1: i32, y1: i32, x2: i32, y2: i32, attr: u8) void {
    const dx: i32 = x2 - x1;
    const dy: i32 = y2 - y1;
    var p: i32 = 2 * dy - dx;
    var x = x1;
    var y = y1;

    while (x < x2) {
        if (p >= 0) {
            drawPixel(x, y, attr);
            y += 1;
            p = p + 2 * dy - 2 * dx;
        } else {
            drawPixel(x, y, attr);
            p = p + 2 * dy;
        }

        x += 1;
    }
}

pub fn drawCircle(x0: i32, y0: i32, radius: i32, attr: u8, fill: bool) void {
    var x = radius;
    var y: i32 = 0;
    var err: i32 = 0;

    while (x >= y) {
        if (fill) {
            drawLine(x0 - y, y0 + x, x0 + y, y0 + x, (attr & 0xf0) >> 4);
            drawLine(x0 - x, y0 + y, x0 + x, y0 + y, (attr & 0xf0) >> 4);
            drawLine(x0 - x, y0 - y, x0 + x, y0 - y, (attr & 0xf0) >> 4);
            drawLine(x0 - y, y0 - x, x0 + y, y0 - x, (attr & 0xf0) >> 4);
        }

        drawPixel(x0 - y, y0 + x, attr);
        drawPixel(x0 + y, y0 + x, attr);
        drawPixel(x0 - x, y0 + y, attr);
        drawPixel(x0 + x, y0 + y, attr);
        drawPixel(x0 - x, y0 - y, attr);
        drawPixel(x0 + x, y0 - y, attr);
        drawPixel(x0 - y, y0 - x, attr);
        drawPixel(x0 + y, y0 - x, attr);

        if (err <= 0) {
            y += 1;
            err += 2 * y + 1;
        }

        if (err > 0) {
            x -= 1;
            err -= 2 * x + 1;
        }
    }
}

pub fn drawChar(ch: u8, x: i32, y: i32, attr: u8) void {
    const glyph_index: usize = if (ch < FONT_NUMGLYPHS) ch else 0;

    for (0..FONT_HEIGHT) |i| {
        const glyph = text.font[glyph_index][i];

        for (0..FONT_WIDTH) |j| {
            const mask: u8 = @as(u8, 1) << @intCast(j);
            const col: u8 = if ((glyph & mask) != 0)
                attr & 0x0f
            else
                (attr & 0xf0) >> 4;

            drawPixel(
                x + @as(i32, @intCast(j)),
                y + @as(i32, @intCast(i)),
                col,
            );
        }
    }
}

pub fn drawString(x_: i32, y_: i32, s: []const u8, attr: u8) void {
    var x = x_;
    var y = y_;

    for (s) |ch| {
        if (ch == '\r') {
            x = 0;
        } else if (ch == '\n') {
            x = 0;
            y += FONT_HEIGHT;
        } else {
            drawChar(ch, x, y, attr);
            x += FONT_WIDTH;
        }
    }
}
