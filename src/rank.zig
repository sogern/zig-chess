const std = @import("std");

pub const Rank = enum(u64) {
    @"1" = 0xFF00000000000000,
    @"2" = 0x00FF000000000000,
    @"3" = 0x0000FF0000000000,
    @"4" = 0x000000FF00000000,
    @"5" = 0x00000000FF000000,
    @"6" = 0x0000000000FF0000,
    @"7" = 0x000000000000FF00,
    @"8" = 0x00000000000000FF,
    None = 0x0,

    pub fn fromInt(i: u8) @This() {
        if (i < 1 or i > 8) return .None;
        return @enumFromInt(@intFromEnum(Rank.@"1") >> @intCast((i - 1) * 8));
    }

    pub fn fromIndex(i: usize) @This() {
        if (i > 7) return .None;
        return @enumFromInt(@intFromEnum(Rank.@"1") >> @intCast(i * 8));
    }

    pub inline fn char(self: @This()) u8 {
        if (self == .None) return 0;
        return '1' + (@clz(@intFromEnum(self)) / 8);
    }

    pub inline fn int(self: @This()) u8 {
        if (self == .None) return 0;
        return 1 + (@clz(@intFromEnum(self)) / 8);
    }

    pub inline fn index(self: @This()) usize {
        if (self == .None) return 8;
        return @clz(@intFromEnum(self)) / 8;
    }

    pub inline fn bitmask(self: @This()) u64 {
        return @intFromEnum(self);
    }
};

test "char" {
    try std.testing.expectEqual('1', Rank.@"1".char());
    try std.testing.expectEqual('8', Rank.@"8".char());
    try std.testing.expectEqual(0, Rank.None.char());
}

test "int" {
    try std.testing.expectEqual(1, Rank.@"1".int());
    try std.testing.expectEqual(8, Rank.@"8".int());
    try std.testing.expectEqual(0, Rank.None.int());
}

test "index" {
    try std.testing.expectEqual(0, Rank.@"1".index());
    try std.testing.expectEqual(7, Rank.@"8".index());
    try std.testing.expectEqual(8, Rank.None.index());
}

test "fromInt" {
    try std.testing.expectEqual(Rank.@"1", Rank.fromInt(1));
    try std.testing.expectEqual(Rank.@"8", Rank.fromInt(8));
    try std.testing.expectEqual(Rank.None, Rank.fromInt(0));
    try std.testing.expectEqual(Rank.None, Rank.fromInt(9));
}

test "fromIndex" {
    try std.testing.expectEqual(Rank.@"1", Rank.fromIndex(0));
    try std.testing.expectEqual(Rank.@"8", Rank.fromIndex(7));
    try std.testing.expectEqual(Rank.None, Rank.fromIndex(8));
}