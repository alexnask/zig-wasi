const std = @import("std");
const Builder = std.build.Builder;
const Pkg = std.build.Pkg;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const lib = b.addStaticLibrary("zig-wasi", "src/main.zig");

    lib.setBuildMode(mode);
    lib.addPackage(.{
        .name = "zig",
        .path = "zig/src/main.zig",
        .dependencies = &[_]Pkg{.{
            .name = "build_options",
            .path = "build_options.zig",
        }},
    });
    lib.setTarget(.{
        .cpu_arch = .wasm32,
        .os_tag = .wasi,
    });
    lib.install();
}
