const Config = @import("../../Core/Config.zig");

pub const Size = struct {
    width:  f32,
    height: f32,

    pub fn from(width: f32, height: f32) Size {
        return Size{ .width = width, .height = height };
    }

    pub fn apply(self: Size, value: f32) f32 {
        const avg_unit = (Config.unit_x + Config.unit_y) / 2.0;
        return value * self.width * avg_unit;
    }
};
