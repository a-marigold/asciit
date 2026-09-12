const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "asciit",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,

            .error_tracing = null,
            .omit_frame_pointer = true,
            .stack_check = false,
            .single_threaded = true,
            .strip = true,
            .unwind_tables = .none,
            .stack_protector = false,
            .link_libc = false,
        }),
    });

    b.installArtifact(exe);
}
