const std = @import("std");

const ANSI = enum {
    const Green = "\x1b[1;32m";
    const Cyan = "\x1b[1;36m";
    const Yellow = "\x1b[1;33m";
    const Red = "\x1b[1;31m";
    const Purple = "\x1b[1;35m";
    const Reset = "\x1b[0m";
    const BoldUnderline = "\x1b[1;4m";
    const Italic = "\x1b[3m";
    const ItalicReset = "\x1b[23m";
};

const _program_flags = struct {
    debug_mode: bool = false,
};

const flags = _program_flags{ .debug_mode = true };

fn logMessage(comptime level: []const u8, comptime color: []const u8, comptime fmt: []const u8, args: anytype) void {
    var buffer: [256]u8 = undefined;
    const message = std.fmt.bufPrint(&buffer, fmt, args) catch {
        std.debug.print("Error formatting message\n", .{});
        return;
    };
    std.debug.print("{s}[{s}] {s}{s}\n", .{ color, level, ANSI.Reset, message });
}

fn ok(comptime fmt: []const u8, args: anytype) void {
    logMessage("OK", ANSI.Green, fmt, args);
}

fn info(comptime fmt: []const u8, args: anytype) void {
    logMessage("INFO", ANSI.Cyan, fmt, args);
}

fn warn(comptime fmt: []const u8, args: anytype) void {
    logMessage("WARN", ANSI.Yellow, fmt, args);
}

fn err(comptime fmt: []const u8, args: anytype, comptime fatal: bool, comptime status: ?u8) void {
    logMessage("ERROR", ANSI.Red, fmt, args);
    if (fatal) {
        if (status) |code| {
            std.process.exit(code);
        } else {
            std.process.exit(1);
        }
    }
}

fn debug(comptime fmt: []const u8, args: anytype) void {
    if (flags.debug_mode) {
        logMessage("DEBUG", ANSI.Purple, fmt, args);
    }
}

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    ok("This is a success message. {s}", .{"Hello, World!"});
    info("This is a test message.", .{});
    warn("This is a warning message.", .{});
    debug("This is a debug message.", .{});
    err("This is an error message without fatal flag", .{}, false, null);
    err("This is an error message with fatal flag", .{}, true, 130);
}
