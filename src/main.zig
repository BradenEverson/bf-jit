const std = @import("std");
const preprocess = @import("preprocessor.zig");

pub fn exit_err(msg: []const u8) noreturn {
    std.debug.print("{s}\n", .{msg});
    std.process.exit(1);
}

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    var args = std.process.args();
    _ = args.skip();

    const path = args.next() orelse exit_err("Include a file please");

    const file = std.fs.cwd().openFile(path, .{}) catch exit_err("File does not exist >:(");
    defer file.close();

    const buf = file.readToEndAlloc(allocator, 1024) catch exit_err("Did you really try running this on a system with less than 1024 bytes of memory?");
    defer allocator.free(buf);

    var ops = std.ArrayList(preprocess.Op).init(allocator);
    defer ops.deinit();

    preprocess.preproccess(buf, &ops);
}
