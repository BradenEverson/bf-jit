//! Compiler Runtime

const std = @import("std");
const Op = @import("preprocessor.zig").Op;
const exit_err = @import("main.zig").exit_err;

pub const AssembledRuntime = struct {
    commands: []Op,
    fd: std.fs.File,

    pub fn new(commands: []Op) AssembledRuntime {
        const fd = std.fs.cwd().createFile("out.s", .{}) catch exit_err("Failed to make file");
        return AssembledRuntime{ .commands = commands, .fd = fd };
    }

    pub fn deinit(self: *AssembledRuntime) void {
        self.fd.close();
    }

    pub fn run(self: *AssembledRuntime) void {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

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

        for (self.commands, 0..) |cmd, i| {
            switch (cmd.kind) {
                .left => {
                    const instr = std.fmt.allocPrint(allocator, "sub rbx, {d}\n", .{cmd.extra}) catch exit_err("Failed to format string");
                    _ = self.fd.write(instr) catch exit_err("Failed to write ;(");
                },
                .right => {
                    const instr = std.fmt.allocPrint(allocator, "add rbx, {d}\n", .{cmd.extra}) catch exit_err("Failed to format string");
                    _ = self.fd.write(instr) catch exit_err("Failed to write ;(");
                },
                .inc => {
                    const instr = std.fmt.allocPrint(allocator, "add byte [rbx], {d}\n", .{cmd.extra}) catch exit_err("Failed to format string");
                    _ = self.fd.write(instr) catch exit_err("Failed to write ;(");
                },
                .dec => {
                    const instr = std.fmt.allocPrint(allocator, "sub byte [rbx], {d}\n", .{cmd.extra}) catch exit_err("Failed to format string");
                    _ = self.fd.write(instr) catch exit_err("Failed to write ;(");
                },

                .print => {
                    const instr = std.fmt.allocPrint(allocator,
                        \\mov rax, 1
                        \\mov rdi, 1
                        \\mov rsi, rbx
                        \\mov rdx, 1
                        \\syscall
                        \\
                    , .{}) catch exit_err("Failed to format string");

                    for (0..cmd.extra) |_| {
                        _ = self.fd.write(instr) catch exit_err("Failed to write ;(");
                    }
                },

                .while_start => {
                    const instr = std.fmt.allocPrint(allocator,
                        \\open{d}:
                        \\cmp byte [rbx], 0
                        \\je close{d}
                        \\
                    , .{ i, cmd.extra }) catch exit_err("Failed to format string");

                    _ = self.fd.write(instr) catch exit_err("Failed to write ;(");
                },

                .while_end => {
                    const instr = std.fmt.allocPrint(allocator,
                        \\cmp byte [rbx], 0
                        \\jne open{d}
                        \\close{d}:
                        \\
                    , .{ cmd.extra, i }) catch exit_err("Failed to format string");

                    _ = self.fd.write(instr) catch exit_err("Failed to write ;(");
                },

                else => @panic("not implemented"), // unimplemented for now
            }
        }

        _ = self.fd.write(
            \\
            \\mov rax, 60
            \\mov rdi, 0
            \\syscall
            \\
        ) catch exit_err("Failed to write :(");
    }
};
