//! Just In Time Compiled Runtime

const std = @import("std");
const linux = std.os.linux;

const Op = @import("preprocessor.zig").Op;
const exit_err = @import("main.zig").exit_err;
const elf = @import("compiler/elf.zig");

pub const JitRuntime = struct {
    commands: []Op,
    buffer: [30_000]u8,

    pub fn new(commands: []Op) JitRuntime {
        return JitRuntime{ .commands = commands, .buffer = [_]u8{0} ** 30_000 };
    }

    pub fn deinit(self: *JitRuntime) void {
        _ = self;
    }

    pub fn run(self: *JitRuntime) void {
        const allocator = std.heap.page_allocator;
        var buf = std.ArrayList(u8).init(allocator);
        defer buf.deinit();

        var program = std.ArrayList(u8).init(allocator);

        const buf_ptr: usize = @intFromPtr(&self.buffer);
        const start = [_]u8{
            0x48,
            0xBB,
            @intCast((buf_ptr >> 0) & 0xFF),
            @intCast((buf_ptr >> 8) & 0xFF),
            @intCast((buf_ptr >> 16) & 0xFF),
            @intCast((buf_ptr >> 24) & 0xFF),
            @intCast((buf_ptr >> 32) & 0xFF),
            @intCast((buf_ptr >> 40) & 0xFF),
            @intCast((buf_ptr >> 48) & 0xFF),
            @intCast((buf_ptr >> 56) & 0xFF),
        };

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

        // ret
        program.append(0xc3) catch exit_err("Bro you really failed on apending the last byte???");

        const size = program.items.len;
        const ptr = linux.mmap(null, size, linux.PROT.READ | linux.PROT.WRITE | linux.PROT.EXEC, .{ .TYPE = .PRIVATE, .EXECUTABLE = true, .ANONYMOUS = true }, -1, 0);

        const ptr_slice: [*]u8 = @ptrFromInt(ptr);
        @memcpy(ptr_slice[0..size], program.items);

        const jit: *fn () void = @ptrCast(ptr_slice);
        jit();

        _ = linux.munmap(ptr_slice, size);
    }
};
