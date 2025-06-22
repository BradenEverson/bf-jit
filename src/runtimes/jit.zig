//! Just In Time Compiled Runtime

const std = @import("std");
const linux = std.os.linux;

const Op = @import("../preprocessor.zig").Op;
const exit_err = @import("../main.zig").exit_err;
const elf = @import("compiler/elf.zig");
const create_binary = @import("compiler/bin.zig").create_binary;

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

        create_binary(self.commands, &program);

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
