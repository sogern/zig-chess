const std = @import("std");
const bitboard = @import("bitboard.zig").bitboard;
const Piece = @import("piece.zig").Piece;
const Colour = @import("piece.zig").Colour;
const PieceError = @import("piece.zig").PieceError;
const Square = @import("square.zig").Square;

pub const BoardError = error{
    SquareOccupied,
};

pub const Board = packed struct {
    whiteKing: bitboard = 0,
    whiteQueen: bitboard = 0,
    whiteRooks: bitboard = 0,
    whiteBishops: bitboard = 0,
    whiteKnights: bitboard = 0,
    whitePawns: bitboard = 0,
    blackKing: bitboard = 0,
    blackQueen: bitboard = 0,
    blackRooks: bitboard = 0,
    blackBishops: bitboard = 0,
    blackKnights: bitboard = 0,
    blackPawns: bitboard = 0,
    whiteSquares: bitboard = 0,  // all white pieces
    blackSquares: bitboard = 0,  // all black pieces
    emptySquares: bitboard = 0xFFFFFFFFFFFFFFFF,

    pub fn getBBForPiece(self: *Board, piece: Piece) !bitboard {
        return switch (piece) {
            .WhiteKing => self.whiteKing,
            .WhiteQueen => self.whiteQueen,
            .WhiteRook => self.whiteRooks,
            .WhiteBishop => self.whiteBishops,
            .WhiteKnight => self.whiteKnights,
            .WhitePawn => self.whitePawns,
            .BlackKing => self.blackKing,
            .BlackQueen => self.blackQueen,
            .BlackRook => self.blackRooks,
            .BlackBishop => self.blackBishops,
            .BlackKnight => self.blackKnights,
            .BlackPawn => self.blackPawns,
            else => PieceError.InvalidPiece,
        };
    }

    inline fn setBitboardBit(bb: bitboard, s: i8) bitboard {
        return bb | Square.squareBit(@intCast(s));
    }

    inline fn clearBitboardBit(bb: bitboard, s: i8) bitboard {
        return bb & ~Square.squareBit(@intCast(s));
    }

    pub inline fn isSquareOccupied(self: Board, square: Square) bool {
        const bit: bitboard = Square.squareBit(@intCast(square.s));
        return (self.whiteSquares & bit) != 0 or (self.blackSquares & bit) != 0;
    }

    pub inline fn isSquareEmpty(self: Board, square: Square) bool {
        const bit: bitboard = Square.squareBit(@intCast(square.s));
        return (self.emptySquares & bit) != 0;
    }

    pub fn getPieceOnSquare(self: Board, square: Square) Piece {
        const bit: bitboard = Square.squareBit(@intCast(square.s));
        if ((self.whiteSquares & bit) != 0) {
            if ((self.whiteKing & bit) != 0) return Piece.WhiteKing;
            if ((self.whiteQueen & bit) != 0) return Piece.WhiteQueen;
            if ((self.whiteRooks & bit) != 0) return Piece.WhiteRook;
            if ((self.whiteBishops & bit) != 0) return Piece.WhiteBishop;
            if ((self.whiteKnights & bit) != 0) return Piece.WhiteKnight;
            if ((self.whitePawns & bit) != 0) return Piece.WhitePawn;
        } else if ((self.blackSquares & bit) != 0) {
            if ((self.blackKing & bit) != 0) return Piece.BlackKing;
            if ((self.blackQueen & bit) != 0) return Piece.BlackQueen;
            if ((self.blackRooks & bit) != 0) return Piece.BlackRook;
            if ((self.blackBishops & bit) != 0) return Piece.BlackBishop;
            if ((self.blackKnights & bit) != 0) return Piece.BlackKnight;
            if ((self.blackPawns & bit) != 0) return Piece.BlackPawn;
        }
        return Piece.None;
    }

    pub fn placePiece(self: *Board, p: Piece, square: Square) !void {
        if (self.isSquareOccupied(square)) {
            return BoardError.SquareOccupied;
        }

        const bit: bitboard = setBitboardBit(0, square.s);
        // std.debug.print("piece: {c}, square: {s}, bit: {b}\n", .{p.toChar(), square.toString(), bit});

        switch (p) {
            .WhiteKing => {
                self.whiteKing |= bit;
                self.whiteSquares |= bit;
            },
            .BlackKing => {
                self.blackKing |= bit;
                self.blackSquares |= bit;
            },
            .WhiteQueen => {
                self.whiteQueen |= bit;
                self.whiteSquares |= bit;
            },
            .BlackQueen => {
                self.blackQueen |= bit;
                self.blackSquares |= bit;
            },
            .WhiteRook => {
                self.whiteRooks |= bit;
                self.whiteSquares |= bit;
            },
            .BlackRook => {
                self.blackRooks |= bit;
                self.blackSquares |= bit;
            },
            .WhiteBishop => {
                self.whiteBishops |= bit;
                self.whiteSquares |= bit;
            },
            .BlackBishop => {
                self.blackBishops |= bit;
                self.blackSquares |= bit;
            },
            .WhiteKnight => {
                self.whiteKnights |= bit;
                self.whiteSquares |= bit;
            },
            .BlackKnight => {
                self.blackKnights |= bit;
                self.blackSquares |= bit;
            },
            .WhitePawn => {
                self.whitePawns |= bit;
                self.whiteSquares |= bit;
            },
            .BlackPawn => {
                self.blackPawns |= bit;
                self.blackSquares |= bit;
            },
            else => return PieceError.InvalidPiece,
        }

        self.emptySquares = clearBitboardBit(self.emptySquares, square.s);
    }

    pub fn getKingSquare(self: Board, colour: Colour) Square {
        return switch(colour) {
            .None => .None,
            .White => {
                if (self.whiteKing == 0) return Square.None;
                const index = @as(i8, @clz(self.whiteKing));
                return Square.fromIndex(index);
            },
            .Black => {
                if (self.blackKing == 0) return Square.None;
                const index = @as(i8, @clz(self.blackKing));
                return Square.fromIndex(index);
            },
        };
    }

    /// Draw returns a string representation of the board.
    pub fn draw(self: Board) []const u8 {
        const alloc = std.heap.page_allocator;
        const lines = [_][]const u8{
            "  A B C D E F G H\n",
            "8                \n",
            "7                \n",
            "6                \n",
            "5                \n",
            "4                \n",
            "3                \n",
            "2                \n",
            "1                \n",
        };
        var out = std.ArrayList(u8).initCapacity(alloc, lines[0].len * lines.len) catch unreachable;
        out.appendSlice(alloc, lines[0]) catch unreachable;
        var bufs: [8][20]u8 = undefined;
        for (0..8) |rank| {
            const r: i8 = @intCast(7 - rank);
            const l = rank + 1;
            std.mem.copyForwards(u8, bufs[rank][0..lines[l].len], lines[l]);
            for (0..8) |file| {
                const f: i8 = @intCast(file);
                const piece = self.getPieceOnSquare(Square.fromFileAndRank(f, r));
                bufs[rank][file * 2 + 2] = piece.toChar();
            }
            out.appendSlice(alloc, bufs[rank][0..lines[l].len]) catch unreachable;
        }
        return out.items;
    }

    pub fn debugInternalBitboards(self: Board) void {
        std.debug.print("White King:   {b:0>64}\n", .{self.whiteKing});
        std.debug.print("White Queen:  {b:0>64}\n", .{self.whiteQueen});
        std.debug.print("White Rooks:  {b:0>64}\n", .{self.whiteRooks});
        std.debug.print("White Bishops:{b:0>64}\n", .{self.whiteBishops});
        std.debug.print("White Knights:{b:0>64}\n", .{self.whiteKnights});
        std.debug.print("White Pawns:  {b:0>64}\n", .{self.whitePawns});
        std.debug.print("Black King:   {b:0>64}\n", .{self.blackKing});
        std.debug.print("Black Queen:  {b:0>64}\n", .{self.blackQueen});
        std.debug.print("Black Rooks:  {b:0>64}\n", .{self.blackRooks});
        std.debug.print("Black Bishops:{b:0>64}\n", .{self.blackBishops});
        std.debug.print("Black Knights:{b:0>64}\n", .{self.blackKnights});
        std.debug.print("Black Pawns:  {b:0>64}\n", .{self.blackPawns});
        std.debug.print("White Squares:{b:0>64}\n", .{self.whiteSquares});
        std.debug.print("Black Squares:{b:0>64}\n", .{self.blackSquares});
        std.debug.print("Empty Squares:{b:0>64}\n", .{self.emptySquares});
    }
};

test "Board setBitboardBit" {
    std.debug.print("Testing setBitboardBit...\n", .{});
    var bb: bitboard = 0;
    bb = Board.setBitboardBit(bb, Square.E4);
    try std.testing.expectEqual(Square.squareBit(Square.E4), bb);
    // std.debug.print("bb after setting bit {d}: {b}\n", .{Square.E4, bb});
}

test "Board clearBitboardBit" {
    std.debug.print("Testing clearBitboardBit...\n", .{});
    var bb: bitboard = 0xFFFFFFFFFFFFFFFF;
    bb = Board.clearBitboardBit(bb, Square.E4);
    try std.testing.expectEqual(~Square.squareBit(Square.E4), bb);
    // std.debug.print("bb after clearing bit {d}: {b}\n", .{Square.E4, bb});
}

test "Board creation and piece placement" {
    std.debug.print("Create board and place pieces...\n", .{});
    var board = Board{};

    // Place a white king on e4
    const squareE4 = Square.fromFileAndRank(4, 3); // File E, Rank 4
    // std.debug.print("squareE4: {d}\n", .{squareE4.s});
    try board.placePiece(Piece.WhiteKing, squareE4);

    // Check if the white king is placed correctly
    const expectedBB: bitboard = Square.squareBit(Square.E4);
    // std.debug.print("White King bitboard: {b:0>64}, expected bitboard: {b:0>64}\n", .{board.whiteKing, expectedBB});
    try std.testing.expectEqual(expectedBB, board.whiteKing);
    // std.debug.print("White squares bitboard: {b:0>64}, expected bitboard: {b:0>64}\n", .{board.whiteSquares, expectedBB});
    try std.testing.expectEqual(expectedBB, board.whiteSquares);
    const expectedEmptyQuares: bitboard = 0xFFFFFFFFFFFFFFFF & ~expectedBB;
    // std.debug.print("Empty squares bitboard: {b:0>64}, expected bitboard: {b:0>64}\n", .{board.emptySquares, expectedEmptyQuares});
    try std.testing.expectEqual(expectedEmptyQuares, board.emptySquares);
}

test "Board getKingSquare" {
    std.debug.print("Testing Board getKingSquare...\n", .{});
    var board = Board{};

    // Place a white king on e1
    const e1 = Square.fromFileAndRank(Square.FileE, Square.Rank1);
    try board.placePiece(Piece.WhiteKing, e1);
    // std.debug.print("White King bitboard: {b:0>64}\n", .{board.whiteKing});
    const whiteKingSquare = board.getKingSquare(Colour.White);
    // std.debug.print("White King is on square: {s}\n", .{whiteKingSquare.toString()});
    try std.testing.expectEqual(true, whiteKingSquare.equals(e1));

    // Place a black king on e8
    const e8 = Square.fromFileAndRank(Square.FileE, Square.Rank8);
    try board.placePiece(Piece.BlackKing, e8);
    const blackKingSquare = board.getKingSquare(Colour.Black);
    try std.testing.expectEqual(true, blackKingSquare.equals(e8));
}

test "Board draw" {
    std.debug.print("Testing Board draw...\n", .{});
    var board = Board{};

    // Place some pieces
    try board.placePiece(Piece.WhiteKing, Square.fromFileAndRank(Square.FileE, Square.Rank4)); // E4
    try board.placePiece(Piece.BlackQueen, Square.fromFileAndRank(Square.FileD, Square.Rank6)); // D6
    try board.placePiece(Piece.WhiteRook, Square.fromFileAndRank(Square.FileA, Square.Rank1)); // A1

    const expected = "  A B C D E F G H\n"
        ++ "8                \n"
        ++ "7                \n"
        ++ "6       q        \n"
        ++ "5                \n"
        ++ "4         K      \n"
        ++ "3                \n"
        ++ "2                \n"
        ++ "1 R              \n";
    try std.testing.expectEqualStrings(expected, board.draw());
    // std.debug.print("{s}\n", .{board.draw()});
}