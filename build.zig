const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "ExtremeUI",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const os = @import("builtin").os.tag;

    if (os == .windows) {
        exe.linkSystemLibrary("gdi32");
        exe.linkSystemLibrary("user32");
        exe.linkSystemLibrary("vulkan-1");
    } else if (os == .linux) {
        exe.linkSystemLibrary("X11");
        exe.linkSystemLibrary("vulkan");
    } else if (os == .macos) {
        exe.linkFramework("Cocoa");
        exe.linkFramework("Metal");
        exe.linkFramework("MetalKit");
    }

    exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run ExtremeUI");
    run_step.dependOn(&run_cmd.step);
}
