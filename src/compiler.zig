//! Compiler Runtime

const Op = @import("preprocessor.zig").Op;

pub const CompiledRuntime = struct {
    commands: []Op,

    pub fn new(commands: []Op) CompiledRuntime {
        return CompiledRuntime{ .commands = commands };
    }
};
