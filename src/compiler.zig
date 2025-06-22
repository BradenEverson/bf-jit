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

        var program = std.ArrayList(u8).init(allocator);

        const start = [_]u8{ 0x48, 0xC7, 0xC3, 0x00, 0x20, 0x40, 0x00 };
        program.appendSlice(&start) catch exit_err("Failed to append to array :(");

        var curr_offset: i32 = 0;

        for (self.commands) |cmd| {
            switch (cmd.kind) {
                .right => {
                    // Add rbx, *extra*
                    const instr = [_]u8{ 0x48, 0x81, 0xC3, @intCast(cmd.extra & 0xFF), @intCast((cmd.extra >> 8) & 0xFF), 0x00, 0x00 };
                    program.appendSlice(&instr) catch exit_err("Failed to append to array :(");
                },

                .left => {
                    // Add ebx, *extra*
                    const instr = [_]u8{ 0x48, 0x81, 0xEB, @intCast(cmd.extra & 0xFF), @intCast((cmd.extra >> 8) & 0xFF), 0x00, 0x00 };
                    program.appendSlice(&instr) catch exit_err("Failed to append to array :(");
                },

                .print => {
                    const instr = [_]u8{
                        // Mov Rax, 1
                        0xB8, 0x01, 0x00, 0x00, 0x00,
                        // Mov Rdi, 1
                        0xBF, 0x01, 0x00, 0x00, 0x00,
                        // Mov Rsi, Rbx
                        0x89, 0xDE,
                        // Mov Rdx, 1
                        0xBA, 0x01, 0x00,
                        0x00, 0x00,
                        // Syscall
                        0x0F, 0x05,
                    };

                    for (0..cmd.extra) |_| {
                        program.appendSlice(&instr) catch exit_err("Failed to append to array :(");
                    }
                },

                .inc => {
                    // Add byte [ebx], *extra*
                    const instr = [_]u8{ 0x80, 0x03, @intCast(cmd.extra % 0x100) };
                    program.appendSlice(&instr) catch exit_err("Failed to append to array :(");
                },

                .dec => {
                    // Sub byte [ebx], *extra*
                    const instr = [_]u8{ 0x80, 0x2B, @intCast(cmd.extra % 0x100) };
                    program.appendSlice(&instr) catch exit_err("Failed to append to array :(");
                },

                .while_start => {
                    var close_offset: i32 = 0;
                    for (0..cmd.extra) |i| {
                        close_offset += self.commands[i].get_byte_size();
                    }

                    const offset: i32 = close_offset - curr_offset;

                    const instr = [_]u8{
                        // Cmp byte [ebx], 0 (I really hate what zls format is doing here)
                        0x80,                           0x3b,                            0x00,
                        // jump near if equal {offset}
                        0x0F,                           0x84,                            @intCast((offset >> 0) & 0xFF),
                        @intCast((offset >> 8) & 0xFF), @intCast((offset >> 16) & 0xFF), @intCast((offset >> 24) & 0xFF),
                    };
                    program.appendSlice(&instr) catch exit_err("Failed to append to array :(");
                },

                .while_end => {
                    var close_offset: i32 = 0;
                    for (0..cmd.extra) |i| {
                        close_offset += self.commands[i].get_byte_size();
                    }

                    const offset: i32 = close_offset - curr_offset;

                    const instr = [_]u8{
                        // Cmp byte [ebx], 0 (I really hate what zls format is doing here)
                        0x80,                           0x3b,                            0x00,
                        // jump near if equal {offset}
                        0x0F,                           0x85,                            @intCast((offset >> 0) & 0xFF),
                        @intCast((offset >> 8) & 0xFF), @intCast((offset >> 16) & 0xFF), @intCast((offset >> 24) & 0xFF),
                    };
                    program.appendSlice(&instr) catch exit_err("Failed to append to array :(");
                },

                else => {},
            }

            curr_offset += cmd.get_byte_size();
        }

        elf.wrap_elf(program.items, &buf) catch exit_err("Elf bad");
        _ = self.fd.write(buf.items) catch exit_err("Writing bad");
    }
};
