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

    pub fn to_string(self: *const OpKind) []const u8 {
        return switch (self.*) {
            .inc => "inc",
            .dec => "dec",
            .left => "left",
            .right => "right",
            .while_start => "while_start",
            .while_end => "while_end",
            .print => "print",
            .read => "read",
        };
    }
};

pub const Op = struct {
    kind: OpKind,
    extra: u16,

    pub fn get_byte_size(self: *const Op) u16 {
        return switch (self.*.kind) {
            .inc => 3,
            .dec => 3,
            .left => 7,
            .right => 7,
            .while_start => 9,
            .while_end => 9,
            .print => 26 * self.*.extra,
            .read => 26,
        };
    }

    pub fn print_op(self: *const Op) void {
        const tag = self.kind.to_string();

        std.debug.print("{s} - {d}\n", .{ tag, self.extra });
    }
};

pub fn preproccess(buf: []const u8, al: *std.ArrayList(Op)) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var stack = std.ArrayList(u16).init(allocator);
    defer stack.deinit();

    var i: u16 = 0;
    while (i < buf.len) {
        const current = buf[i];
        switch (current) {
            '+', '-', '>', '<', '.', ',' => {
                const opkind = OpKind.op_from_char(current) orelse unreachable;
                const start = i;
                while (i < buf.len and buf[i] == current) {
                    i += 1;
                }
                const count = i - start;

                const op = Op{
                    .kind = opkind,
                    .extra = count,
                };

                _ = try al.append(op);
            },
            '[', ']' => {
                const opkind = OpKind.op_from_char(current) orelse unreachable;
                const op = Op{
                    .kind = opkind,
                    .extra = 0x404,
                };

                _ = try al.append(op);

                i += 1;
            },
            else => {
                i += 1;
            },
        }
    }

    // Step two: fill in the while loops

    i = 0;

    while (i < al.items.len) {
        const op = &al.items[i];
        if (op.kind == .while_start) {
            _ = try stack.append(i);
        } else if (op.kind == .while_end) {
            const prev = stack.pop() orelse unreachable;
            op.*.extra = prev;
            al.items[prev].extra = i;
        }

        i += 1;
    }
}
