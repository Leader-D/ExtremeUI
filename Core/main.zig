const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    std.debug.print("ExtremeUI v0.0.1 starting...\n", .{});
    std.debug.print("Platform: {s}\n", .{@tagName(builtin.os.tag)});

    std.debug.print("ExtremeUI initialized successfully.\n", .{});
}
