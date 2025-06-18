//! Interpreter Runtime

const Op = @import("preprocessor.zig").Op;

pub const InterprettedRuntime = struct {
    commands: []Op,

    pub fn new(commands: []Op) InterprettedRuntime {
        return InterprettedRuntime{ .commands = commands };
    }
};
