//! Compiler Runtime

const std = @import("std");
const Op = @import("preprocessor.zig").Op;
const exit_err = @import("main.zig").exit_err;
const elf = @import("compiler/elf.zig");

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

        const program = [_]u8{
            // Mov 0x00402000 to EBX, that's the start address of the 30k block
            0x48, 0xC7, 0xC3, 0x00, 0x20, 0x40, 0x00,

            // Mov Rax, 1
            0x48, 0xC7, 0xC0, 0x01, 0x00, 0x00, 0x00,
            // Mov Rdi, 1
            0x48, 0xC7, 0xC7, 0x01, 0x00, 0x00, 0x00,
            // Mov Rsi, [rbx]
            0x48, 0x89, 0xDE,
            // Mov Rdx, 1
            0x48, 0xC7, 0xC2, 0x01,
            0x00, 0x00, 0x00,
            // Syscall
            0x0F, 0x05,
        };

        elf.wrap_elf(&program, &buf) catch exit_err("Elf bad");
        _ = self.fd.write(buf.items) catch exit_err("Writing bad");
    }
};
