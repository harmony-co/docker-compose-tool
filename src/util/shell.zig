const std = @import("std");
const log = @import("logging.zig");

pub fn getCwd(allocator: std.mem.Allocator) []u8 {
    return std.fs.cwd().realpathAlloc(allocator, ".") catch |e| {
        log.fatal("Failed to get current working directory: {!}", .{e}, null);
        unreachable;
    };
}

pub fn exec(command: []const []const u8) std.process.Child.RunError!std.process.Child.RunResult {
    return std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = command,
    }) catch |e| {
        log.err("Failed to execute command: {!}", .{e});
        return e;
    };
}
