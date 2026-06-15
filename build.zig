const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("zig-chess", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const root_unit_tests = b.addTest(.{
        .name = "lib tests",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const chess960_unit_tests = b.addTest(.{
        .name = "chess960 tests",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/chess960/chess960.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_root_unit_tests = b.addRunArtifact(root_unit_tests);
    const run_chess960_unit_tests = b.addRunArtifact(chess960_unit_tests);

    const test_step = b.step("test", "Run unit tests");

    test_step.dependOn(&run_root_unit_tests.step);
    test_step.dependOn(&run_chess960_unit_tests.step);
}
