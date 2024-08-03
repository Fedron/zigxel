const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zigxel",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const mach_glfw_dep = b.dependency("mach-glfw", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("mach-glfw", mach_glfw_dep.module("mach-glfw"));

    const gl_bindings = @import("zigglgen").generateBindingsModule(b, .{ .api = .gl, .version = .@"4.6", .profile = .core, .extensions = &.{} });
    exe.root_module.addImport("gl", gl_bindings);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}