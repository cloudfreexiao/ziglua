const std = @import("std");

const Build = std.Build;
const Step = std.Build.Step;

pub fn configure(b: *Build, target: Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, upstream: *Build.Dependency, shared: bool) *Step.Compile {
    const lib_opts = .{
        .name = "lua",
        .target = target,
        .optimize = optimize,
        .version = std.SemanticVersion{ .major = 5, .minor = 4, .patch = 7 },
    };
    const lib = if (shared)
        b.addSharedLibrary(lib_opts)
    else
        b.addStaticLibrary(lib_opts);

    lib.addIncludePath(upstream.path("src"));

    const flags = [_][]const u8{
        // Standard version used in Lua Makefile
        "-std=gnu99",

        // Define target-specific macro
        switch (target.result.os.tag) {
            .linux => "-DLUA_USE_LINUX",
            .macos => "-DLUA_USE_MACOSX",
            .windows => "-DLUA_USE_WINDOWS",
            else => "-DLUA_USE_POSIX",
        },

        // Enable api check
        if (optimize == .Debug) "-DLUA_USE_APICHECK" else "",
    };

    const lua_source_files = &skynet_lua_source_files;

    lib.addCSourceFiles(.{
        .root = .{ .dependency = .{
            .dependency = upstream,
            .sub_path = "",
        } },
        .files = lua_source_files,
        .flags = &flags,
    });

    lib.linkLibC();

    lib.installHeader(upstream.path("src/skynetlua.h"), "skynetlua.h");

    return lib;
}

const skynet_lua_source_files = [_][]const u8{
    "src/skynetlua.c",
};
