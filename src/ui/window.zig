const std = @import("std");
const os = @import("../root.zig");
const Color = os.ui.color.Color;

pub const Window = struct {
    pos_x: i32,
    pos_y: i32,
    size_x: usize,
    size_y: usize,
    dirty: bool,
    title: []const u8,
    colors: WindowColors,
    mode: Theme,

    framebuffer: []u32,
    stride: usize,
    framebuffer_width: usize,
    framebuffer_height: usize,

    pub fn new(
        framebuffer: []u32,
        pos_x: i32,
        pos_y: i32,
        size_x: usize,
        size_y: usize,
        title: []const u8,
        mode: Theme,
    ) Window {
        std.debug.assert(framebuffer.len >= size_x * size_y);

        var window = Window{
            .pos_x = pos_x,
            .pos_y = pos_y,
            .size_x = size_x,
            .size_y = size_y,
            .dirty = true,
            .title = title,
            .colors = undefined,
            .mode = mode,
            .framebuffer = framebuffer[0 .. size_x * size_y],
            .stride = size_x,
            .framebuffer_width = size_x,
            .framebuffer_height = size_y,
        };

        window.colors = switch (mode) {
            .Light => WindowColors.light(),
            .Dark => WindowColors.dark(),
        };

        return window;
    }

    pub fn mark_dirty(self: *Window) void {
        self.dirty = true;
    }

    pub fn clear(self: *Window, color: Color) void {
        @memset(self.framebuffer, pack_color(color));
        self.dirty = true;
    }

    pub fn set_pixel(self: *Window, x: usize, y: usize, color: Color) void {
        if (x >= self.framebuffer_width or y >= self.framebuffer_height) return;
        self.framebuffer[y * self.stride + x] = pack_color(color);
        self.dirty = true;
    }

    pub fn draw_line(self: *Window, x1: usize, y1: usize, x2: usize, y2: usize, color: Color) void {
        const dx: i32 = if (x1 <= x2) @as(i32, @intCast(x2 - x1)) else -@as(i32, @intCast(x1 - x2));
        const dy: i32 = if (y1 <= y2) @as(i32, @intCast(y2 - y1)) else -@as(i32, @intCast(y1 - y2));
        const sx: i32 = if (x1 < x2) 1 else -1;
        const sy: i32 = if (y1 < y2) 1 else -1;
        var err: i32 = dx - dy;

        var current_x = x1;
        var current_y = y1;

        while (true) {
            self.set_pixel(current_x, current_y, color);
            if (current_x == x2 and current_y == y2) break;
            const e2 = 2 * err;
            if (e2 > -dy) {
                err -= dy;
                current_x = @as(usize, @intCast(@as(i32, @intCast(current_x)) + sx));
            }
            if (e2 < dx) {
                err += dx;
                current_y = @as(usize, @intCast(@as(i32, @intCast(current_y)) + sy));
            }
        }

        self.dirty = true;
    }

    pub fn draw_rect(
        self: *Window,
        x1: usize,
        y1: usize,
        x2: usize,
        y2: usize,
        color: Color,
        fill: bool,
    ) void {
        if (self.framebuffer_width == 0 or self.framebuffer_height == 0) return;

        const right = @min(x2, self.framebuffer_width - 1);
        const bottom = @min(y2, self.framebuffer_height - 1);
        if (x1 > right or y1 > bottom) return;

        if (fill) {
            var current_y = y1;
            while (current_y <= bottom) : (current_y += 1) {
                var current_x = x1;
                while (current_x <= right) : (current_x += 1) {
                    self.framebuffer[current_y * self.stride + current_x] = pack_color(color);
                }
            }
        } else {
            var current_x = x1;
            while (current_x <= right) : (current_x += 1) {
                self.framebuffer[y1 * self.stride + current_x] = pack_color(color);
                self.framebuffer[bottom * self.stride + current_x] = pack_color(color);
            }

            var current_y = y1;
            while (current_y <= bottom) : (current_y += 1) {
                self.framebuffer[current_y * self.stride + x1] = pack_color(color);
                self.framebuffer[current_y * self.stride + right] = pack_color(color);
            }
        }

        self.dirty = true;
    }

    pub fn redraw(self: *Window) void {
        const window_width = self.size_x;
        const window_height = self.size_y;
        const window_colors = self.colors;

        self.draw_rect(
            0,
            0,
            window_width - 1,
            window_height - 1,
            window_colors.background,
            true,
        );

        self.draw_line(0, 0, window_width - 1, 0, window_colors.highlight);
        self.draw_line(0, 0, 0, window_height - 1, window_colors.highlight);
        self.draw_line(0, window_height - 1, window_width - 1, window_height - 1, window_colors.shadow);
        self.draw_line(window_width - 1, 0, window_width - 1, window_height - 1, window_colors.shadow);

        self.draw_rect(5, 5, window_width - 6, 20, window_colors.titlebar, true);

        self.draw_rect(5, 25, window_width - 6, window_height - 6, window_colors.content, true);

        self.draw_line(5, 25, window_width - 6, 25, window_colors.shadow);
        self.draw_line(5, 25, 5, window_height - 6, window_colors.shadow);
        self.draw_line(window_width - 6, 25, window_width - 6, window_height - 6, window_colors.highlight);
        self.draw_line(5, window_height - 6, window_width - 6, window_height - 6, window_colors.highlight);

        self.draw_string(10, 10, self.title, window_colors.foreground);
        self.dirty = true;
    }

    pub fn draw_string(self: *Window, start_x: usize, start_y: usize, text: []const u8, color: Color) void {
        var current_x = start_x;
        var current_y = start_y;

        for (text) |character| {
            if (character == '\r') {
                current_x = 0;
            } else if (character == '\n') {
                current_x = 0;
                current_y += os.drivers.vidcore.fb.FONT_HEIGHT;
            } else {
                self.draw_char(character, current_x, current_y, color);
                current_x += os.drivers.vidcore.fb.FONT_WIDTH;
            }
        }

        self.dirty = true;
    }

    fn draw_char(self: *Window, character: u8, char_x: usize, char_y: usize, color: Color) void {
        const glyph_index: usize = if (character < os.drivers.vidcore.fb.FONT_NUMGLYPHS) character else 0;

        for (0..os.drivers.vidcore.fb.FONT_HEIGHT) |row_index| {
            const glyph_row = os.ui.text.font[glyph_index][row_index];

            for (0..os.drivers.vidcore.fb.FONT_WIDTH) |col_index| {
                const mask: u8 = @as(u8, 1) << @intCast(col_index);
                if ((glyph_row & mask) != 0) {
                    self.set_pixel(char_x + col_index, char_y + row_index, color);
                }
            }
        }
    }

    fn pack_color(color: Color) u32 {
        return (@as(u32, color.a) << 24) |
            (@as(u32, color.r) << 16) |
            (@as(u32, color.g) << 8) |
            @as(u32, color.b);
    }
};

pub const WindowColors = struct {
    background: Color,
    foreground: Color,
    content: Color,
    titlebar: Color,
    shadow: Color,
    highlight: Color,

    fn dark() WindowColors {
        return .{
            .background = Color.from_u32(0x303030),
            .foreground = Color.from_u32(0xAAAAAA),
            .content = Color.from_u32(0x202020),
            .titlebar = Color.from_u32(0x303030),
            .shadow = Color.from_u32(0x101010),
            .highlight = Color.from_u32(0xBBBBBB),
        };
    }

    fn light() WindowColors {
        return .{
            .background = Color.from_u32(0xCCCAC4),
            .foreground = Color.from_u32(0xEEEEEE),
            .content = Color.from_u32(0x6B6A67),
            .titlebar = Color.from_u32(0x404040),
            .shadow = Color.from_u32(0x505050),
            .highlight = Color.from_u32(0xDDDDDD),
        };
    }
};

pub const Theme = enum { Light, Dark };
