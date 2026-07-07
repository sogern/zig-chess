const std = @import("std");
const File = @import("file.zig").File;
const Rank = @import("rank.zig").Rank;

pub const Square = enum(u64) {
    A1 = @as(u64, 1) << 63,
    B1 = @as(u64, 1) << 62,
    C1 = @as(u64, 1) << 61,
    D1 = @as(u64, 1) << 60,
    E1 = @as(u64, 1) << 59,
    F1 = @as(u64, 1) << 58,
    G1 = @as(u64, 1) << 57,
    H1 = @as(u64, 1) << 56,
    A2 = @as(u64, 1) << 55,
    B2 = @as(u64, 1) << 54,
    C2 = @as(u64, 1) << 53,
    D2 = @as(u64, 1) << 52,
    E2 = @as(u64, 1) << 51,
    F2 = @as(u64, 1) << 50,
    G2 = @as(u64, 1) << 49,
    H2 = @as(u64, 1) << 48,
    A3 = @as(u64, 1) << 47,
    B3 = @as(u64, 1) << 46,
    C3 = @as(u64, 1) << 45,
    D3 = @as(u64, 1) << 44,
    E3 = @as(u64, 1) << 43,
    F3 = @as(u64, 1) << 42,
    G3 = @as(u64, 1) << 41,
    H3 = @as(u64, 1) << 40,
    A4 = @as(u64, 1) << 39,
    B4 = @as(u64, 1) << 38,
    C4 = @as(u64, 1) << 37,
    D4 = @as(u64, 1) << 36,
    E4 = @as(u64, 1) << 35,
    F4 = @as(u64, 1) << 34,
    G4 = @as(u64, 1) << 33,
    H4 = @as(u64, 1) << 32,
    A5 = @as(u64, 1) << 31,
    B5 = @as(u64, 1) << 30,
    C5 = @as(u64, 1) << 29,
    D5 = @as(u64, 1) << 28,
    E5 = @as(u64, 1) << 27,
    F5 = @as(u64, 1) << 26,
    G5 = @as(u64, 1) << 25,
    H5 = @as(u64, 1) << 24,
    A6 = @as(u64, 1) << 23,
    B6 = @as(u64, 1) << 22,
    C6 = @as(u64, 1) << 21,
    D6 = @as(u64, 1) << 20,
    E6 = @as(u64, 1) << 19,
    F6 = @as(u64, 1) << 18,
    G6 = @as(u64, 1) << 17,
    H6 = @as(u64, 1) << 16,
    A7 = @as(u64, 1) << 15,
    B7 = @as(u64, 1) << 14,
    C7 = @as(u64, 1) << 13,
    D7 = @as(u64, 1) << 12,
    E7 = @as(u64, 1) << 11,
    F7 = @as(u64, 1) << 10,
    G7 = @as(u64, 1) << 9,
    H7 = @as(u64, 1) << 8,
    A8 = @as(u64, 1) << 7,
    B8 = @as(u64, 1) << 6,
    C8 = @as(u64, 1) << 5,
    D8 = @as(u64, 1) << 4,
    E8 = @as(u64, 1) << 3,
    F8 = @as(u64, 1) << 2,
    G8 = @as(u64, 1) << 1,
    H8 = @as(u64, 1) << 0,
    None = 0x0,

    pub fn fromIndex(i: usize) @This() {
        if (i > 63) return .None;
        return @enumFromInt(@as(u64, 1) << @intCast(63 - i));
    }

    test fromIndex {
        try std.testing.expectEqual(Square.A1, Square.fromIndex(0));
        try std.testing.expectEqual(Square.E4, Square.fromIndex(28));
        try std.testing.expectEqual(Square.H8, Square.fromIndex(63));
        try std.testing.expectEqual(Square.None, Square.fromIndex(64));
    }

    pub fn fromFileAndRank(f: File, r: Rank) @This() {
        if (f == .None or r == .None) return .None;
        const i = ((r.int() - 1) * 8) + f.int() - 1;
        return fromIndex(i);
    }

    test fromFileAndRank {
        try std.testing.expectEqual(Square.A1, Square.fromFileAndRank(File.A, Rank.@"1"));
        try std.testing.expectEqual(Square.E4, Square.fromFileAndRank(File.E, Rank.@"4"));
        try std.testing.expectEqual(Square.H8, Square.fromFileAndRank(File.H, Rank.@"8"));
        try std.testing.expectEqual(Square.None, Square.fromFileAndRank(File.None, Rank.@"8"));
    }

    pub fn fromString(s: []const u8) @This() {
        if (s.len != 2) return .None;
        return fromIndex((@as(usize, s[0] - 'a') + (@as(usize, s[1] - '1') * 8)));
    }

    test fromString {
        try std.testing.expectEqual(Square.A1, Square.fromString("a1"));
        try std.testing.expectEqual(Square.E4, Square.fromString("e4"));
        try std.testing.expectEqual(Square.H8, Square.fromString("h8"));
        try std.testing.expectEqual(Square.None, Square.fromString("i9"));
        try std.testing.expectEqual(Square.None, Square.fromString("a"));
        try std.testing.expectEqual(Square.None, Square.fromString(""));
    }

    pub inline fn string(self: @This()) []const u8 {
        if (self == .None) return "";
        return squareStrings[@clz(@intFromEnum(self))];
    }

    pub inline fn bitmask(self: @This()) u64 {
        return @intFromEnum(self);
    }

    pub inline fn rank(self: @This()) Rank {
        if (self == .None) return .None;
        return Rank.fromIndex(@clz(@intFromEnum(self)) / 8);
    }

    test rank {
        try std.testing.expectEqual(Rank.@"1", Square.A1.rank());
        try std.testing.expectEqual(Rank.@"4", Square.E4.rank());
        try std.testing.expectEqual(Rank.@"8", Square.H8.rank());
        try std.testing.expectEqual(Rank.None, Square.None.rank());
    }

    pub inline fn file(self: @This()) File {
        if (self == .None) return .None;
        return File.fromIndex(@clz(@intFromEnum(self)) % 8);
    }

    test file {
        try std.testing.expectEqual(File.A, Square.A1.file());
        try std.testing.expectEqual(File.E, Square.E4.file());
        try std.testing.expectEqual(File.H, Square.H8.file());
        try std.testing.expectEqual(File.None, Square.None.file());
    }

    pub inline fn index(self: @This()) usize {
        return @clz(@intFromEnum(self));
    }

    pub fn order(self: @This(), other: @This()) std.math.Order {
        const selfIndex = self.index();
        const otherIndex = other.index();
        if (selfIndex < otherIndex) return .lt;
        if (selfIndex > otherIndex) return .gt;
        return .eq;
    }

    /// Less than
    pub fn lt(self: @This(), other: @This()) bool {
        return self.order(other) == .lt;
    }

    /// Greater than
    pub fn gt(self: @This(), other: @This()) bool {
        return self.order(other) == .gt;
    }

    /// Less than or equal to
    pub fn lte(self: @This(), other: @This()) bool {
        return self.order(other) != .gt;
    }

    /// Greater than or equal to
    pub fn gte(self: @This(), other: @This()) bool {
        return self.order(other) != .lt;
    }

    test "comparison" {
        try std.testing.expect(Square.A1.lt(Square.B1));
        try std.testing.expect(Square.A1.lt(Square.A2));
        try std.testing.expect(Square.H8.gt(Square.G8));
        try std.testing.expect(Square.H8.gt(Square.H7));
        try std.testing.expect(Square.None.gt(Square.H8));
    }
};

const squareStrings = [_]*const [2]u8{
    "a1", "b1", "c1", "d1", "e1", "f1", "g1", "h1",
    "a2", "b2", "c2", "d2", "e2", "f2", "g2", "h2",
    "a3", "b3", "c3", "d3", "e3", "f3", "g3", "h3",
    "a4", "b4", "c4", "d4", "e4", "f4", "g4", "h4",
    "a5", "b5", "c5", "d5", "e5", "f5", "g5", "h5",
    "a6", "b6", "c6", "d6", "e6", "f6", "g6", "h6",
    "a7", "b7", "c7", "d7", "e7", "f7", "g7", "h7",
    "a8", "b8", "c8", "d8", "e8", "f8", "g8", "h8",
};

test {
    @import("std").testing.refAllDecls(@This());
}