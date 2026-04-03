const std = @import("std");
const Position = @import("Position.zig");

pub const Rotation = struct {
    angle: f32,

    pub fn from(degrees: f32) Rotation {
        return Rotation{ .angle = degrees * (std.math.pi / 180.0) };
    }

    pub fn apply(self: Rotation, local: Position.Vec2) Position.Vec2 {
        const cos_a = @cos(self.angle);
        const sin_a = @sin(self.angle);
        return Position.Vec2{
            .x = local.x * cos_a - local.y * sin_a,
            .y = local.x * sin_a + local.y * cos_a,
        };
    }
};
