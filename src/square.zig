const std = @import("std");

pub const numSquaresOnBoard = 64;
pub const numSquaresInRow = 8;

pub const Square = struct {
    /// Rank in the range 0-7, or NoRank if invalid
    r: i8,
    /// File in the range 0-7, or NoFile if invalid
    f: i8,
    /// Square bitboard index 0-63, or NoSquare if invalid
    s: i8,

    pub fn fromFileAndRank(file: i8, rank: i8) Square {
        if (file < 0 or file > 7 or rank < 0 or rank > 7) return .{ .s = NoSquare, .f = NoFile, .r = NoRank };
        const out = 63 - ((file * numSquaresInRow) + rank);
        return .{ .s = @intCast(out), .r = rank, .f = file };
    }

    pub fn fromString(s: []const u8) Square {
        if (s.len != 2 or s[0] < 'a' or s[1] < '1') return .{ .s = NoSquare, .f = NoFile, .r = NoRank };
        const file = s[0] - 'a';
        const rank = s[1] - '1';
        if (file > 7 or rank > 7) return .{ .s = NoSquare, .f = NoFile, .r = NoRank };
        const out = 63 - ((file * numSquaresInRow) + rank);
        return .{ .s = @intCast(out), .r = @intCast(rank), .f = @intCast(file) };
    }

    pub fn toString(self: Square) []const u8 {
        if (self.s == NoSquare) return "";
        return squareStrings[63 - @as(usize, @intCast(self.s))];
    }

    pub const A1 = 63;
    pub const A2 = 62;
    pub const A3 = 61;
    pub const A4 = 60;
    pub const A5 = 59;
    pub const A6 = 58;
    pub const A7 = 57;
    pub const A8 = 56;
    pub const B1 = 55;
    pub const B2 = 54;
    pub const B3 = 53;
    pub const B4 = 52;
    pub const B5 = 51;
    pub const B6 = 50;
    pub const B7 = 49;
    pub const B8 = 48;
    pub const C1 = 47;
    pub const C2 = 46;
    pub const C3 = 45;
    pub const C4 = 44;
    pub const C5 = 43;
    pub const C6 = 42;
    pub const C7 = 41;
    pub const C8 = 40;
    pub const D1 = 39;
    pub const D2 = 38;
    pub const D3 = 37;
    pub const D4 = 36;
    pub const D5 = 35;
    pub const D6 = 34;
    pub const D7 = 33;
    pub const D8 = 32;
    pub const E1 = 31;
    pub const E2 = 30;
    pub const E3 = 29;
    pub const E4 = 28;
    pub const E5 = 27;
    pub const E6 = 26;
    pub const E7 = 25;
    pub const E8 = 24;
    pub const F1 = 23;
    pub const F2 = 22;
    pub const F3 = 21;
    pub const F4 = 20;
    pub const F5 = 19;
    pub const F6 = 18;
    pub const F7 = 17;
    pub const F8 = 16;
    pub const G1 = 15;
    pub const G2 = 14;
    pub const G3 = 13;
    pub const G4 = 12;
    pub const G5 = 11;
    pub const G6 = 10;
    pub const G7 = 9;
    pub const G8 = 8;
    pub const H1 = 7;
    pub const H2 = 6;
    pub const H3 = 5;
    pub const H4 = 4;
    pub const H5 = 3;
    pub const H6 = 2;
    pub const H7 = 1;
    pub const H8 = 0;
    pub const NoSquare: i8 = -1;

    pub const FileA = 0;
    pub const FileB = 1;
    pub const FileC = 2;
    pub const FileD = 3;
    pub const FileE = 4;
    pub const FileF = 5;
    pub const FileG = 6;
    pub const FileH = 7;
    pub const NoFile: i8 = -1;

    pub const Rank1 = 0;
    pub const Rank2 = 1;
    pub const Rank3 = 2;
    pub const Rank4 = 3;
    pub const Rank5 = 4;
    pub const Rank6 = 5;
    pub const Rank7 = 6;
    pub const Rank8 = 7;
    pub const NoRank: i8 = -1;
};

const squareStrings = [_]*const [2]u8{
    "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8",
    "b1", "b2", "b3", "b4", "b5", "b6", "b7", "b8",
    "c1", "c2", "c3", "c4", "c5", "c6", "c7", "c8",
    "d1", "d2", "d3", "d4", "d5", "d6", "d7", "d8",
    "e1", "e2", "e3", "e4", "e5", "e6", "e7", "e8",
    "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8",
    "g1", "g2", "g3", "g4", "g5", "g6", "g7", "g8",
    "h1", "h2", "h3", "h4", "h5", "h6", "h7", "h8",
};

test "Square fromString and toString" {
    const testCase = struct {
        s: i8,
        str: []const u8,
        exp: []const u8,
    };
    const testCases: []const testCase = &[_]testCase{
        .{ .s = Square.A1, .str = "a1", .exp = "a1" },
        .{ .s = Square.A2, .str = "a2", .exp = "a2" },
        .{ .s = Square.A3, .str = "a3", .exp = "a3" },
        .{ .s = Square.A4, .str = "a4", .exp = "a4" },
        .{ .s = Square.A5, .str = "a5", .exp = "a5" },
        .{ .s = Square.A6, .str = "a6", .exp = "a6" },
        .{ .s = Square.A7, .str = "a7", .exp = "a7" },
        .{ .s = Square.A8, .str = "a8", .exp = "a8" },
        .{ .s = Square.B1, .str = "b1", .exp = "b1" },
        .{ .s = Square.B2, .str = "b2", .exp = "b2" },
        .{ .s = Square.B3, .str = "b3", .exp = "b3" },
        .{ .s = Square.B4, .str = "b4", .exp = "b4" },
        .{ .s = Square.B5, .str = "b5", .exp = "b5" },
        .{ .s = Square.B6, .str = "b6", .exp = "b6" },
        .{ .s = Square.B7, .str = "b7", .exp = "b7" },
        .{ .s = Square.B8, .str = "b8", .exp = "b8" },
        .{ .s = Square.C1, .str = "c1", .exp = "c1" },
        .{ .s = Square.C2, .str = "c2", .exp = "c2" },
        .{ .s = Square.C3, .str = "c3", .exp = "c3" },
        .{ .s = Square.C4, .str = "c4", .exp = "c4" },
        .{ .s = Square.C5, .str = "c5", .exp = "c5" },
        .{ .s = Square.C6, .str = "c6", .exp = "c6" },
        .{ .s = Square.C7, .str = "c7", .exp = "c7" },
        .{ .s = Square.C8, .str = "c8", .exp = "c8" },
        .{ .s = Square.D1, .str = "d1", .exp = "d1" },
        .{ .s = Square.D2, .str = "d2", .exp = "d2" },
        .{ .s = Square.D3, .str = "d3", .exp = "d3" },
        .{ .s = Square.D4, .str = "d4", .exp = "d4" },
        .{ .s = Square.D5, .str = "d5", .exp = "d5" },
        .{ .s = Square.D6, .str = "d6", .exp = "d6" },
        .{ .s = Square.D7, .str = "d7", .exp = "d7" },
        .{ .s = Square.D8, .str = "d8", .exp = "d8" },
        .{ .s = Square.E1, .str = "e1", .exp = "e1" },
        .{ .s = Square.E2, .str = "e2", .exp = "e2" },
        .{ .s = Square.E3, .str = "e3", .exp = "e3" },
        .{ .s = Square.E4, .str = "e4", .exp = "e4" },
        .{ .s = Square.E5, .str = "e5", .exp = "e5" },
        .{ .s = Square.E6, .str = "e6", .exp = "e6" },
        .{ .s = Square.E7, .str = "e7", .exp = "e7" },
        .{ .s = Square.E8, .str = "e8", .exp = "e8" },
        .{ .s = Square.F1, .str = "f1", .exp = "f1" },
        .{ .s = Square.F2, .str = "f2", .exp = "f2" },
        .{ .s = Square.F3, .str = "f3", .exp = "f3" },
        .{ .s = Square.F4, .str = "f4", .exp = "f4" },
        .{ .s = Square.F5, .str = "f5", .exp = "f5" },
        .{ .s = Square.F6, .str = "f6", .exp = "f6" },
        .{ .s = Square.F7, .str = "f7", .exp = "f7" },
        .{ .s = Square.F8, .str = "f8", .exp = "f8" },
        .{ .s = Square.G1, .str = "g1", .exp = "g1" },
        .{ .s = Square.G2, .str = "g2", .exp = "g2" },
        .{ .s = Square.G3, .str = "g3", .exp = "g3" },
        .{ .s = Square.G4, .str = "g4", .exp = "g4" },
        .{ .s = Square.G5, .str = "g5", .exp = "g5" },
        .{ .s = Square.G6, .str = "g6", .exp = "g6" },
        .{ .s = Square.G7, .str = "g7", .exp = "g7" },
        .{ .s = Square.G8, .str = "g8", .exp = "g8" },
        .{ .s = Square.H1, .str = "h1", .exp = "h1" },
        .{ .s = Square.H2, .str = "h2", .exp = "h2" },
        .{ .s = Square.H3, .str = "h3", .exp = "h3" },
        .{ .s = Square.H4, .str = "h4", .exp = "h4" },
        .{ .s = Square.H5, .str = "h5", .exp = "h5" },
        .{ .s = Square.H6, .str = "h6", .exp = "h6" },
        .{ .s = Square.H7, .str = "h7", .exp = "h7" },
        .{ .s = Square.H8, .str = "h8", .exp = "h8" },
        .{ .s = Square.NoSquare, .str = "z0", .exp = "" },
        .{ .s = Square.NoSquare, .str = "a9", .exp = "" },
        .{ .s = Square.NoSquare, .str = "i1", .exp = "" },
        .{ .s = Square.NoSquare, .str = "", .exp = "" },
        .{ .s = Square.NoSquare, .str = "invalid", .exp = "" },
    };

    for (testCases) |tc| {
        const s = Square.fromString(tc.str);
        try std.testing.expectEqual(tc.s, s.s);
        const str = s.toString();
        try std.testing.expectEqualStrings(tc.exp, str);
    }
}

test "Square fromFileAndRank" {
    const testCase = struct {
        f: i8,
        r: i8,
        exp: i8,
    };
    const testCases: []const testCase = &[_]testCase{
        .{ .f = Square.FileA, .r = Square.Rank1, .exp = Square.A1 },
        .{ .f = Square.FileB, .r = Square.Rank2, .exp = Square.B2 },
        .{ .f = Square.FileC, .r = Square.Rank3, .exp = Square.C3 },
        .{ .f = Square.FileD, .r = Square.Rank4, .exp = Square.D4 },
        .{ .f = Square.FileE, .r = Square.Rank5, .exp = Square.E5 },
        .{ .f = Square.FileF, .r = Square.Rank6, .exp = Square.F6 },
        .{ .f = Square.FileG, .r = Square.Rank7, .exp = Square.G7 },
        .{ .f = Square.FileH, .r = Square.Rank8, .exp = Square.H8 },
        // Invalid cases
        .{ .f = Square.NoFile, .r = Square.NoRank, .exp = Square.NoSquare },
        .{ .f = 8, .r = 0, .exp = Square.NoSquare },
        .{ .f = 0, .r = 8, .exp = Square.NoSquare },
    };

    for (testCases) |tc| {
        const s = Square.fromFileAndRank(tc.f, tc.r);
        try std.testing.expectEqual(tc.exp, s.s);
    }
}