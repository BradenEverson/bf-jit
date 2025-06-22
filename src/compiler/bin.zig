//! Utility function for converting a command stream to x86-64 machine binary

const Op = @import("../preprocessor.zig").Op;
const std = @import("std");
const exit_err = @import("../main.zig").exit_err;

pub fn create_binary(commands: []Op, program: *std.ArrayList(u8)) void {
    var curr_offset: i32 = 0;

    for (commands) |cmd| {
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
                    // mov rax, 1
                    0x48,
                    0xc7,
                    0xc0,
                    0x01,
                    0x00,
                    0x00,
                    0x00,
                    // mov rsi, rbx
                    0x48,
                    0x89,
                    0xde,
                    // mov rdi, 1
                    0x48,
                    0xc7,
                    0xc7,
                    0x01,
                    0x00,
                    0x00,
                    0x00,
                    // mov rdx, 1
                    0x48,
                    0xc7,
                    0xc2,
                    0x01,
                    0x00,
                    0x00,
                    0x00,
                    // syscall
                    0x0f,
                    0x05,
                };

                for (0..cmd.extra) |_| {
                    program.appendSlice(&instr) catch exit_err("Failed to append to array :(");
                }
            },

            .read => {
                const instr = [_]u8{
                    // mov rax, 0
                    0x48,
                    0xc7,
                    0xc0,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    // mov rsi, rbx
                    0x48,
                    0x89,
                    0xde,
                    // mov rdi, 0
                    0x48,
                    0xc7,
                    0xc7,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    // mov rdx, 1
                    0x48,
                    0xc7,
                    0xc2,
                    0x01,
                    0x00,
                    0x00,
                    0x00,
                    // syscall
                    0x0f,
                    0x05,
                };

                program.appendSlice(&instr) catch exit_err("Failed to append to array :(");
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
                    close_offset += commands[i].get_byte_size();
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
                    close_offset += commands[i].get_byte_size();
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
        }

        curr_offset += cmd.get_byte_size();
    }
}
