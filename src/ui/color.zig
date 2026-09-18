pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub fn rgb(r: u8, g: u8, b: u8) Color {
        return .{ .r = r, .g = g, .b = b, .a = 255 };
    }

    pub fn from_u32(value: u32) Color {
        if (value <= 0xFFFFFF) {
            return .{
                .r = @intCast((value >> 16) & 0xFF),
                .g = @intCast((value >> 8) & 0xFF),
                .b = @intCast(value & 0xFF),
                .a = 255,
            };
        }

        return .{
            .r = @intCast((value >> 24) & 0xFF),
            .g = @intCast((value >> 16) & 0xFF),
            .b = @intCast((value >> 8) & 0xFF),
            .a = @intCast(value & 0xFF),
        };
    }
};
