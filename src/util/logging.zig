const std = @import("std");
const SGR = @import("tasai").SGR;

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
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_string = comptime switch (level) {
        .debug => SGR.parseString("<f:magenta><b>[DEBUG]<r><r>"),
        .err => SGR.parseString("<f:red><b>[ERROR]<r><r>"),
        .warn => SGR.parseString("<f:yellow><b>[WARN]<r><r>"),
        .info => SGR.parseString("<f:cyan><b>[INFO]<r><r>"),
    };

    const prefix = comptime switch (scope) {
        .ok => SGR.parseString("<f:green><b>[OK]<r><r>"),
        .fatal => SGR.parseString("<f:red><b>[FATAL]<r><r>"),
        else => level_string,
    };

    const io = comptime if (level == .err or level == .debug) std.io.getStdErr() else std.io.getStdOut();

    io.lock(.none) catch return;
    defer io.unlock();

    const writer = io.writer();
    nosuspend writer.print(prefix ++ " " ++ format ++ "\n", args) catch return;
}
