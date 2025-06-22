//! Interpreter Runtime

const std = @import("std");
const Op = @import("preprocessor.zig").Op;
const exit_err = @import("main.zig").exit_err;

pub const InterprettedRuntime = struct {
    commands: []Op,
    state: [30_000]u8,
    pc: u16,
    cursor: u16,

    pub fn new(commands: []Op) InterprettedRuntime {
        return InterprettedRuntime{ .commands = commands, .state = [_]u8{0} ** 30_000, .pc = 0, .cursor = 0 };
    }

    pub fn deinit(self: *InterprettedRuntime) void {
        _ = self;
    }

    pub fn run(self: *InterprettedRuntime) void {
        const stdin = std.io.getStdIn();
        const reader = stdin.reader();

        while (self.pc < self.commands.len) {
            const op = self.commands[self.pc];
            switch (op.kind) {
                .inc => {
                    self.state[self.cursor] +%= @intCast(op.extra % 256);
                    self.pc += 1;
                },

                .dec => {
                    self.state[self.cursor] -%= @intCast(op.extra % 256);
                    self.pc += 1;
                },

                .left => {
                    self.cursor -= op.extra;
                    self.pc += 1;
                },

                .right => {
                    self.cursor += op.extra;
                    self.pc += 1;
                },

                .print => {
                    for (0..op.extra) |_| {
                        std.debug.print("{c}", .{self.state[self.cursor]});
                    }

                    self.pc += 1;
                },

                .while_start => {
                    if (self.state[self.cursor] == 0) {
                        self.pc = op.extra;
                    } else {
                        self.pc += 1;
                    }
                },

                .while_end => {
                    if (self.state[self.cursor] != 0) {
                        self.pc = op.extra;
                    } else {
                        self.pc += 1;
                    }
                },

                .read => {
                    const byte = reader.readByte() catch exit_err("Reading 1 byte failed");
                    self.state[self.cursor] = byte;
                    self.pc += 1;
                },
            }
        }
    }
};
