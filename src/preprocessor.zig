//! Preprocessor for collapsing repeated tokens

const std = @import("std");

pub const OpKind = enum {
    inc,
    dec,
    left,
    right,
    while_start,
    while_end,
    print,
    read,

    pub fn op_from_char(char: u8) ?OpKind {
        return switch (char) {
            '+' => .inc,
            '-' => .dec,
            '<' => .left,
            '>' => .right,

            '[' => .while_start,
            ']' => .while_end,

            '.' => .print,
            ',' => .read,

            else => null,
        };
    }
};

pub const Op = struct {
    kind: OpKind,
    extra: u32,
};

pub fn preproccess(buf: []const u8, al: *std.ArrayList(Op)) !void {
    var i: u32 = 0;
    while (i < buf.len) {
        const current = buf[i];
        switch (current) {
            '+', '-', '>', '<', '.', ',' => {
                const start = i;
                while (i < buf.len and buf[i] == current) {
                    i += 1;
                }
                const count = i - start;
                const opkind = OpKind.op_from_char(current) orelse unreachable;

                const op = Op{
                    .kind = opkind,
                    .extra = count,
                };

                _ = try al.append(op);
            },
            '[', ']' => {
                i += 1;
            },
            else => {
                i += 1;
            },
        }
    }
}
