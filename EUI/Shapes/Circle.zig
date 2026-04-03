const Position = @import("../Transform/Position.zig");
const Size     = @import("../Transform/Size.zig");
const Rotation = @import("../Transform/Rotation.zig");
const Colors   = @import("../Colors/Colors.zig");

pub const Circle = struct {
    position: Position.Vec2,
    size:     Size.Size,
    rotation: Rotation.Rotation,
    radius:   f32,
    color:    Colors.RGBA,

    pub fn sdf(self: Circle, pixel_x: f32, pixel_y: f32) f32 {
        var local = Position.apply(self.position, pixel_x, pixel_y);
        local = self.rotation.apply(local);
        const scaled_radius = self.size.apply(self.radius);
        return @sqrt(local.x * local.x + local.y * local.y) - scaled_radius;
    }
};
