pub const os = @import("../root.zig");

pub const Window = struct {
    pos_x: i32,
    pos_y: i32,
    size_x: i32,
    size_y: i32,
    dirty: bool,
    title: []const u8,
    colors: WindowColors,
    mode: Theme,

    pub fn new(pos_x: i32, pos_y: i32, size_x: i32, size_y: i32, title: []const u8, mode: Theme) Window {
        var window = Window{
            .pos_x = pos_x,
            .pos_y = pos_y,
            .size_x = size_x,
            .size_y = size_y,
            .dirty = true,
            .title = title,
            .colors = WindowColors.light(),
            .mode = Theme.Light,
        };
        switch (mode) {
            Theme.Light => window.colors = WindowColors.light(),
            Theme.Dark => window.colors = WindowColors.dark(),
        }
        return window;
    }

    pub fn redraw(self: *Window) void {
        os.drivers.vidcore.fb.drawRect(self.pos_x, self.pos_y, self.size_x, self.size_y, self.colors.background, true);
        os.drivers.vidcore.fb.drawLine(self.pos_x, self.pos_y + 15, self.size_x + 1, 1, self.colors.content);

        os.drivers.vidcore.fb.drawLine(self.pos_x + 1, self.pos_y + 15, self.size_x, 1, self.colors.content);
        os.drivers.vidcore.fb.drawRect(self.pos_x + 5, self.pos_y + 20, self.size_x - 5, self.size_y - 5, self.colors.content, true);
        os.drivers.vidcore.fb.drawString(self.pos_x + 5, self.pos_y + 5, self.title, self.colors.foreground);
    }

    pub fn update(self: *Window) void {
        if (self.dirty) {
            self.redraw();
            self.dirty = false;
        }
    }
};

pub const WindowColors = struct {
    background: os.ui.color.Color,
    foreground: os.ui.color.Color,
    content: os.ui.color.Color,

    fn set(self: *WindowColors, background: os.ui.color.Color, foreground: os.ui.color.Color, content: os.ui.color.Color) void {
        self.background = background;
        self.foreground = foreground;
        self.content = content;
    }

    fn dark() WindowColors {
        return WindowColors{
            .background = os.ui.color.Color.from_u32(0x202020),
            .foreground = os.ui.color.Color.from_u32(0xAAAAAA),
            .content = os.ui.color.Color.from_u32(0x101010),
        };
    }

    fn light() WindowColors {
        return WindowColors{
            .background = os.ui.color.Color.from_u32(0xcccac4),
            .foreground = os.ui.color.Color.from_u32(0x101010),
            .content = os.ui.color.Color.from_u32(0x85847f),
        };
    }
};

pub const Theme = enum {
    Light,
    Dark,
};
