const std = @import("std");
const log = @import("util/logging.zig");

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

const _program_flags = struct {
    debug_mode: bool = false,
};

const flags = _program_flags{ .debug_mode = true };

fn getCwd() []u8 {
    return std.fs.cwd().realpathAlloc(arena.allocator(), ".") catch |e| {
        log.err("Failed to get current working directory: {!}", .{e}, true, 1);
        unreachable;
    };
}

fn exec(command: []const []const u8) std.process.Child.RunError!std.process.Child.RunResult {
    return std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = command,
    }) catch |e| {
        log.err("Failed to execute command: {!}", .{e}, false, null);
        return e;
    };
}

pub fn main() !void {
    defer arena.deinit();
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    log.ok("Current working directory: {s}", .{getCwd()});

    log.ok("Args: {d}", .{args.len});

    const out = try exec(args[1..]);
    log.ok("Child process exited with out: {s}", .{out.stdout});

    const args2 = .{ "echo", "Hello, World!" };
    const out2 = try exec(&args2);
    log.ok("Child process exited with out: {s}", .{out2.stdout});

    if (flags.debug_mode) {
        log.debug("This is a debug message.", .{});
        log.debug("Debug messages should only be displayed when the {s}`flags.debug_mode`{s} is true", .{
            log.ANSI.BoldUnderline, log.ANSI.Reset,
        });
    }

    log.ok("This is a success message. {s}", .{"Hello, World!"});
    log.info("This is a test message.", .{});
    log.warn("This is a warning message.", .{});
    log.err("This is an error message without fatal flag", .{}, false, null);
    log.err("This is an error message with fatal flag (130)", .{}, true, 130);
}
