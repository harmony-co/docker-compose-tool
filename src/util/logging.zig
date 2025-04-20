const std = @import("std");
const SGR = @import("tasai").CSI.SGR;

pub const ok = std.log.scoped(.ok).info;
pub const info = std.log.info;
pub const warn = std.log.warn;
pub const debug = std.log.debug;
pub const err = std.log.err;

pub fn fatal(comptime format: []const u8, args: anytype, comptime exit_code: ?u8) noreturn {
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

pub fn ask(comptime question: []const u8, abort_on_refuse: bool) bool {
    if (question.len == 0) {
        @compileError("You need to provide a question to ask");
    }

    const std_out = std.io.getStdOut();
    const reader_interface = std.io.getStdIn().reader();
    var answer_buffer: [4096]u8 = undefined;

    std_out.lock(.none) catch |e| {
        fatal("{!}", .{e}, null);
        return false;
    };
    defer std_out.unlock();

    const writer = std_out.writer();

    writer.print(SGR.parseString("<f:yellow><b>{s}\n<r><r>"), .{question}) catch |e| {
        fatal("{!}", .{e}, null);
        return false;
    };

    writer.print("Continue? [y/N] ", .{}) catch |e| {
        fatal("{!}", .{e}, null);
        return false;
    };

    const answer = reader_interface.readUntilDelimiterOrEof(&answer_buffer, '\n') catch |e| {
        fatal("{!}", .{e}, null);
        return false;
    };

    if (answer) |response| {
        if (response.len > 0 and response[0] == 'y') {
            ok("Continuing...", .{});
        } else {
            if (abort_on_refuse) {
                fatal("Aborting...", .{}, null);
            } else {
                warn("Continuing...", .{});
                return true;
            }
        }
    }

    return false;
}
