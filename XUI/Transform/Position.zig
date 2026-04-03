const std = @import("std");
const Config = @import("../../Core/Config.zig");

pub const Vec2 = struct {
    x: f32,
    y: f32,
};

pub const Position = struct {
    vec: Vec2,

    pub fn from(x: f32, y: f32) Position {
        return Position{ .vec = Vec2{ .x = x, .y = y } };
    }

    pub fn apply(self: Position, pixel_x: f32, pixel_y: f32) Vec2 {
        return Vec2{
            .x = Config.toUnitX(pixel_x) - self.vec.x,
            .y = Config.toUnitY(pixel_y) - self.vec.y,
        };
    }
};
