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
};

pub const Op = struct {
    kind: OpKind,
    extra: u32,
};

pub fn preproccess(buf: []const u8, al: *std.ArrayList(Op)) void {
    _ = al;
    _ = buf;
}
