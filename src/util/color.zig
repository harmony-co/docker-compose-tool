const std = @import("std");

const SRGCode = struct { open: []const u8, close: []const u8 };

const SGRModifierMap = struct {
    const Bold: SRGCode = .{ .open = "1", .close = "22" };
    const Italic: SRGCode = .{ .open = "3", .close = "23" };
    const Underline: SRGCode = .{ .open = "4", .close = "24" };
};

const SGRModifier = enum {
    Bold,
    Italic,
    Underline,

    fn map(self: SGRModifier) SRGCode {
        return switch (self) {
            inline else => |tag| {
                const tagName = comptime std.enums.tagName(SGRModifier, tag) orelse unreachable;
                return @field(SGRModifierMap, tagName);
            },
        };
    }
};

const SGRColorCode = enum(u8) {
    None,
    Red = 31,
    Green,
    Yellow,
    Blue,
    Magenta,
    Cyan,
    White,
};

pub fn colorize(
    comptime text: []const u8,
    comptime color: SGRColorCode,
    comptime modifiers: []const SGRModifier,
) []const u8 {
    comptime var open: []const u8 = &.{};
    comptime var close: []const u8 = &.{};

    inline for (modifiers) |modifier| {
        const mod = comptime modifier.map();

        open = open ++ mod.open ++ @as([]const u8, &.{';'});
        close = close ++ mod.close ++ @as([]const u8, &.{';'});
    }

    if (comptime color != .None) {
        open = open ++ std.fmt.comptimePrint("{d}", .{@intFromEnum(color)}) ++ @as([]const u8, &.{'m'});
        close = close ++ "39m";
    } else {
        open = open[0 .. open.len - 1] ++ @as([]const u8, &.{'m'});
        close = close[0 .. close.len - 1] ++ @as([]const u8, &.{'m'});
    }

    return "\x1B[" ++ open ++ text ++ "\x1B[" ++ close;
}
