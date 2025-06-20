//! Compiler Runtime

const std = @import("std");
const Op = @import("preprocessor.zig").Op;
const exit_err = @import("main.zig").exit_err;

pub const CompiledRuntime = struct {
    commands: []Op,
    fd: std.fs.File,

    pub fn new(commands: []Op) CompiledRuntime {
        const fd = std.fs.cwd().createFile("out", .{ .read = false, .truncate = true, .mode = 0o755 }) catch exit_err("Failed to make file");
        return CompiledRuntime{ .commands = commands, .fd = fd };
    }

    pub fn deinit(self: *CompiledRuntime) void {
        self.fd.close();
    }

    pub fn run(self: *CompiledRuntime) void {
        _ = self;
    }
};
