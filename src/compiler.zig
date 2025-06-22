//! Compiler Runtime

const std = @import("std");
const Op = @import("preprocessor.zig").Op;
const exit_err = @import("main.zig").exit_err;
const elf = @import("compiler/elf.zig");

const create_binary = @import("compiler/bin.zig").create_binary;

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
        const allocator = std.heap.page_allocator;
        var buf = std.ArrayList(u8).init(allocator);
        defer buf.deinit();

        var program = std.ArrayList(u8).init(allocator);

        const start = [_]u8{ 0x48, 0xC7, 0xC3, 0x00, 0x20, 0x40, 0x00 };
        program.appendSlice(&start) catch exit_err("Failed to append to array :(");

        create_binary(self.commands, &program);

        elf.wrap_elf(program.items, &buf) catch exit_err("Elf bad");
        _ = self.fd.write(buf.items) catch exit_err("Writing bad");
    }
};
