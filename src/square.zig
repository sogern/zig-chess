const std = @import("std");

pub const Self = @This();

pub const numSquaresOnBoard = 64;
pub const numSquaresInRow = 8;

/// Rank in the range 0-7, or NoRank if invalid
r: i8 = NoRank,
/// File in the range 0-7, or NoFile if invalid
f: i8 = NoFile,
/// Square bitboard index 0-63, or NoSquare if invalid
s: i8 = NoSquare,

pub inline fn squareBit(index: usize) u64 {
    return squareBits[index];
}

pub fn fromIndex(index: i8) Self {
    if (index < 0 or index >= numSquaresOnBoard) return .{};
    const rank = @divTrunc(index, numSquaresInRow);
    const file = @mod(index, numSquaresInRow);
    return .{ .s = index, .r = @intCast(rank), .f = @intCast(file) };
}

pub fn fromFileAndRank(file: i8, rank: i8) Self {
    if (file < 0 or file > 7 or rank < 0 or rank > 7) return .{};
    const out = (rank * numSquaresInRow) + file;
    return .{ .s = @intCast(out), .r = rank, .f = file };
}

pub fn fromString(s: []const u8) Self {
    if (s.len != 2 or s[0] < 'a' or s[1] < '1') return .{};
    const file = s[0] - 'a';
    const rank = s[1] - '1';
    if (file > 7 or rank > 7) return .{};
    const out = (rank * numSquaresInRow) + file;
    return .{ .s = @intCast(out), .r = @intCast(rank), .f = @intCast(file) };
}

pub fn getBitboard(self: Self) u64 {
    if (self.s == NoSquare) return 0;
    return squareBits[@as(usize, @intCast(self.s))];
}

pub fn toString(self: Self) []const u8 {
    if (self.s == NoSquare) return "";
    return squareStrings[@as(usize, @intCast(self.s))];
}

pub fn equals(self: Self, other: Self) bool {
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

pub const squareBits = [_]u64{
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

pub const None: Self = .{ .s = NoSquare, .f = NoFile, .r = NoRank };
pub const SqA1: Self = .{ .s = A1, .f = FileA, .r = Rank1 };
pub const SqA2: Self = .{ .s = A2, .f = FileA, .r = Rank2 };
pub const SqA3: Self = .{ .s = A3, .f = FileA, .r = Rank3 };
pub const SqA4: Self = .{ .s = A4, .f = FileA, .r = Rank4 };
pub const SqA5: Self = .{ .s = A5, .f = FileA, .r = Rank5 };
pub const SqA6: Self = .{ .s = A6, .f = FileA, .r = Rank6 };
pub const SqA7: Self = .{ .s = A7, .f = FileA, .r = Rank7 };
pub const SqA8: Self = .{ .s = A8, .f = FileA, .r = Rank8 };
pub const SqB1: Self = .{ .s = B1, .f = FileB, .r = Rank1 };
pub const SqB2: Self = .{ .s = B2, .f = FileB, .r = Rank2 };
pub const SqB3: Self = .{ .s = B3, .f = FileB, .r = Rank3 };
pub const SqB4: Self = .{ .s = B4, .f = FileB, .r = Rank4 };
pub const SqB5: Self = .{ .s = B5, .f = FileB, .r = Rank5 };
pub const SqB6: Self = .{ .s = B6, .f = FileB, .r = Rank6 };
pub const SqB7: Self = .{ .s = B7, .f = FileB, .r = Rank7 };
pub const SqB8: Self = .{ .s = B8, .f = FileB, .r = Rank8 };
pub const SqC1: Self = .{ .s = C1, .f = FileC, .r = Rank1 };
pub const SqC2: Self = .{ .s = C2, .f = FileC, .r = Rank2 };
pub const SqC3: Self = .{ .s = C3, .f = FileC, .r = Rank3 };
pub const SqC4: Self = .{ .s = C4, .f = FileC, .r = Rank4 };
pub const SqC5: Self = .{ .s = C5, .f = FileC, .r = Rank5 };
pub const SqC6: Self = .{ .s = C6, .f = FileC, .r = Rank6 };
pub const SqC7: Self = .{ .s = C7, .f = FileC, .r = Rank7 };
pub const SqC8: Self = .{ .s = C8, .f = FileC, .r = Rank8 };
pub const SqD1: Self = .{ .s = D1, .f = FileD, .r = Rank1 };
pub const SqD2: Self = .{ .s = D2, .f = FileD, .r = Rank2 };
pub const SqD3: Self = .{ .s = D3, .f = FileD, .r = Rank3 };
pub const SqD4: Self = .{ .s = D4, .f = FileD, .r = Rank4 };
pub const SqD5: Self = .{ .s = D5, .f = FileD, .r = Rank5 };
pub const SqD6: Self = .{ .s = D6, .f = FileD, .r = Rank6 };
pub const SqD7: Self = .{ .s = D7, .f = FileD, .r = Rank7 };
pub const SqD8: Self = .{ .s = D8, .f = FileD, .r = Rank8 };
pub const SqE1: Self = .{ .s = E1, .f = FileE, .r = Rank1 };
pub const SqE2: Self = .{ .s = E2, .f = FileE, .r = Rank2 };
pub const SqE3: Self = .{ .s = E3, .f = FileE, .r = Rank3 };
pub const SqE4: Self = .{ .s = E4, .f = FileE, .r = Rank4 };
pub const SqE5: Self = .{ .s = E5, .f = FileE, .r = Rank5 };
pub const SqE6: Self = .{ .s = E6, .f = FileE, .r = Rank6 };
pub const SqE7: Self = .{ .s = E7, .f = FileE, .r = Rank7 };
pub const SqE8: Self = .{ .s = E8, .f = FileE, .r = Rank8 };
pub const SqF1: Self = .{ .s = F1, .f = FileF, .r = Rank1 };
pub const SqF2: Self = .{ .s = F2, .f = FileF, .r = Rank2 };
pub const SqF3: Self = .{ .s = F3, .f = FileF, .r = Rank3 };
pub const SqF4: Self = .{ .s = F4, .f = FileF, .r = Rank4 };
pub const SqF5: Self = .{ .s = F5, .f = FileF, .r = Rank5 };
pub const SqF6: Self = .{ .s = F6, .f = FileF, .r = Rank6 };
pub const SqF7: Self = .{ .s = F7, .f = FileF, .r = Rank7 };
pub const SqF8: Self = .{ .s = F8, .f = FileF, .r = Rank8 };
pub const SqG1: Self = .{ .s = G1, .f = FileG, .r = Rank1 };
pub const SqG2: Self = .{ .s = G2, .f = FileG, .r = Rank2 };
pub const SqG3: Self = .{ .s = G3, .f = FileG, .r = Rank3 };
pub const SqG4: Self = .{ .s = G4, .f = FileG, .r = Rank4 };
pub const SqG5: Self = .{ .s = G5, .f = FileG, .r = Rank5 };
pub const SqG6: Self = .{ .s = G6, .f = FileG, .r = Rank6 };
pub const SqG7: Self = .{ .s = G7, .f = FileG, .r = Rank7 };
pub const SqG8: Self = .{ .s = G8, .f = FileG, .r = Rank8 };
pub const SqH1: Self = .{ .s = H1, .f = FileH, .r = Rank1 };
pub const SqH2: Self = .{ .s = H2, .f = FileH, .r = Rank2 };
pub const SqH3: Self = .{ .s = H3, .f = FileH, .r = Rank3 };
pub const SqH4: Self = .{ .s = H4, .f = FileH, .r = Rank4 };
pub const SqH5: Self = .{ .s = H5, .f = FileH, .r = Rank5 };
pub const SqH6: Self = .{ .s = H6, .f = FileH, .r = Rank6 };
pub const SqH7: Self = .{ .s = H7, .f = FileH, .r = Rank7 };
pub const SqH8: Self = .{ .s = H8, .f = FileH, .r = Rank8 };

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

test "fromString and toString" {
    const testCase = struct {
        s: i8,
        str: []const u8,
        exp: []const u8,
    };
    const testCases: []const testCase = &[_]testCase{
        .{ .s = A1, .str = "a1", .exp = "a1" },
        .{ .s = A2, .str = "a2", .exp = "a2" },
        .{ .s = A3, .str = "a3", .exp = "a3" },
        .{ .s = A4, .str = "a4", .exp = "a4" },
        .{ .s = A5, .str = "a5", .exp = "a5" },
        .{ .s = A6, .str = "a6", .exp = "a6" },
        .{ .s = A7, .str = "a7", .exp = "a7" },
        .{ .s = A8, .str = "a8", .exp = "a8" },
        .{ .s = B1, .str = "b1", .exp = "b1" },
        .{ .s = B2, .str = "b2", .exp = "b2" },
        .{ .s = B3, .str = "b3", .exp = "b3" },
        .{ .s = B4, .str = "b4", .exp = "b4" },
        .{ .s = B5, .str = "b5", .exp = "b5" },
        .{ .s = B6, .str = "b6", .exp = "b6" },
        .{ .s = B7, .str = "b7", .exp = "b7" },
        .{ .s = B8, .str = "b8", .exp = "b8" },
        .{ .s = C1, .str = "c1", .exp = "c1" },
        .{ .s = C2, .str = "c2", .exp = "c2" },
        .{ .s = C3, .str = "c3", .exp = "c3" },
        .{ .s = C4, .str = "c4", .exp = "c4" },
        .{ .s = C5, .str = "c5", .exp = "c5" },
        .{ .s = C6, .str = "c6", .exp = "c6" },
        .{ .s = C7, .str = "c7", .exp = "c7" },
        .{ .s = C8, .str = "c8", .exp = "c8" },
        .{ .s = D1, .str = "d1", .exp = "d1" },
        .{ .s = D2, .str = "d2", .exp = "d2" },
        .{ .s = D3, .str = "d3", .exp = "d3" },
        .{ .s = D4, .str = "d4", .exp = "d4" },
        .{ .s = D5, .str = "d5", .exp = "d5" },
        .{ .s = D6, .str = "d6", .exp = "d6" },
        .{ .s = D7, .str = "d7", .exp = "d7" },
        .{ .s = D8, .str = "d8", .exp = "d8" },
        .{ .s = E1, .str = "e1", .exp = "e1" },
        .{ .s = E2, .str = "e2", .exp = "e2" },
        .{ .s = E3, .str = "e3", .exp = "e3" },
        .{ .s = E4, .str = "e4", .exp = "e4" },
        .{ .s = E5, .str = "e5", .exp = "e5" },
        .{ .s = E6, .str = "e6", .exp = "e6" },
        .{ .s = E7, .str = "e7", .exp = "e7" },
        .{ .s = E8, .str = "e8", .exp = "e8" },
        .{ .s = F1, .str = "f1", .exp = "f1" },
        .{ .s = F2, .str = "f2", .exp = "f2" },
        .{ .s = F3, .str = "f3", .exp = "f3" },
        .{ .s = F4, .str = "f4", .exp = "f4" },
        .{ .s = F5, .str = "f5", .exp = "f5" },
        .{ .s = F6, .str = "f6", .exp = "f6" },
        .{ .s = F7, .str = "f7", .exp = "f7" },
        .{ .s = F8, .str = "f8", .exp = "f8" },
        .{ .s = G1, .str = "g1", .exp = "g1" },
        .{ .s = G2, .str = "g2", .exp = "g2" },
        .{ .s = G3, .str = "g3", .exp = "g3" },
        .{ .s = G4, .str = "g4", .exp = "g4" },
        .{ .s = G5, .str = "g5", .exp = "g5" },
        .{ .s = G6, .str = "g6", .exp = "g6" },
        .{ .s = G7, .str = "g7", .exp = "g7" },
        .{ .s = G8, .str = "g8", .exp = "g8" },
        .{ .s = H1, .str = "h1", .exp = "h1" },
        .{ .s = H2, .str = "h2", .exp = "h2" },
        .{ .s = H3, .str = "h3", .exp = "h3" },
        .{ .s = H4, .str = "h4", .exp = "h4" },
        .{ .s = H5, .str = "h5", .exp = "h5" },
        .{ .s = H6, .str = "h6", .exp = "h6" },
        .{ .s = H7, .str = "h7", .exp = "h7" },
        .{ .s = H8, .str = "h8", .exp = "h8" },
        .{ .s = NoSquare, .str = "z0", .exp = "" },
        .{ .s = NoSquare, .str = "a9", .exp = "" },
        .{ .s = NoSquare, .str = "i1", .exp = "" },
        .{ .s = NoSquare, .str = "", .exp = "" },
        .{ .s = NoSquare, .str = "invalid", .exp = "" },
    };

    for (testCases) |tc| {
        const s = fromString(tc.str);
        try std.testing.expectEqual(tc.s, s.s);
        const str = s.toString();
        try std.testing.expectEqualStrings(tc.exp, str);
    }
}

test fromFileAndRank {
    const testCase = struct {
        f: i8,
        r: i8,
        exp: i8,
    };
    const testCases: []const testCase = &[_]testCase{
        .{ .f = FileA, .r = Rank1, .exp = A1 },
        .{ .f = FileA, .r = Rank2, .exp = A2 },
        .{ .f = FileA, .r = Rank3, .exp = A3 },
        .{ .f = FileA, .r = Rank4, .exp = A4 },
        .{ .f = FileA, .r = Rank5, .exp = A5 },
        .{ .f = FileA, .r = Rank6, .exp = A6 },
        .{ .f = FileA, .r = Rank7, .exp = A7 },
        .{ .f = FileA, .r = Rank8, .exp = A8 },
        .{ .f = FileB, .r = Rank1, .exp = B1 },
        .{ .f = FileB, .r = Rank2, .exp = B2 },
        .{ .f = FileB, .r = Rank3, .exp = B3 },
        .{ .f = FileB, .r = Rank4, .exp = B4 },
        .{ .f = FileB, .r = Rank5, .exp = B5 },
        .{ .f = FileB, .r = Rank6, .exp = B6 },
        .{ .f = FileB, .r = Rank7, .exp = B7 },
        .{ .f = FileB, .r = Rank8, .exp = B8 },
        .{ .f = FileC, .r = Rank1, .exp = C1 },
        .{ .f = FileC, .r = Rank2, .exp = C2 },
        .{ .f = FileC, .r = Rank3, .exp = C3 },
        .{ .f = FileC, .r = Rank4, .exp = C4 },
        .{ .f = FileC, .r = Rank5, .exp = C5 },
        .{ .f = FileC, .r = Rank6, .exp = C6 },
        .{ .f = FileC, .r = Rank7, .exp = C7 },
        .{ .f = FileC, .r = Rank8, .exp = C8 },
        .{ .f = FileD, .r = Rank1, .exp = D1 },
        .{ .f = FileD, .r = Rank2, .exp = D2 },
        .{ .f = FileD, .r = Rank3, .exp = D3 },
        .{ .f = FileD, .r = Rank4, .exp = D4 },
        .{ .f = FileD, .r = Rank5, .exp = D5 },
        .{ .f = FileD, .r = Rank6, .exp = D6 },
        .{ .f = FileD, .r = Rank7, .exp = D7 },
        .{ .f = FileD, .r = Rank8, .exp = D8 },
        .{ .f = FileE, .r = Rank1, .exp = E1 },
        .{ .f = FileE, .r = Rank2, .exp = E2 },
        .{ .f = FileE, .r = Rank3, .exp = E3 },
        .{ .f = FileE, .r = Rank4, .exp = E4 },
        .{ .f = FileE, .r = Rank5, .exp = E5 },
        .{ .f = FileE, .r = Rank6, .exp = E6 },
        .{ .f = FileE, .r = Rank7, .exp = E7 },
        .{ .f = FileE, .r = Rank8, .exp = E8 },
        .{ .f = FileF, .r = Rank1, .exp = F1 },
        .{ .f = FileF, .r = Rank2, .exp = F2 },
        .{ .f = FileF, .r = Rank3, .exp = F3 },
        .{ .f = FileF, .r = Rank4, .exp = F4 },
        .{ .f = FileF, .r = Rank5, .exp = F5 },
        .{ .f = FileF, .r = Rank6, .exp = F6 },
        .{ .f = FileF, .r = Rank7, .exp = F7 },
        .{ .f = FileF, .r = Rank8, .exp = F8 },
        .{ .f = FileG, .r = Rank1, .exp = G1 },
        .{ .f = FileG, .r = Rank2, .exp = G2 },
        .{ .f = FileG, .r = Rank3, .exp = G3 },
        .{ .f = FileG, .r = Rank4, .exp = G4 },
        .{ .f = FileG, .r = Rank5, .exp = G5 },
        .{ .f = FileG, .r = Rank6, .exp = G6 },
        .{ .f = FileG, .r = Rank7, .exp = G7 },
        .{ .f = FileG, .r = Rank8, .exp = G8 },
        .{ .f = FileH, .r = Rank1, .exp = H1 },
        .{ .f = FileH, .r = Rank2, .exp = H2 },
        .{ .f = FileH, .r = Rank3, .exp = H3 },
        .{ .f = FileH, .r = Rank4, .exp = H4 },
        .{ .f = FileH, .r = Rank5, .exp = H5 },
        .{ .f = FileH, .r = Rank6, .exp = H6 },
        .{ .f = FileH, .r = Rank7, .exp = H7 },
        .{ .f = FileH, .r = Rank8, .exp = H8 },
        // Invalid cases
        .{ .f = NoFile, .r = NoRank, .exp = NoSquare },
        .{ .f = 8, .r = 0, .exp = NoSquare },
        .{ .f = 0, .r = 8, .exp = NoSquare },
    };

    for (testCases) |tc| {
        const s = fromFileAndRank(tc.f, tc.r);
        try std.testing.expectEqual(tc.exp, s.s);
    }
}

test fromIndex {
    const testCase = struct {
        index: i8,
        file: i8,
        rank: i8,
        exp: i8,
    };
    const testCases: []const testCase = &[_]testCase{
        .{ .index = 0, .file = FileA, .rank = Rank1, .exp = A1 },
        .{ .index = 1, .file = FileB, .rank = Rank1, .exp = B1 },
        .{ .index = 2, .file = FileC, .rank = Rank1, .exp = C1 },
        .{ .index = 3, .file = FileD, .rank = Rank1, .exp = D1 },
        .{ .index = 4, .file = FileE, .rank = Rank1, .exp = E1 },
        .{ .index = 5, .file = FileF, .rank = Rank1, .exp = F1 },
        .{ .index = 6, .file = FileG, .rank = Rank1, .exp = G1 },
        .{ .index = 7, .file = FileH, .rank = Rank1, .exp = H1 },
        .{ .index = 8, .file = FileA, .rank = Rank2, .exp = A2 },
        .{ .index = 9, .file = FileB, .rank = Rank2, .exp = B2 },
        .{ .index = 10, .file = FileC, .rank = Rank2, .exp = C2 },
        .{ .index = 11, .file = FileD, .rank = Rank2, .exp = D2 },
        .{ .index = 12, .file = FileE, .rank = Rank2, .exp = E2 },
        .{ .index = 13, .file = FileF, .rank = Rank2, .exp = F2 },
        .{ .index = 14, .file = FileG, .rank = Rank2, .exp = G2 },
        .{ .index = 15, .file = FileH, .rank = Rank2, .exp = H2 },
        .{ .index = 16, .file = FileA, .rank = Rank3, .exp = A3 },
        .{ .index = 17, .file = FileB, .rank = Rank3, .exp = B3 },
        .{ .index = 18, .file = FileC, .rank = Rank3, .exp = C3 },
        .{ .index = 19, .file = FileD, .rank = Rank3, .exp = D3 },
        .{ .index = 20, .file = FileE, .rank = Rank3, .exp = E3 },
        .{ .index = 21, .file = FileF, .rank = Rank3, .exp = F3 },
        .{ .index = 22, .file = FileG, .rank = Rank3, .exp = G3 },
        .{ .index = 23, .file = FileH, .rank = Rank3, .exp = H3 },
        .{ .index = 24, .file = FileA, .rank = Rank4, .exp = A4 },
        .{ .index = 25, .file = FileB, .rank = Rank4, .exp = B4 },
        .{ .index = 26, .file = FileC, .rank = Rank4, .exp = C4 },
        .{ .index = 27, .file = FileD, .rank = Rank4, .exp = D4 },
        .{ .index = 28, .file = FileE, .rank = Rank4, .exp = E4 },
        .{ .index = 29, .file = FileF, .rank = Rank4, .exp = F4 },
        .{ .index = 30, .file = FileG, .rank = Rank4, .exp = G4 },
        .{ .index = 31, .file = FileH, .rank = Rank4, .exp = H4 },
        .{ .index = 32, .file = FileA, .rank = Rank5, .exp = A5 },
        .{ .index = 33, .file = FileB, .rank = Rank5, .exp = B5 },
        .{ .index = 34, .file = FileC, .rank = Rank5, .exp = C5 },
        .{ .index = 35, .file = FileD, .rank = Rank5, .exp = D5 },
        .{ .index = 36, .file = FileE, .rank = Rank5, .exp = E5 },
        .{ .index = 37, .file = FileF, .rank = Rank5, .exp = F5 },
        .{ .index = 38, .file = FileG, .rank = Rank5, .exp = G5 },
        .{ .index = 39, .file = FileH, .rank = Rank5, .exp = H5 },
        .{ .index = 40, .file = FileA, .rank = Rank6, .exp = A6 },
        .{ .index = 41, .file = FileB, .rank = Rank6, .exp = B6 },
        .{ .index = 42, .file = FileC, .rank = Rank6, .exp = C6 },
        .{ .index = 43, .file = FileD, .rank = Rank6, .exp = D6 },
        .{ .index = 44, .file = FileE, .rank = Rank6, .exp = E6 },
        .{ .index = 45, .file = FileF, .rank = Rank6, .exp = F6 },
        .{ .index = 46, .file = FileG, .rank = Rank6, .exp = G6 },
        .{ .index = 47, .file = FileH, .rank = Rank6, .exp = H6 },
        .{ .index = 48, .file = FileA, .rank = Rank7, .exp = A7 },
        .{ .index = 49, .file = FileB, .rank = Rank7, .exp = B7 },
        .{ .index = 50, .file = FileC, .rank = Rank7, .exp = C7 },
        .{ .index = 51, .file = FileD, .rank = Rank7, .exp = D7 },
        .{ .index = 52, .file = FileE, .rank = Rank7, .exp = E7 },
        .{ .index = 53, .file = FileF, .rank = Rank7, .exp = F7 },
        .{ .index = 54, .file = FileG, .rank = Rank7, .exp = G7 },
        .{ .index = 55, .file = FileH, .rank = Rank7, .exp = H7 },
        .{ .index = 56, .file = FileA, .rank = Rank8, .exp = A8 },
        .{ .index = 57, .file = FileB, .rank = Rank8, .exp = B8 },
        .{ .index = 58, .file = FileC, .rank = Rank8, .exp = C8 },
        .{ .index = 59, .file = FileD, .rank = Rank8, .exp = D8 },
        .{ .index = 60, .file = FileE, .rank = Rank8, .exp = E8 },
        .{ .index = 61, .file = FileF, .rank = Rank8, .exp = F8 },
        .{ .index = 62, .file = FileG, .rank = Rank8, .exp = G8 },
        .{ .index = 63, .file = FileH, .rank = Rank8, .exp = H8 },

        // Invalid cases
        .{ .index = -1, .file = NoFile, .rank = NoRank, .exp = NoSquare },
        .{ .index = 64, .file = NoFile, .rank = NoRank, .exp = NoSquare },
    };

    for (testCases) |tc| {
        const s = fromIndex(tc.index);
        // std.debug.print("Index {d}: rank and file: {d} {d}\n", .{tc.index, s.r, s.f});
        try std.testing.expectEqual(tc.exp, s.s);
        try std.testing.expectEqual(tc.file, s.f);
        try std.testing.expectEqual(tc.rank, s.r);
    }
}