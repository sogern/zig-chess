const std = @import("std");

pub const File = enum(u64) {
    A = 0x8080808080808080,
    B = 0x4040404040404040,
    C = 0x2020202020202020,
    D = 0x1010101010101010,
    E = 0x0808080808080808,
    F = 0x0404040404040404,
    G = 0x0202020202020202,
    H = 0x0101010101010101,
    None = 0x0,

    pub fn fromInt(i: u8) @This() {
        if (i < 1 or i > 8) return .None;
        return @enumFromInt(@intFromEnum(File.A) >> @intCast(i - 1));
    }

    pub fn fromIndex(i: usize) @This() {
        if (i > 7) return .None;
        return @enumFromInt(@intFromEnum(File.A) >> @intCast(i));
    }

    pub inline fn char(self: @This()) u8 {
        if (self == .None) return 0;
        return 'a' + @clz(@intFromEnum(self));
    }

    pub inline fn int(self: @This()) u8 {
        if (self == .None) return 0;
        return 1 + @clz(@intFromEnum(self));
    }

    pub inline fn index(self: @This()) usize {
        if (self == .None) return 8;
        return @clz(@intFromEnum(self));
    }

    pub inline fn bitmask(self: @This()) u64 {
        return @intFromEnum(self);
    }
};

test "char" {
    try std.testing.expectEqual('a', File.A.char());
    try std.testing.expectEqual('h', File.H.char());
    try std.testing.expectEqual(0, File.None.char());
}

test "int" {
    try std.testing.expectEqual(1, File.A.int());
    try std.testing.expectEqual(8, File.H.int());
    try std.testing.expectEqual(0, File.None.int());
}

test "index" {
    try std.testing.expectEqual(0, File.A.index());
    try std.testing.expectEqual(7, File.H.index());
    try std.testing.expectEqual(8, File.None.index());
}

test "fromInt" {
    try std.testing.expectEqual(File.A, File.fromInt(1));
    try std.testing.expectEqual(File.H, File.fromInt(8));
    try std.testing.expectEqual(File.None, File.fromInt(0));
    try std.testing.expectEqual(File.None, File.fromInt(9));
}

test "fromIndex" {
    try std.testing.expectEqual(File.A, File.fromIndex(0));
    try std.testing.expectEqual(File.H, File.fromIndex(7));
    try std.testing.expectEqual(File.None, File.fromIndex(8));
}