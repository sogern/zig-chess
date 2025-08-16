const std = @import("std");
const bitboard = @import("bitboard.zig").bitboard;
const Piece = @import("piece.zig").Piece;
const PieceError = @import("piece.zig").PieceError;
const Square = @import("square.zig").Square;

pub const BoardError = error{
    SquareOccupied,
};

pub const Board = packed struct {
    whiteKing: bitboard,
    whiteQueen: bitboard,
    whiteRooks: bitboard,
    whiteBishops: bitboard,
    whiteKnights: bitboard,
    whitePawns: bitboard,
    blackKing: bitboard,
    blackQueen: bitboard,
    blackRooks: bitboard,
    blackBishops: bitboard,
    blackKnights: bitboard,
    blackPawns: bitboard,
    whiteSquares: bitboard,  // all white pieces
    blackSquares: bitboard,  // all black pieces
    emptySquares: bitboard,

    pub fn create(alloc: std.mem.Allocator) !*Board {
        const board = try alloc.create(Board);
        reset(board);
        return board;
    }

    pub fn reset(self: *Board) void {
        self.* = Board{
            .whiteKing = 0,
            .whiteQueen = 0,
            .whiteRooks = 0,
            .whiteBishops = 0,
            .whiteKnights = 0,
            .whitePawns = 0,
            .blackKing = 0,
            .blackQueen = 0,
            .blackRooks = 0,
            .blackBishops = 0,
            .blackKnights = 0,
            .blackPawns = 0,
            .whiteSquares = 0,
            .blackSquares = 0,
            .emptySquares = 0xFFFFFFFFFFFFFFFF,
        };
    }

    pub fn getBBForPiece(self: *Board, p: Piece) !*bitboard {
        switch (p) {
            Piece.WhiteKing => return self.whiteKing.*,
            Piece.WhiteQueen => return self.whiteQueen.*,
            Piece.WhiteRook => return self.whiteRooks.*,
            Piece.WhiteBishop => return self.whiteBishops.*,
            Piece.WhiteKnight => return self.whiteKnights.*,
            Piece.WhitePawn => return self.whitePawns.*,
            Piece.BlackKing => return self.blackKing.*,
            Piece.BlackQueen => return self.blackQueen.*,
            Piece.BlackRook => return self.blackRooks.*,
            Piece.BlackBishop => return self.blackBishops.*,
            Piece.BlackKnight => return self.blackKnights.*,
            Piece.BlackPawn => return self.blackPawns.*,
            else => {
                return PieceError.InvalidPiece;
            },
        }
    }

    inline fn setBitboardBit(bb: *bitboard, s: i8) void {
        const bit: bitboard = (@as(bitboard, 1) << @intCast(s));
        bb.* |= bit;
    }

    inline fn clearBitboardBit(bb: *bitboard, s: i8) void {
        const bit: bitboard = (@as(bitboard, 1) << @intCast(s));
        bb.* &= ~bit;
    }

    pub inline fn isSquareOccupied(self: *Board, square: Square) bool {
        const bit: bitboard = (@as(bitboard, 1) << @intCast(square.s));
        return (self.whiteSquares & bit) != 0 or (self.blackSquares & bit) != 0;
    }

    pub inline fn isSquareEmpty(self: *Board, square: Square) bool {
        const bit: bitboard = (@as(bitboard, 1) << @intCast(square.s));
        return (self.emptySquares & bit) != 0;
    }

    pub fn getPieceOnSquare(self: *Board, square: Square) Piece {
        const bit: bitboard = (@as(bitboard, 1) << @intCast(square.s));
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
        return Piece.None; // No piece on the square
    }

    pub fn placePiece(self: *Board, p: Piece, square: Square) !void {
        if (self.isSquareOccupied(square)) {
            return BoardError.SquareOccupied;
        }

        var bit: bitboard = 0;
        setBitboardBit(&bit, square.s);
        // std.debug.print("piece: {c}, square: {s}, bit: {b}\n", .{p.toChar(), square.toString(), bit});

        if (p == Piece.WhiteKing) {
            self.whiteKing |= bit;
            self.whiteSquares |= bit;
        } else if (p == Piece.BlackKing) {
            self.blackKing |= bit;
            self.blackSquares |= bit;
        } else if (p == Piece.WhiteQueen) {
            self.whiteQueen |= bit;
            self.whiteSquares |= bit;
        } else if (p == Piece.BlackQueen) {
            self.blackQueen |= bit;
            self.blackSquares |= bit;
        } else if (p == Piece.WhiteRook) {
            self.whiteRooks |= bit;
            self.whiteSquares |= bit;
        } else if (p == Piece.BlackRook) {
            self.blackRooks |= bit;
            self.blackSquares |= bit;
        } else if (p == Piece.WhiteBishop) {
            self.whiteBishops |= bit;
            self.whiteSquares |= bit;
        } else if (p == Piece.BlackBishop) {
            self.blackBishops |= bit;
            self.blackSquares |= bit;
        } else if (p == Piece.WhiteKnight) {
            self.whiteKnights |= bit;
            self.whiteSquares |= bit;
        } else if (p == Piece.BlackKnight) {
            self.blackKnights |= bit;
            self.blackSquares |= bit;
        } else if (p == Piece.WhitePawn) {
            self.whitePawns |= bit;
            self.whiteSquares |= bit;
        } else if (p == Piece.BlackPawn) {
            self.blackPawns |= bit;
            self.blackSquares |= bit;
        } else {
            return PieceError.InvalidPiece;
        }

        clearBitboardBit(&self.emptySquares, square.s);
    }

    /// Returns a string representation of the board for debugging purposes.
    pub fn toDebugString(self: *Board) []const u8 {
        const alloc = std.heap.page_allocator;
        const lines = [_][]const u8{
            "  a b c d e f g h\n",
            "  ---------------\n",
            "8                \n",
            "7                \n",
            "6                \n",
            "5                \n",
            "4                \n",
            "3                \n",
            "2                \n",
            "1                \n",
            "  ---------------\n",
        };
        var out = std.ArrayList(u8).init(alloc);
        out.appendSlice(lines[0]) catch unreachable;
        out.appendSlice(lines[1]) catch unreachable;
        var bufs: [8][20]u8 = undefined;
        for (0..8) |rank| {
            const r: i8 = @intCast(7 - rank);
            const l = rank + 2;
            std.mem.copyForwards(u8, bufs[rank][0..lines[l].len], lines[l]);
            for (0..8) |file| {
                const f: i8 = @intCast(file);
                const piece = self.getPieceOnSquare(Square.fromFileAndRank(f, r));
                bufs[rank][file * 2 + 2] = piece.toChar();
            }
            out.appendSlice(bufs[rank][0..lines[l].len]) catch unreachable;
        }
        out.appendSlice(lines[lines.len-1]) catch unreachable;
        return out.items;
    }

    pub fn deinit(_: *Board) void {
    }
};

test "Board setBitboardBit" {
    std.debug.print("Testing setBitboardBit...\n", .{});
    var bb: bitboard = 0;
    Board.setBitboardBit(&bb, Square.E4);
    try std.testing.expect(bb == (@as(bitboard, 1) << Square.E4));
    // std.debug.print("bb after setting bit {d}: {b}\n", .{Square.E4, bb});
}

test "Board creation and piece placement" {
    std.debug.print("Create board and place pieces...\n", .{});
    const alloc = std.testing.allocator;
    const board = try Board.create(alloc);
    defer {
        board.deinit();
        alloc.destroy(board);
    }

    // Place a white king on e1 (square 60)
    const squareE4 = Square.fromFileAndRank(4, 3); // File E, Rank 4
    // std.debug.print("squareE1: {d}\n", .{squareE4.s});
    try board.placePiece(Piece.WhiteKing, squareE4);

    // Check if the white king is placed correctly
    const expectedBB: bitboard = (@as(bitboard, 1) << Square.E4);
    // std.debug.print("White King bitboard: {b}, expected bitboard: {b}\n", .{board.whiteKing, expectedBB});
    try std.testing.expect(board.whiteKing == expectedBB);
    // std.debug.print("White squares bitboard: {b}, expected bitboard: {b}\n", .{board.whiteSquares, expectedBB});
    try std.testing.expect(board.whiteSquares == expectedBB);
    const expectedEmptyQuares: bitboard = 0xFFFFFFFFFFFFFFFF & ~expectedBB;
    // std.debug.print("Empty squares bitboard: {b}, expected bitboard: {b}\n", .{board.emptySquares, expectedEmptyQuares});
    try std.testing.expect(board.emptySquares == expectedEmptyQuares);
}

test "Board toDebugString" {
    std.debug.print("Testing Board toDebugString...\n", .{});
    const alloc = std.testing.allocator;
    const board = try Board.create(alloc);
    defer {
        board.deinit();
        alloc.destroy(board);
    }

    // Place some pieces
    try board.placePiece(Piece.WhiteKing, Square.fromFileAndRank(4, 3)); // E4
    try board.placePiece(Piece.BlackQueen, Square.fromFileAndRank(3, 5)); // D6
    try board.placePiece(Piece.WhiteRook, Square.fromFileAndRank(0, 0)); // A1

    std.debug.print("{s}\n", .{board.toDebugString()});
}