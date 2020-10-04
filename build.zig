const std = @import("std");
const Builder = std.build.Builder;
const Pkg = std.build.Pkg;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const lib = b.addStaticLibrary("zig-wasi", "src/main.zig");

    lib.setBuildMode(mode);
    lib.addBuildOption(bool, "is_stage1", false);
    lib.addBuildOption(bool, "have_llvm", false);
    lib.addBuildOption(bool, "enable_tracy", false);
    lib.addBuildOption([]const u8, "version", "0.6.0-modded");

    // @TODO Better way to inherit te build options package.
    const build_options_file = std.fs.path.join(
        b.allocator,
        &[_][]const u8{ b.cache_root, b.fmt("{}_build_options.zig", .{lib.name}) },
    ) catch unreachable;

    lib.addPackage(.{
        .name = "zig",
        .path = "zig/src/main.zig",
        .dependencies = &[_]Pkg{.{
            .name = "build_options",
            .path = b.pathFromRoot(build_options_file),
        }},
    });
    lib.setTarget(.{
        .cpu_arch = .wasm32,
        .os_tag = .wasi,
    });
    lib.install();
}
