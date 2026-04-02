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

    // ─── Platform-specific dependencies ───────────────────────────
    // Later, Comptime in Core/Installer will handle this automatically.
    const os = @import("builtin").os.tag;

    if (os == .windows) {
        // Windows: link against Win32 and Vulkan
        exe.linkSystemLibrary("gdi32");
        exe.linkSystemLibrary("user32");
        exe.linkSystemLibrary("vulkan-1");
    } else if (os == .linux) {
        // Linux: link against X11/Wayland and Vulkan
        exe.linkSystemLibrary("X11");
        exe.linkSystemLibrary("vulkan");
    } else if (os == .macos) {
        // macOS: link against Cocoa and Metal
        // Note: SPIR-V will be cross-compiled to MSL via Core/Shad-gines later
        exe.linkFramework("Cocoa");
        exe.linkFramework("Metal");
        exe.linkFramework("MetalKit");
    }

    exe.linkLibC();

    b.installArtifact(exe);

    // ─── Run step ─────────────────────────────────────────────────
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run ExtremeUI");
    run_step.dependOn(&run_cmd.step);
}
