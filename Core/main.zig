const std      = @import("std");
const builtin  = @import("builtin");
const Config   = @import("Config.zig");
const Engine   = @import("Shad-gines/SPIR-V/Runtime/Engine.zig");
const Platform = @import("Platform/Linux_win.zig");

pub fn main() !void {
    std.debug.print("ExtremeUI v0.0.1 starting...\n", .{});
    std.debug.print("Platform: {s}\n", .{@tagName(builtin.os.tag)});

    try Platform.open();
}
