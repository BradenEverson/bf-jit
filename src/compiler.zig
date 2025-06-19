//! Compiler Runtime

const std = @import("std");
const Op = @import("preprocessor.zig").Op;
const exit_err = @import("main.zig").exit_err;

pub const CompiledRuntime = struct {
    commands: []Op,
    fd: std.fs.File,

    pub fn new(commands: []Op) CompiledRuntime {
        const fd = std.fs.cwd().createFile("out.s", .{}) catch exit_err("Failed to make file");
        return CompiledRuntime{ .commands = commands, .fd = fd };
    }

    pub fn run(self: *CompiledRuntime) void {
        _ = self.fd.write(
            \\section .bss
            \\tape: resb 30000
            \\
            \\section .text
            \\global _start
            \\_start:
            \\
            \\mov rbx, tape
            \\
        ) catch exit_err("Failed to write :(");

        _ = self.fd.write(
            \\
            \\mov rax, 60
            \\mov rdi, 0
            \\syscall
            \\
        ) catch exit_err("Failed to write :(");
        self.fd.close();
    }
};
