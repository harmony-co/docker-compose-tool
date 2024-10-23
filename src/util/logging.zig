const std = @import("std");

pub const ANSI = enum {
    pub const Green = "\x1b[1;32m";
    pub const Cyan = "\x1b[1;36m";
    pub const Yellow = "\x1b[1;33m";
    pub const Red = "\x1b[1;31m";
    pub const Purple = "\x1b[1;35m";
    pub const Reset = "\x1b[0m";
    pub const BoldUnderline = "\x1b[1;4m";
    pub const Italic = "\x1b[3m";
    pub const ItalicReset = "\x1b[23m";
};

pub fn logMessage(comptime level: []const u8, comptime color: []const u8, comptime fmt: []const u8, args: anytype) void {
    var buffer: [256]u8 = undefined;
    const message = std.fmt.bufPrint(&buffer, fmt, args) catch |e| {
        switch (e) {
            std.fmt.BufPrintError.NoSpaceLeft => err("Buffer too small", .{}, true, 1),
        }
        return;
    };
    std.debug.print("{s}[{s}] {s}{s}\n", .{ color, level, ANSI.Reset, message });
}

pub fn ok(comptime fmt: []const u8, args: anytype) void {
    logMessage("OK", ANSI.Green, fmt, args);
}

pub fn info(comptime fmt: []const u8, args: anytype) void {
    logMessage("INFO", ANSI.Cyan, fmt, args);
}

pub fn warn(comptime fmt: []const u8, args: anytype) void {
    logMessage("WARN", ANSI.Yellow, fmt, args);
}

pub fn debug(comptime fmt: []const u8, args: anytype) void {
    logMessage("DEBUG", ANSI.Purple, fmt, args);
}

pub fn err(comptime fmt: []const u8, args: anytype, comptime fatal: bool, comptime status: ?u8) void {
    logMessage("ERROR", ANSI.Red, fmt, args);
    if (fatal) {
        if (status) |code| {
            std.process.exit(code);
        } else {
            std.process.exit(1);
        }
    }
}
