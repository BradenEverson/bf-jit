# bf-jit 🧠💥
## Implementations for a BrainF Interpreter, Assembler, Compiler and Just In Time Compiler

## Current Features:
- [x] Interpreter
- [x] Assembler
- [x] ELF64 Compiler
- [x] JIT Compiler

To swap between the 4 different modes of operation, a consistent API is kept between them all so that swapping is as simple as commenting out an include:

```zig
//! BF Compiler/Interpreter/Jit Main Entry Point
//! loads a buffer from a file (maybe REPL in the future)
//! and dispatches it to the chosen runtime

const std = @import("std");
const preprocess = @import("preprocessor.zig");
// const Runtime = @import("interpreter.zig").InterprettedRuntime;
// const Runtime = @import("assembler.zig").AssembledRuntime;
// const Runtime = @import("compiler.zig").CompiledRuntime;
const Runtime = @import("jit.zig").JitRuntime;
```

Inspired by: https://github.com/tsoding/bfjit
