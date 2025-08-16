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

    pub fn fromChar(c: u8) Piece {
        switch (c) {
            'K' => return Piece.WhiteKing,
            'Q' => return Piece.WhiteQueen,
            'R' => return Piece.WhiteRook,
            'B' => return Piece.WhiteBishop,
            'N' => return Piece.WhiteKnight,
            'P' => return Piece.WhitePawn,
            'k' => return Piece.BlackKing,
            'q' => return Piece.BlackQueen,
            'r' => return Piece.BlackRook,
            'b' => return Piece.BlackBishop,
            'n' => return Piece.BlackKnight,
            'p' => return Piece.BlackPawn,
            else => return Piece.None,
        }
    }

    pub fn @"type"(self: @This()) PieceType {
        if (self == Piece.None) {
            return PieceType.None;
        }
        return @enumFromInt(@intFromEnum(self) % 6);
    }

    pub fn toChar(self: @This()) u8 {
        return pieces[@intFromEnum(self)];
    }
};

pub fn newPiece(pieceType: PieceType, colour: Colour) Piece {
    if (colour == Colour.None or pieceType == PieceType.None) {
        return Piece.None;
    }
    return @enumFromInt(@intFromEnum(pieceType) + (@intFromEnum(colour) * 6));
}

pub const PieceType = enum(u8) {
    King,
    Queen,
    Rook,
    Bishop,
    Knight,
    Pawn,
    None,

    pub fn toString(self: @This()) u8 {
        return pieceTypes[@intFromEnum(self)];
    }
};

pub const Colour = enum(u8) {
    White,
    Black,
    None,

    pub fn toString(self: @This()) u8 {
        return colours[@intFromEnum(self)];
    }
};

test "create new pieces" {
    const TestCase = struct {
        c: Colour,
        pt: PieceType,
        e: Piece,
    };
    const testCases: [13]TestCase = .{
        .{ .c = Colour.White, .pt = PieceType.King, .e = Piece.WhiteKing },
        .{ .c = Colour.Black, .pt = PieceType.King, .e = Piece.BlackKing },
        .{ .c = Colour.White, .pt = PieceType.Queen, .e = Piece.WhiteQueen },
        .{ .c = Colour.Black, .pt = PieceType.Queen, .e = Piece.BlackQueen },
        .{ .c = Colour.White, .pt = PieceType.Rook, .e = Piece.WhiteRook },
        .{ .c = Colour.Black, .pt = PieceType.Rook, .e = Piece.BlackRook },
        .{ .c = Colour.White, .pt = PieceType.Bishop, .e = Piece.WhiteBishop },
        .{ .c = Colour.Black, .pt = PieceType.Bishop, .e = Piece.BlackBishop },
        .{ .c = Colour.White, .pt = PieceType.Knight, .e = Piece.WhiteKnight },
        .{ .c = Colour.Black, .pt = PieceType.Knight, .e = Piece.BlackKnight },
        .{ .c = Colour.White, .pt = PieceType.Pawn, .e = Piece.WhitePawn },
        .{ .c = Colour.Black, .pt = PieceType.Pawn, .e = Piece.BlackPawn },
        .{ .c = Colour.None, .pt = PieceType.None, .e = Piece.None },
    };

    for (testCases) |tc| {
        try std.testing.expectEqual(tc.e, newPiece(tc.pt, tc.c));
    }
}

test "piece type from pieces" {
    const TestCase = struct {
        p: Piece,
        e: PieceType,
    };
    const testCases: [13]TestCase = .{
        .{ .p = Piece.WhiteKing, .e = PieceType.King },
        .{ .p = Piece.BlackKing, .e = PieceType.King },
        .{ .p = Piece.WhiteQueen, .e = PieceType.Queen },
        .{ .p = Piece.BlackQueen, .e = PieceType.Queen },
        .{ .p = Piece.WhiteRook, .e = PieceType.Rook },
        .{ .p = Piece.BlackRook, .e = PieceType.Rook },
        .{ .p = Piece.WhiteBishop, .e = PieceType.Bishop },
        .{ .p = Piece.BlackBishop, .e = PieceType.Bishop },
        .{ .p = Piece.WhiteKnight, .e = PieceType.Knight },
        .{ .p = Piece.BlackKnight, .e = PieceType.Knight },
        .{ .p = Piece.WhitePawn, .e = PieceType.Pawn },
        .{ .p = Piece.BlackPawn, .e = PieceType.Pawn },
        .{ .p = Piece.None, .e = PieceType.None },
    };

    for (testCases) |tc| {
        try std.testing.expectEqual(tc.e, tc.p.type());
    }
}

test "string representation of piece types" {
    const testCases: [7]struct {
        pt: PieceType,
        e: u8,
    } = .{
        .{ .pt = PieceType.King, .e = 'k' },
        .{ .pt = PieceType.Queen, .e = 'q' },
        .{ .pt = PieceType.Rook, .e = 'r' },
        .{ .pt = PieceType.Bishop, .e = 'b' },
        .{ .pt = PieceType.Knight, .e = 'n' },
        .{ .pt = PieceType.Pawn, .e = 'p' },
        .{ .pt = PieceType.None, .e = ' ' },
    };

    for (testCases) |tc| {
        try std.testing.expectEqual(tc.e, tc.pt.toString());
    }
}

test "string representation of colours" {
    const testCases: [3]struct {
        c: Colour,
        e: u8,
    } = .{
        .{ .c = Colour.White, .e = 'w' },
        .{ .c = Colour.Black, .e = 'b' },
        .{ .c = Colour.None, .e = ' ' },
    };

    for (testCases) |tc| {
        try std.testing.expectEqual(tc.e, tc.c.toString());
    }
}
