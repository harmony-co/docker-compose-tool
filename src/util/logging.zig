const std = @import("std");

pub const ANSI = enum {
    pub const BoldGreen = "\x1b[1;32m";
    pub const BoldCyan = "\x1b[1;36m";
    pub const BoldYellow = "\x1b[1;33m";
    pub const BoldRed = "\x1b[1;31m";
    pub const BoldPurple = "\x1b[1;35m";
    pub const BoldColorReset = "\x1b[22;39m";
    pub const BoldUnderline = "\x1b[1;4m";
    pub const ResetBoldUnderline = "\x1b[22;24m";
    pub const Italic = "\x1b[3m";
    pub const ItalicReset = "\x1b[23m";
};

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
    const level_string = switch (level) {
        .debug => ANSI.BoldPurple ++ "[DEBUG]" ++ ANSI.BoldColorReset,
        .err => ANSI.BoldRed ++ "[ERROR]" ++ ANSI.BoldColorReset,
        .warn => ANSI.BoldYellow ++ "[WARN]" ++ ANSI.BoldColorReset,
        .info => ANSI.BoldCyan ++ "[INFO]" ++ ANSI.BoldColorReset,
    };

    const prefix = switch (scope) {
        .ok => ANSI.BoldGreen ++ "[OK]" ++ ANSI.BoldColorReset,
        .fatal => ANSI.BoldRed ++ "[FATAL]" ++ ANSI.BoldColorReset,
        else => level_string,
    };

    const io = comptime if (level == .err or level == .debug) std.io.getStdErr() else std.io.getStdOut();

    io.lock(.none) catch return;
    defer io.unlock();

    const writer = io.writer();
    nosuspend writer.print(prefix ++ " " ++ format ++ "\n", args) catch return;
}
