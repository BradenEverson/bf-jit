//! Just In Time Compiled Runtime

const Op = @import("preprocessor.zig").Op;

pub const JitRuntime = struct {
    commands: []Op,

    pub fn new(commands: []Op) JitRuntime {
        return JitRuntime{ .commands = commands };
    }
};
