const std = @import("std");

pub const numSquaresOnBoard = 64;
pub const numSquaresInRow = 8;

pub const Square = struct {
    /// Rank in the range 0-7, or NoRank if invalid
    r: i8 = NoRank,
    /// File in the range 0-7, or NoFile if invalid
    f: i8 = NoFile,
    /// Square bitboard index 0-63, or NoSquare if invalid
    s: i8 = NoSquare,

    pub inline fn squareBit(index: usize) u64 {
        return squareBits[index];
    }

    pub fn fromIndex(index: i8) Square {
        if (index < 0 or index >= numSquaresOnBoard) return .{};
        const rank = @divTrunc(index, numSquaresInRow);
        const file = @mod(index, numSquaresInRow);
        return .{ .s = index, .r = @intCast(rank), .f = @intCast(file) };
    }

    pub fn fromFileAndRank(file: i8, rank: i8) Square {
        if (file < 0 or file > 7 or rank < 0 or rank > 7) return .{};
        const out = (rank * numSquaresInRow) + file;
        return .{ .s = @intCast(out), .r = rank, .f = file };
    }

    pub fn fromString(s: []const u8) Square {
        if (s.len != 2 or s[0] < 'a' or s[1] < '1') return .{};
        const file = s[0] - 'a';
        const rank = s[1] - '1';
        if (file > 7 or rank > 7) return .{};
        const out = (rank * numSquaresInRow) + file;
        return .{ .s = @intCast(out), .r = @intCast(rank), .f = @intCast(file) };
    }

    pub fn getBitboard(self: Square) u64 {
        if (self.s == NoSquare) return 0;
        return squareBits[@as(usize, @intCast(self.s))];
    }

    pub fn toString(self: Square) []const u8 {
        if (self.s == NoSquare) return "";
        return squareStrings[@as(usize, @intCast(self.s))];
    }

    pub fn equals(self: Square, other: Square) bool {
        return self.s == other.s and self.f == other.f and self.r == other.r;
    }

    pub const NoSquare: i8 = -1;
    pub const A1 = 0;
    pub const B1 = 1;
    pub const C1 = 2;
    pub const D1 = 3;
    pub const E1 = 4;
    pub const F1 = 5;
    pub const G1 = 6;
    pub const H1 = 7;
    pub const A2 = 8;
    pub const B2 = 9;
    pub const C2 = 10;
    pub const D2 = 11;
    pub const E2 = 12;
    pub const F2 = 13;
    pub const G2 = 14;
    pub const H2 = 15;
    pub const A3 = 16;
    pub const B3 = 17;
    pub const C3 = 18;
    pub const D3 = 19;
    pub const E3 = 20;
    pub const F3 = 21;
    pub const G3 = 22;
    pub const H3 = 23;
    pub const A4 = 24;
    pub const B4 = 25;
    pub const C4 = 26;
    pub const D4 = 27;
    pub const E4 = 28;
    pub const F4 = 29;
    pub const G4 = 30;
    pub const H4 = 31;
    pub const A5 = 32;
    pub const B5 = 33;
    pub const C5 = 34;
    pub const D5 = 35;
    pub const E5 = 36;
    pub const F5 = 37;
    pub const G5 = 38;
    pub const H5 = 39;
    pub const A6 = 40;
    pub const B6 = 41;
    pub const C6 = 42;
    pub const D6 = 43;
    pub const E6 = 44;
    pub const F6 = 45;
    pub const G6 = 46;
    pub const H6 = 47;
    pub const A7 = 48;
    pub const B7 = 49;
    pub const C7 = 50;
    pub const D7 = 51;
    pub const E7 = 52;
    pub const F7 = 53;
    pub const G7 = 54;
    pub const H7 = 55;
    pub const A8 = 56;
    pub const B8 = 57;
    pub const C8 = 58;
    pub const D8 = 59;
    pub const E8 = 60;
    pub const F8 = 61;
    pub const G8 = 62;
    pub const H8 = 63;

    const squareBits = [_]u64{
        @as(u64, 1) << (63 - A1),
        @as(u64, 1) << (63 - B1),
        @as(u64, 1) << (63 - C1),
        @as(u64, 1) << (63 - D1),
        @as(u64, 1) << (63 - E1),
        @as(u64, 1) << (63 - F1),
        @as(u64, 1) << (63 - G1),
        @as(u64, 1) << (63 - H1),
        @as(u64, 1) << (63 - A2),
        @as(u64, 1) << (63 - B2),
        @as(u64, 1) << (63 - C2),
        @as(u64, 1) << (63 - D2),
        @as(u64, 1) << (63 - E2),
        @as(u64, 1) << (63 - F2),
        @as(u64, 1) << (63 - G2),
        @as(u64, 1) << (63 - H2),
        @as(u64, 1) << (63 - A3),
        @as(u64, 1) << (63 - B3),
        @as(u64, 1) << (63 - C3),
        @as(u64, 1) << (63 - D3),
        @as(u64, 1) << (63 - E3),
        @as(u64, 1) << (63 - F3),
        @as(u64, 1) << (63 - G3),
        @as(u64, 1) << (63 - H3),
        @as(u64, 1) << (63 - A4),
        @as(u64, 1) << (63 - B4),
        @as(u64, 1) << (63 - C4),
        @as(u64, 1) << (63 - D4),
        @as(u64, 1) << (63 - E4),
        @as(u64, 1) << (63 - F4),
        @as(u64, 1) << (63 - G4),
        @as(u64, 1) << (63 - H4),
        @as(u64, 1) << (63 - A5),
        @as(u64, 1) << (63 - B5),
        @as(u64, 1) << (63 - C5),
        @as(u64, 1) << (63 - D5),
        @as(u64, 1) << (63 - E5),
        @as(u64, 1) << (63 - F5),
        @as(u64, 1) << (63 - G5),
        @as(u64, 1) << (63 - H5),
        @as(u64, 1) << (63 - A6),
        @as(u64, 1) << (63 - B6),
        @as(u64, 1) << (63 - C6),
        @as(u64, 1) << (63 - D6),
        @as(u64, 1) << (63 - E6),
        @as(u64, 1) << (63 - F6),
        @as(u64, 1) << (63 - G6),
        @as(u64, 1) << (63 - H6),
        @as(u64, 1) << (63 - A7),
        @as(u64, 1) << (63 - B7),
        @as(u64, 1) << (63 - C7),
        @as(u64, 1) << (63 - D7),
        @as(u64, 1) << (63 - E7),
        @as(u64, 1) << (63 - F7),
        @as(u64, 1) << (63 - G7),
        @as(u64, 1) << (63 - H7),
        @as(u64, 1) << (63 - A8),
        @as(u64, 1) << (63 - B8),
        @as(u64, 1) << (63 - C8),
        @as(u64, 1) << (63 - D8),
        @as(u64, 1) << (63 - E8),
        @as(u64, 1) << (63 - F8),
        @as(u64, 1) << (63 - G8),
        @as(u64, 1) << (63 - H8),
    };

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

    pub const None: Square = .{ .s = NoSquare, .f = NoFile, .r = NoRank };
    pub const SqA1: Square = .{ .s = A1, .f = FileA, .r = Rank1 };
    pub const SqA2: Square = .{ .s = A2, .f = FileA, .r = Rank2 };
    pub const SqA3: Square = .{ .s = A3, .f = FileA, .r = Rank3 };
    pub const SqA4: Square = .{ .s = A4, .f = FileA, .r = Rank4 };
    pub const SqA5: Square = .{ .s = A5, .f = FileA, .r = Rank5 };
    pub const SqA6: Square = .{ .s = A6, .f = FileA, .r = Rank6 };
    pub const SqA7: Square = .{ .s = A7, .f = FileA, .r = Rank7 };
    pub const SqA8: Square = .{ .s = A8, .f = FileA, .r = Rank8 };
    pub const SqB1: Square = .{ .s = B1, .f = FileB, .r = Rank1 };
    pub const SqB2: Square = .{ .s = B2, .f = FileB, .r = Rank2 };
    pub const SqB3: Square = .{ .s = B3, .f = FileB, .r = Rank3 };
    pub const SqB4: Square = .{ .s = B4, .f = FileB, .r = Rank4 };
    pub const SqB5: Square = .{ .s = B5, .f = FileB, .r = Rank5 };
    pub const SqB6: Square = .{ .s = B6, .f = FileB, .r = Rank6 };
    pub const SqB7: Square = .{ .s = B7, .f = FileB, .r = Rank7 };
    pub const SqB8: Square = .{ .s = B8, .f = FileB, .r = Rank8 };
    pub const SqC1: Square = .{ .s = C1, .f = FileC, .r = Rank1 };
    pub const SqC2: Square = .{ .s = C2, .f = FileC, .r = Rank2 };
    pub const SqC3: Square = .{ .s = C3, .f = FileC, .r = Rank3 };
    pub const SqC4: Square = .{ .s = C4, .f = FileC, .r = Rank4 };
    pub const SqC5: Square = .{ .s = C5, .f = FileC, .r = Rank5 };
    pub const SqC6: Square = .{ .s = C6, .f = FileC, .r = Rank6 };
    pub const SqC7: Square = .{ .s = C7, .f = FileC, .r = Rank7 };
    pub const SqC8: Square = .{ .s = C8, .f = FileC, .r = Rank8 };
    pub const SqD1: Square = .{ .s = D1, .f = FileD, .r = Rank1 };
    pub const SqD2: Square = .{ .s = D2, .f = FileD, .r = Rank2 };
    pub const SqD3: Square = .{ .s = D3, .f = FileD, .r = Rank3 };
    pub const SqD4: Square = .{ .s = D4, .f = FileD, .r = Rank4 };
    pub const SqD5: Square = .{ .s = D5, .f = FileD, .r = Rank5 };
    pub const SqD6: Square = .{ .s = D6, .f = FileD, .r = Rank6 };
    pub const SqD7: Square = .{ .s = D7, .f = FileD, .r = Rank7 };
    pub const SqD8: Square = .{ .s = D8, .f = FileD, .r = Rank8 };
    pub const SqE1: Square = .{ .s = E1, .f = FileE, .r = Rank1 };
    pub const SqE2: Square = .{ .s = E2, .f = FileE, .r = Rank2 };
    pub const SqE3: Square = .{ .s = E3, .f = FileE, .r = Rank3 };
    pub const SqE4: Square = .{ .s = E4, .f = FileE, .r = Rank4 };
    pub const SqE5: Square = .{ .s = E5, .f = FileE, .r = Rank5 };
    pub const SqE6: Square = .{ .s = E6, .f = FileE, .r = Rank6 };
    pub const SqE7: Square = .{ .s = E7, .f = FileE, .r = Rank7 };
    pub const SqE8: Square = .{ .s = E8, .f = FileE, .r = Rank8 };
    pub const SqF1: Square = .{ .s = F1, .f = FileF, .r = Rank1 };
    pub const SqF2: Square = .{ .s = F2, .f = FileF, .r = Rank2 };
    pub const SqF3: Square = .{ .s = F3, .f = FileF, .r = Rank3 };
    pub const SqF4: Square = .{ .s = F4, .f = FileF, .r = Rank4 };
    pub const SqF5: Square = .{ .s = F5, .f = FileF, .r = Rank5 };
    pub const SqF6: Square = .{ .s = F6, .f = FileF, .r = Rank6 };
    pub const SqF7: Square = .{ .s = F7, .f = FileF, .r = Rank7 };
    pub const SqF8: Square = .{ .s = F8, .f = FileF, .r = Rank8 };
    pub const SqG1: Square = .{ .s = G1, .f = FileG, .r = Rank1 };
    pub const SqG2: Square = .{ .s = G2, .f = FileG, .r = Rank2 };
    pub const SqG3: Square = .{ .s = G3, .f = FileG, .r = Rank3 };
    pub const SqG4: Square = .{ .s = G4, .f = FileG, .r = Rank4 };
    pub const SqG5: Square = .{ .s = G5, .f = FileG, .r = Rank5 };
    pub const SqG6: Square = .{ .s = G6, .f = FileG, .r = Rank6 };
    pub const SqG7: Square = .{ .s = G7, .f = FileG, .r = Rank7 };
    pub const SqG8: Square = .{ .s = G8, .f = FileG, .r = Rank8 };
    pub const SqH1: Square = .{ .s = H1, .f = FileH, .r = Rank1 };
    pub const SqH2: Square = .{ .s = H2, .f = FileH, .r = Rank2 };
    pub const SqH3: Square = .{ .s = H3, .f = FileH, .r = Rank3 };
    pub const SqH4: Square = .{ .s = H4, .f = FileH, .r = Rank4 };
    pub const SqH5: Square = .{ .s = H5, .f = FileH, .r = Rank5 };
    pub const SqH6: Square = .{ .s = H6, .f = FileH, .r = Rank6 };
    pub const SqH7: Square = .{ .s = H7, .f = FileH, .r = Rank7 };
    pub const SqH8: Square = .{ .s = H8, .f = FileH, .r = Rank8 };
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
        .{ .f = Square.FileA, .r = Square.Rank2, .exp = Square.A2 },
        .{ .f = Square.FileA, .r = Square.Rank3, .exp = Square.A3 },
        .{ .f = Square.FileA, .r = Square.Rank4, .exp = Square.A4 },
        .{ .f = Square.FileA, .r = Square.Rank5, .exp = Square.A5 },
        .{ .f = Square.FileA, .r = Square.Rank6, .exp = Square.A6 },
        .{ .f = Square.FileA, .r = Square.Rank7, .exp = Square.A7 },
        .{ .f = Square.FileA, .r = Square.Rank8, .exp = Square.A8 },
        .{ .f = Square.FileB, .r = Square.Rank1, .exp = Square.B1 },
        .{ .f = Square.FileB, .r = Square.Rank2, .exp = Square.B2 },
        .{ .f = Square.FileB, .r = Square.Rank3, .exp = Square.B3 },
        .{ .f = Square.FileB, .r = Square.Rank4, .exp = Square.B4 },
        .{ .f = Square.FileB, .r = Square.Rank5, .exp = Square.B5 },
        .{ .f = Square.FileB, .r = Square.Rank6, .exp = Square.B6 },
        .{ .f = Square.FileB, .r = Square.Rank7, .exp = Square.B7 },
        .{ .f = Square.FileB, .r = Square.Rank8, .exp = Square.B8 },
        .{ .f = Square.FileC, .r = Square.Rank1, .exp = Square.C1 },
        .{ .f = Square.FileC, .r = Square.Rank2, .exp = Square.C2 },
        .{ .f = Square.FileC, .r = Square.Rank3, .exp = Square.C3 },
        .{ .f = Square.FileC, .r = Square.Rank4, .exp = Square.C4 },
        .{ .f = Square.FileC, .r = Square.Rank5, .exp = Square.C5 },
        .{ .f = Square.FileC, .r = Square.Rank6, .exp = Square.C6 },
        .{ .f = Square.FileC, .r = Square.Rank7, .exp = Square.C7 },
        .{ .f = Square.FileC, .r = Square.Rank8, .exp = Square.C8 },
        .{ .f = Square.FileD, .r = Square.Rank1, .exp = Square.D1 },
        .{ .f = Square.FileD, .r = Square.Rank2, .exp = Square.D2 },
        .{ .f = Square.FileD, .r = Square.Rank3, .exp = Square.D3 },
        .{ .f = Square.FileD, .r = Square.Rank4, .exp = Square.D4 },
        .{ .f = Square.FileD, .r = Square.Rank5, .exp = Square.D5 },
        .{ .f = Square.FileD, .r = Square.Rank6, .exp = Square.D6 },
        .{ .f = Square.FileD, .r = Square.Rank7, .exp = Square.D7 },
        .{ .f = Square.FileD, .r = Square.Rank8, .exp = Square.D8 },
        .{ .f = Square.FileE, .r = Square.Rank1, .exp = Square.E1 },
        .{ .f = Square.FileE, .r = Square.Rank2, .exp = Square.E2 },
        .{ .f = Square.FileE, .r = Square.Rank3, .exp = Square.E3 },
        .{ .f = Square.FileE, .r = Square.Rank4, .exp = Square.E4 },
        .{ .f = Square.FileE, .r = Square.Rank5, .exp = Square.E5 },
        .{ .f = Square.FileE, .r = Square.Rank6, .exp = Square.E6 },
        .{ .f = Square.FileE, .r = Square.Rank7, .exp = Square.E7 },
        .{ .f = Square.FileE, .r = Square.Rank8, .exp = Square.E8 },
        .{ .f = Square.FileF, .r = Square.Rank1, .exp = Square.F1 },
        .{ .f = Square.FileF, .r = Square.Rank2, .exp = Square.F2 },
        .{ .f = Square.FileF, .r = Square.Rank3, .exp = Square.F3 },
        .{ .f = Square.FileF, .r = Square.Rank4, .exp = Square.F4 },
        .{ .f = Square.FileF, .r = Square.Rank5, .exp = Square.F5 },
        .{ .f = Square.FileF, .r = Square.Rank6, .exp = Square.F6 },
        .{ .f = Square.FileF, .r = Square.Rank7, .exp = Square.F7 },
        .{ .f = Square.FileF, .r = Square.Rank8, .exp = Square.F8 },
        .{ .f = Square.FileG, .r = Square.Rank1, .exp = Square.G1 },
        .{ .f = Square.FileG, .r = Square.Rank2, .exp = Square.G2 },
        .{ .f = Square.FileG, .r = Square.Rank3, .exp = Square.G3 },
        .{ .f = Square.FileG, .r = Square.Rank4, .exp = Square.G4 },
        .{ .f = Square.FileG, .r = Square.Rank5, .exp = Square.G5 },
        .{ .f = Square.FileG, .r = Square.Rank6, .exp = Square.G6 },
        .{ .f = Square.FileG, .r = Square.Rank7, .exp = Square.G7 },
        .{ .f = Square.FileG, .r = Square.Rank8, .exp = Square.G8 },
        .{ .f = Square.FileH, .r = Square.Rank1, .exp = Square.H1 },
        .{ .f = Square.FileH, .r = Square.Rank2, .exp = Square.H2 },
        .{ .f = Square.FileH, .r = Square.Rank3, .exp = Square.H3 },
        .{ .f = Square.FileH, .r = Square.Rank4, .exp = Square.H4 },
        .{ .f = Square.FileH, .r = Square.Rank5, .exp = Square.H5 },
        .{ .f = Square.FileH, .r = Square.Rank6, .exp = Square.H6 },
        .{ .f = Square.FileH, .r = Square.Rank7, .exp = Square.H7 },
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

test "Square fromIndex" {
    const testCase = struct {
        index: i8,
        file: i8,
        rank: i8,
        exp: i8,
    };
    const testCases: []const testCase = &[_]testCase{
        .{ .index = 0, .file = Square.FileA, .rank = Square.Rank1, .exp = Square.A1 },
        .{ .index = 1, .file = Square.FileB, .rank = Square.Rank1, .exp = Square.B1 },
        .{ .index = 2, .file = Square.FileC, .rank = Square.Rank1, .exp = Square.C1 },
        .{ .index = 3, .file = Square.FileD, .rank = Square.Rank1, .exp = Square.D1 },
        .{ .index = 4, .file = Square.FileE, .rank = Square.Rank1, .exp = Square.E1 },
        .{ .index = 5, .file = Square.FileF, .rank = Square.Rank1, .exp = Square.F1 },
        .{ .index = 6, .file = Square.FileG, .rank = Square.Rank1, .exp = Square.G1 },
        .{ .index = 7, .file = Square.FileH, .rank = Square.Rank1, .exp = Square.H1 },
        .{ .index = 8, .file = Square.FileA, .rank = Square.Rank2, .exp = Square.A2 },
        .{ .index = 9, .file = Square.FileB, .rank = Square.Rank2, .exp = Square.B2 },
        .{ .index = 10, .file = Square.FileC, .rank = Square.Rank2, .exp = Square.C2 },
        .{ .index = 11, .file = Square.FileD, .rank = Square.Rank2, .exp = Square.D2 },
        .{ .index = 12, .file = Square.FileE, .rank = Square.Rank2, .exp = Square.E2 },
        .{ .index = 13, .file = Square.FileF, .rank = Square.Rank2, .exp = Square.F2 },
        .{ .index = 14, .file = Square.FileG, .rank = Square.Rank2, .exp = Square.G2 },
        .{ .index = 15, .file = Square.FileH, .rank = Square.Rank2, .exp = Square.H2 },
        .{ .index = 16, .file = Square.FileA, .rank = Square.Rank3, .exp = Square.A3 },
        .{ .index = 17, .file = Square.FileB, .rank = Square.Rank3, .exp = Square.B3 },
        .{ .index = 18, .file = Square.FileC, .rank = Square.Rank3, .exp = Square.C3 },
        .{ .index = 19, .file = Square.FileD, .rank = Square.Rank3, .exp = Square.D3 },
        .{ .index = 20, .file = Square.FileE, .rank = Square.Rank3, .exp = Square.E3 },
        .{ .index = 21, .file = Square.FileF, .rank = Square.Rank3, .exp = Square.F3 },
        .{ .index = 22, .file = Square.FileG, .rank = Square.Rank3, .exp = Square.G3 },
        .{ .index = 23, .file = Square.FileH, .rank = Square.Rank3, .exp = Square.H3 },
        .{ .index = 24, .file = Square.FileA, .rank = Square.Rank4, .exp = Square.A4 },
        .{ .index = 25, .file = Square.FileB, .rank = Square.Rank4, .exp = Square.B4 },
        .{ .index = 26, .file = Square.FileC, .rank = Square.Rank4, .exp = Square.C4 },
        .{ .index = 27, .file = Square.FileD, .rank = Square.Rank4, .exp = Square.D4 },
        .{ .index = 28, .file = Square.FileE, .rank = Square.Rank4, .exp = Square.E4 },
        .{ .index = 29, .file = Square.FileF, .rank = Square.Rank4, .exp = Square.F4 },
        .{ .index = 30, .file = Square.FileG, .rank = Square.Rank4, .exp = Square.G4 },
        .{ .index = 31, .file = Square.FileH, .rank = Square.Rank4, .exp = Square.H4 },
        .{ .index = 32, .file = Square.FileA, .rank = Square.Rank5, .exp = Square.A5 },
        .{ .index = 33, .file = Square.FileB, .rank = Square.Rank5, .exp = Square.B5 },
        .{ .index = 34, .file = Square.FileC, .rank = Square.Rank5, .exp = Square.C5 },
        .{ .index = 35, .file = Square.FileD, .rank = Square.Rank5, .exp = Square.D5 },
        .{ .index = 36, .file = Square.FileE, .rank = Square.Rank5, .exp = Square.E5 },
        .{ .index = 37, .file = Square.FileF, .rank = Square.Rank5, .exp = Square.F5 },
        .{ .index = 38, .file = Square.FileG, .rank = Square.Rank5, .exp = Square.G5 },
        .{ .index = 39, .file = Square.FileH, .rank = Square.Rank5, .exp = Square.H5 },
        .{ .index = 40, .file = Square.FileA, .rank = Square.Rank6, .exp = Square.A6 },
        .{ .index = 41, .file = Square.FileB, .rank = Square.Rank6, .exp = Square.B6 },
        .{ .index = 42, .file = Square.FileC, .rank = Square.Rank6, .exp = Square.C6 },
        .{ .index = 43, .file = Square.FileD, .rank = Square.Rank6, .exp = Square.D6 },
        .{ .index = 44, .file = Square.FileE, .rank = Square.Rank6, .exp = Square.E6 },
        .{ .index = 45, .file = Square.FileF, .rank = Square.Rank6, .exp = Square.F6 },
        .{ .index = 46, .file = Square.FileG, .rank = Square.Rank6, .exp = Square.G6 },
        .{ .index = 47, .file = Square.FileH, .rank = Square.Rank6, .exp = Square.H6 },
        .{ .index = 48, .file = Square.FileA, .rank = Square.Rank7, .exp = Square.A7 },
        .{ .index = 49, .file = Square.FileB, .rank = Square.Rank7, .exp = Square.B7 },
        .{ .index = 50, .file = Square.FileC, .rank = Square.Rank7, .exp = Square.C7 },
        .{ .index = 51, .file = Square.FileD, .rank = Square.Rank7, .exp = Square.D7 },
        .{ .index = 52, .file = Square.FileE, .rank = Square.Rank7, .exp = Square.E7 },
        .{ .index = 53, .file = Square.FileF, .rank = Square.Rank7, .exp = Square.F7 },
        .{ .index = 54, .file = Square.FileG, .rank = Square.Rank7, .exp = Square.G7 },
        .{ .index = 55, .file = Square.FileH, .rank = Square.Rank7, .exp = Square.H7 },
        .{ .index = 56, .file = Square.FileA, .rank = Square.Rank8, .exp = Square.A8 },
        .{ .index = 57, .file = Square.FileB, .rank = Square.Rank8, .exp = Square.B8 },
        .{ .index = 58, .file = Square.FileC, .rank = Square.Rank8, .exp = Square.C8 },
        .{ .index = 59, .file = Square.FileD, .rank = Square.Rank8, .exp = Square.D8 },
        .{ .index = 60, .file = Square.FileE, .rank = Square.Rank8, .exp = Square.E8 },
        .{ .index = 61, .file = Square.FileF, .rank = Square.Rank8, .exp = Square.F8 },
        .{ .index = 62, .file = Square.FileG, .rank = Square.Rank8, .exp = Square.G8 },
        .{ .index = 63, .file = Square.FileH, .rank = Square.Rank8, .exp = Square.H8 },

        // Invalid cases
        .{ .index = -1, .file = Square.NoFile, .rank = Square.NoRank, .exp = Square.NoSquare },
        .{ .index = 64, .file = Square.NoFile, .rank = Square.NoRank, .exp = Square.NoSquare },
    };

    for (testCases) |tc| {
        const s = Square.fromIndex(tc.index);
        // std.debug.print("Index {d}: rank and file: {d} {d}\n", .{tc.index, s.r, s.f});
        try std.testing.expectEqual(tc.exp, s.s);
        try std.testing.expectEqual(tc.file, s.f);
        try std.testing.expectEqual(tc.rank, s.r);
    }
}