const std = @import("std");
const shell = @import("util/shell.zig");
const SGR = @import("tasai").CSI.SGR;
const log = @import("util/logging.zig");
const dct = @import("dct_funcs.zig");

pub const std_options = std.Options{
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

    writer.print(SGR.parseString("<f:yellow><b>{s}\n<r><r>"), .{question}) catch |e| {
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
        if (response.len > 0 and response[0] == 'y') {
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

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    const allocator = arena.allocator();
    log.ok("Current working directory: {s}", .{shell.getCwd(allocator)});

    const command = try dct.verifyCompose(allocator, try std.process.argsAlloc(allocator), "test");
    log.debug("{s}", .{command});

    log.ok("Args: {d}", .{args.len});

    _ = ask("Do you want to continue?", true);

    const out = try shell.exec(args[1..]);
    log.ok("Child process exited with out: {s}", .{out.stdout});

    const args2 = .{ "echo", "Hello, World!" };
    const out2 = try shell.exec(&args2);
    log.ok("Child process exited with out: {s}", .{out2.stdout});

    log.debug("This is a debug message.", .{});
    log.debug(SGR.parseString("Debug messages should only be displayed when running in <u><b>{s}<r><r>"), .{"'debug mode'"});

    log.ok("This is a success message. {s}", .{"Hello, World!"});
    log.info("This is a test message.", .{});
    log.warn("This is a warning message.", .{});
    log.err("This is an error message without fatal flag", .{});
    log.fatal("This is an error message with fatal flag (130)", .{}, 130);
}
