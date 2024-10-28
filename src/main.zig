const std = @import("std");
const log = @import("util/logging.zig");

pub const std_options = .{
    .logFn = log.logMessage,
};

fn ask(comptime question: []const u8, abort_on_refuse: bool) bool {
    if (question.len == 0) {
        @compileError("You need to provide a question to ask");
    }

    const std_out = std.io.getStdOut();
    const reader_interface = std.io.getStdIn().reader();
    var answer_buffer: [4096]u8 = undefined;

    std_out.lock(.none) catch |e| {
        log.fatal("{!}", .{e}, null);
        return false;
    };
    defer std_out.unlock();

    const writer = std_out.writer();

    writer.print("{s}{s}{s}", .{ log.ANSI.BoldYellow, question ++ "\n", log.ANSI.BoldColorReset }) catch |e| {
        log.fatal("{!}", .{e}, null);
        return false;
    };

    writer.print("Continue? [y/N] ", .{}) catch |e| {
        log.fatal("{!}", .{e}, null);
        return false;
    };

    const answer = reader_interface.readUntilDelimiterOrEof(&answer_buffer, '\n') catch |e| {
        log.fatal("{!}", .{e}, null);
        return false;
    };

    if (answer) |response| {
        if (response[0] == 'y') {
            log.ok("Continuing...", .{});
        } else {
            if (abort_on_refuse) {
                log.fatal("Aborting...", .{}, null);
            } else {
                log.warn("Continuing...", .{});
                return true;
            }
        }
    }

    return false;
}

fn getCwd(allocator: std.mem.Allocator) []u8 {
    return std.fs.cwd().realpathAlloc(allocator, ".") catch |e| {
        log.fatal("Failed to get current working directory: {!}", .{e}, null);
        unreachable;
    };
}

fn exec(command: []const []const u8) std.process.Child.RunError!std.process.Child.RunResult {
    return std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = command,
    }) catch |e| {
        log.err("Failed to execute command: {!}", .{e});
        return e;
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    const allocator = arena.allocator();
    log.ok("Current working directory: {s}", .{getCwd(allocator)});

    log.ok("Args: {d}", .{args.len});

    _ = ask("Do you want to continue?", true);

    const out = try exec(args[1..]);
    log.ok("Child process exited with out: {s}", .{out.stdout});

    const args2 = .{ "echo", "Hello, World!" };
    const out2 = try exec(&args2);
    log.ok("Child process exited with out: {s}", .{out2.stdout});

    log.debug("This is a debug message.", .{});
    log.debug("Debug messages should only be displayed when running in {s}'debug mode'{s}", .{
        log.ANSI.BoldUnderline, log.ANSI.ResetBoldUnderline,
    });

    log.ok("This is a success message. {s}", .{"Hello, World!"});
    log.info("This is a test message.", .{});
    log.warn("This is a warning message.", .{});
    log.err("This is an error message without fatal flag", .{});
    log.fatal("This is an error message with fatal flag (130)", .{}, 130);
}
