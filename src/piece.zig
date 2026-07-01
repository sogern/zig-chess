const std = @import("std");

pub const PieceError = error{
    InvalidPiece,
};

const pieces = [_]u8{ 'K', 'Q', 'R', 'B', 'N', 'P', 'k', 'q', 'r', 'b', 'n', 'p', ' ' };
const pieceTypes = [_]u8{ 'k', 'q', 'r', 'b', 'n', 'p', ' ' };
const colours = [_]u8{ 'w', 'b', ' ' };

pub const Piece = enum(u8) {
    WhiteKing,
    WhiteQueen,
    WhiteRook,
    WhiteBishop,
    WhiteKnight,
    WhitePawn,
    BlackKing,
    BlackQueen,
    BlackRook,
    BlackBishop,
    BlackKnight,
    BlackPawn,
    None,

    pub fn fromChar(c: u8) @This() {
        switch (c) {
            'K' => return .WhiteKing,
            'Q' => return .WhiteQueen,
            'R' => return .WhiteRook,
            'B' => return .WhiteBishop,
            'N' => return .WhiteKnight,
            'P' => return .WhitePawn,
            'k' => return .BlackKing,
            'q' => return .BlackQueen,
            'r' => return .BlackRook,
            'b' => return .BlackBishop,
            'n' => return .BlackKnight,
            'p' => return .BlackPawn,
            else => return .None,
        }
    }

    pub fn fromTypeAndColour(pt: PieceType, c: Colour) Piece {
        if (c == .None or pt == .None) return .None;
        return @enumFromInt(@intFromEnum(pt) + (@intFromEnum(c) * 6));
    }

    pub fn @"type"(self: @This()) PieceType {
        if (self == .None) return .None;
        return @enumFromInt(@intFromEnum(self) % 6);
    }

    pub fn colour(self: @This()) Colour {
        if (self == .None) return .None;
        return @enumFromInt(@intFromEnum(self) / 6);
    }

    pub fn char(self: @This()) u8 {
        return pieces[@intFromEnum(self)];
    }
};

pub const PieceType = enum(u8) {
    King,
    Queen,
    Rook,
    Bishop,
    Knight,
    Pawn,
    None,

    pub inline fn string(self: @This()) u8 {
        return pieceTypes[@intFromEnum(self)];
    }
};

pub fn pieceTypeFromChar(c: u8) PieceType {
    return switch (c) {
        'K', 'k' => .King,
        'Q', 'q' => .Queen,
        'R', 'r' => .Rook,
        'B', 'b' => .Bishop,
        'N', 'n' => .Knight,
        'P', 'p' => .Pawn,
        else => .None,
    };
}

pub const Colour = enum(u8) {
    White,
    Black,
    None,

    pub fn fromChar(c: u8) @This() {
        switch (c) {
            'w' => return .White,
            'b' => return .Black,
            else => return .None,
        }
    }

    pub fn char(self: @This()) u8 {
        return colours[@intFromEnum(self)];
    }

    pub fn opposite(self: @This()) @This() {
        return switch (self) {
            .White => .Black,
            .Black => .White,
            .None => .None,
        };
    }
};

test "pieces" {
    const TestCase = struct {
        c: Colour,
        pt: PieceType,
        e: Piece,
    };
    const testCases: [13]TestCase = .{
        .{ .c = .White, .pt = .King, .e = .WhiteKing },
        .{ .c = .Black, .pt = .King, .e = .BlackKing },
        .{ .c = .White, .pt = .Queen, .e = .WhiteQueen },
        .{ .c = .Black, .pt = .Queen, .e = .BlackQueen },
        .{ .c = .White, .pt = .Rook, .e = .WhiteRook },
        .{ .c = .Black, .pt = .Rook, .e = .BlackRook },
        .{ .c = .White, .pt = .Bishop, .e = .WhiteBishop },
        .{ .c = .Black, .pt = .Bishop, .e = .BlackBishop },
        .{ .c = .White, .pt = .Knight, .e = .WhiteKnight },
        .{ .c = .Black, .pt = .Knight, .e = .BlackKnight },
        .{ .c = .White, .pt = .Pawn, .e = .WhitePawn },
        .{ .c = .Black, .pt = .Pawn, .e = .BlackPawn },
        .{ .c = .None, .pt = .None, .e = .None },
    };

    for (testCases) |tc| {
        try std.testing.expectEqual(tc.e, Piece.fromTypeAndColour(tc.pt, tc.c));
    }
}

test "type from pieces" {
    const TestCase = struct {
        p: Piece,
        e: PieceType,
    };
    const testCases: [13]TestCase = .{
        .{ .p = .WhiteKing, .e = .King },
        .{ .p = .BlackKing, .e = .King },
        .{ .p = .WhiteQueen, .e = .Queen },
        .{ .p = .BlackQueen, .e = .Queen },
        .{ .p = .WhiteRook, .e = .Rook },
        .{ .p = .BlackRook, .e = .Rook },
        .{ .p = .WhiteBishop, .e = .Bishop },
        .{ .p = .BlackBishop, .e = .Bishop },
        .{ .p = .WhiteKnight, .e = .Knight },
        .{ .p = .BlackKnight, .e = .Knight },
        .{ .p = .WhitePawn, .e = .Pawn },
        .{ .p = .BlackPawn, .e = .Pawn },
        .{ .p = .None, .e = .None },
    };

    for (testCases) |tc| {
        try std.testing.expectEqual(tc.e, tc.p.type());
    }
}

test "types" {
    const testCases: [7]struct {
        pt: PieceType,
        e: u8,
    } = .{
        .{ .pt = .King, .e = 'k' },
        .{ .pt = .Queen, .e = 'q' },
        .{ .pt = .Rook, .e = 'r' },
        .{ .pt = .Bishop, .e = 'b' },
        .{ .pt = .Knight, .e = 'n' },
        .{ .pt = .Pawn, .e = 'p' },
        .{ .pt = .None, .e = ' ' },
    };

    for (testCases) |tc| {
        try std.testing.expectEqual(tc.e, tc.pt.string());
    }
}

test "colours" {
    const testCases: [3]struct {
        c: Colour,
        e: u8,
    } = .{
        .{ .c = .White, .e = 'w' },
        .{ .c = .Black, .e = 'b' },
        .{ .c = .None, .e = ' ' },
    };

    for (testCases) |tc| {
        try std.testing.expectEqual(tc.e, tc.c.char());
    }
}
