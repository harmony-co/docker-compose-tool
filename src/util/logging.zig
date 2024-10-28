const std = @import("std");
const colorize = @import("color.zig").colorize;

pub const ok = std.log.scoped(.ok).info;
pub const info = std.log.info;
pub const warn = std.log.warn;
pub const debug = std.log.debug;
pub const err = std.log.err;

pub fn fatal(comptime format: []const u8, args: anytype, comptime exit_code: ?u8) void {
    std.log.scoped(.fatal).err(format, args);
    if (comptime exit_code) |code| {
        std.process.exit(code);
    } else {
        std.process.exit(1);
    }
}

pub fn logMessage(
    comptime level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_string = comptime switch (level) {
        .debug => colorize("[DEBUG]", .Magenta, &.{.Bold}),
        .err => colorize("[ERROR]", .Red, &.{.Bold}),
        .warn => colorize("[WARN]", .Yellow, &.{.Bold}),
        .info => colorize("[INFO]", .Cyan, &.{.Bold}),
    };

    const prefix = comptime switch (scope) {
        .ok => colorize("[OK]", .Green, &.{.Bold}),
        .fatal => colorize("[FATAL]", .Red, &.{.Bold}),
        else => level_string,
    };

    const io = comptime if (level == .err or level == .debug) std.io.getStdErr() else std.io.getStdOut();

    io.lock(.none) catch return;
    defer io.unlock();

    const writer = io.writer();
    nosuspend writer.print(prefix ++ " " ++ format ++ "\n", args) catch return;
}
