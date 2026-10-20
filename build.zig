const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    addApp(b, raylib_dep, target, optimize, "dot_tree_gui", "src/dot_tree_gui.zig", "run-dot-tree", "Run the DotTreeGUI");
    addApp(b, raylib_dep, target, optimize, "collision_gui", "src/collision_gui.zig", "run-collision", "Run the CollisionGUI");
}

fn addApp(b: *std.Build, raylib_dep: *std.Build.Dependency, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, name: []const u8, root_source: []const u8, step_name: []const u8, step_desc: []const u8) void {
    const exe = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = b.path(root_source),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.root_module.addImport("raylib", raylib_dep.module("raylib"));
    exe.root_module.linkLibrary(raylib_dep.artifact("raylib"));

    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    if (b.args) |args| run.addArgs(args);
    b.step(step_name, step_desc).dependOn(&run.step);
}
