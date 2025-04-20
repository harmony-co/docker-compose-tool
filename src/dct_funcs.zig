const std = @import("std");
const prompt = @import("tasai").prompt;
const shell = @import("util/shell.zig");
const fatal = @import("util/logging.zig").fatal;
const ask = @import("util/logging.zig").ask;

const Select = prompt.Select;

pub fn verifyCompose(allocator: std.mem.Allocator, arguments: [][:0]u8, project_name: []const u8) ![]u8 {
    const fs = std.fs;
    const path = "./docker";

    _ = fs.cwd().openDir(path, .{}) catch |err| switch (err) {
        error.NotDir => fatal("No docker directory found, are you sure you're in the right place?", .{}, 126),
        else => return err,
    };
    var compose_configurations = std.ArrayList([]const u8).init(allocator);
    defer compose_configurations.deinit();

    var dir = try fs.cwd().openDir("docker/compose", .{ .iterate = true });
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind == .directory) {
            try compose_configurations.append(entry.name);
        }
    }

    var compose_configuration: ?[]const u8 = null;
    var remaining_arguments = std.ArrayList([]const u8).init(allocator);
    defer remaining_arguments.deinit();

    for (arguments) |arg| {
        var matched = false;
        for (compose_configurations.items) |config| {
            if (std.mem.eql(u8, arg, config)) {
                if (compose_configuration != null) {
                    return fatal("Multiple configurations found, please specify only one", .{}, null);
                }
                compose_configuration = arg;
                matched = true;
                break;
            }
        }
        if (!matched) {
            try remaining_arguments.append(arg);
        }
    }

    if (compose_configuration == null and compose_configurations.items.len == 1) {
        compose_configuration = compose_configurations.items[0];
    }

    if (compose_configuration == null) {
        var selection: Select([]const u8, .{}) = .init(
            "Select a configuration",
            compose_configurations.items,
        );
        const selected = try selection.prompt().run();
        compose_configuration = selected;
    }

    var compose_override: ?[]const u8 = null;
    const override_file_path = try std.fmt.allocPrint(allocator, "./docker/compose/{s}/docker-compose.override.yml", .{compose_configuration.?});
    defer allocator.free(override_file_path);

    if (fs.cwd().openFile(override_file_path, .{})) |file| {
        defer file.close();
        compose_override = try std.fmt.allocPrint(allocator, "--file {s}", .{override_file_path});
    } else |_| {}

    const docker_command = try std.fmt.allocPrintZ(
        allocator,
        "docker compose --file docker/compose/{s}/docker-compose.yml --env-file docker/compose/{s}/.env {s} -p {s}",
        .{
            compose_configuration orelse compose_configurations.items[0],
            compose_configuration orelse compose_configurations.items[0],
            compose_override orelse "",
            project_name,
        },
    );

    return docker_command;
}

pub fn up(allocator: std.mem.Allocator, docker_command: []const u8) !void {
    _ = try shell.exec(&.{ "sh", "-c", try std.fmt.allocPrintZ(allocator, "{s} up -d --force-recreate --remove-orphans", .{docker_command}) });
}

pub fn down(allocator: std.mem.Allocator, docker_command: []const u8) !void {
    _ = try shell.exec(&.{ "sh", "-c", try std.fmt.allocPrintZ(allocator, "{s} down", .{docker_command}) });
}

pub fn rebuild(allocator: std.mem.Allocator, docker_command: []const u8) !void {
    try down(allocator, docker_command);
    _ = try shell.exec(&.{ "sh", "-c", try std.fmt.allocPrintZ(allocator, "{s} pull", .{docker_command}) });
    _ = try shell.exec(&.{ "sh", "-c", try std.fmt.allocPrintZ(allocator, "{s} up -d --force-recreate --remove-orphans --build", .{docker_command}) });
}
