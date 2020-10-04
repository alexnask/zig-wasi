const std = @import("std");
const zig = @import("zig");

comptime {
    std.debug.assert(std.builtin.arch == .wasm32);
    std.debug.assert(std.builtin.os.tag == .wasi);
}

export fn buildIR(gpa: *std.mem.Allocator, directory: []const u8, file_name: []const u8) callconv(.Unspecified) !void {
    var preopens = std.fs.wasi.PreopenList.init(std.testing.allocator);
    defer preopens.deinit();
    try preopens.populate();

    const PreopenType = std.fs.wasi.PreopenType;
    const lib_preopen = preopens.find(PreopenType{ .Dir = "lib" }) orelse return error.LibDirectoryNotInPreopens;
    const cache_preopen = preopens.find(PreopenType{ .Dir = "zig-cache" }) orelse return error.CacheDirectoryNotInPreopens;
    const global_cache_preopen = preopens.find(PreopenType{ .Dir = ".cache" }) orelse return error.GlobalCacheDirectoryNotInPreopens;
    const source_directory_preopen = preopens.find(PreopenType{ .Dir = directory }) orelse return error.SourceDirectoryNotInPreopens;

    var root_pkg = zig.Package{
        .root_src_directory = .{
            .path = null,
            .handle = .{ .fd = source_directory_preopen.fd },
        },
        .root_src_path = file_name,
    };

    const random_seed = blk: {
        var random_seed: u64 = undefined;
        try std.crypto.randomBytes(std.mem.asBytes(&random_seed));
        break :blk random_seed;
    };
    var default_prng = std.rand.DefaultPrng.init(random_seed);

    const comp = try zig.Compilation.create(gpa, .{
        .zig_lib_directory = .{
            .path = null,
            .handle = .{ .fd = lib_preopen.fd },
        },
        .local_cache_directory = .{
            .path = null,
            .handle = .{ .fd = cache_preopen.fd },
        },
        .global_cache_directory = .{
            .path = null,
            .handle = .{ .fd = global_cache_preopen.fd },
        },
        .root_name = "root",
        .target = std.Target{
            .cpu = std.Target.Cpu.Model.generic(.x86_64).toCpu(.x86_64),
            .os = std.Target.Os.Tag.linux.defaultVersionRange(),
            .abi = .none,
        },
        .root_pkg = &root_pkg,
        .output_mode = .Obj,
        .rand = &default_prng.random,
        .emit_bin = null, // <- @TODO
        .object_format = null, // <- @TODO
        .optimize_mode = .Debug, // <- @TODO
        .keep_source_files_loaded = true, // true to get ZIR
        .is_native_os = false,
        .color = .Off,
    });
}
