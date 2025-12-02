const std = @import("std");
const bitboard = @import("bitboard.zig").bitboard;
const Piece = @import("piece.zig").Piece;
const CastlingRights = @import("castling.zig").CastlingRights;
const Colour = @import("piece.zig").Colour;
const PieceError = @import("piece.zig").PieceError;
const PieceType = @import("piece.zig").PieceType;
const newPiece = @import("piece.zig").newPiece;
const Square = @import("square.zig").Square;
const Move = @import("move.zig").Move;
const EnPassant = @import("move.zig").EnPassant;
const KingSideCastle = @import("move.zig").KingSideCastle;
const QueenSideCastle = @import("move.zig").QueenSideCastle;

pub const BoardError = error{
    SquareOccupied,
    SquareEmpty,
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
    whiteSquares: bitboard = 0, // all white pieces
    blackSquares: bitboard = 0, // all black pieces
    emptySquares: bitboard = 0xFFFFFFFFFFFFFFFF,

    pub fn getBBForPiece(self: *const Board, piece: Piece) !bitboard {
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

    pub fn setBBForPiece(self: *Board, piece: Piece, bb: bitboard) !void {
        switch (piece) {
            .WhiteKing => self.whiteKing = bb,
            .WhiteQueen => self.whiteQueen = bb,
            .WhiteRook => self.whiteRooks = bb,
            .WhiteBishop => self.whiteBishops = bb,
            .WhiteKnight => self.whiteKnights = bb,
            .WhitePawn => self.whitePawns = bb,
            .BlackKing => self.blackKing = bb,
            .BlackQueen => self.blackQueen = bb,
            .BlackRook => self.blackRooks = bb,
            .BlackBishop => self.blackBishops = bb,
            .BlackKnight => self.blackKnights = bb,
            .BlackPawn => self.blackPawns = bb,
            else => return PieceError.InvalidPiece,
        }
    }

    pub fn getBBForColour(self: *const Board, colour: Colour) bitboard {
        return switch (colour) {
            .White => self.whiteSquares,
            .Black => self.blackSquares,
            else => 0,
        };
    }

    fn calcConvenienceBBs(self: *Board) void {
        self.whiteSquares = self.whiteKing
            | self.whiteQueen
            | self.whiteRooks
            | self.whiteBishops
            | self.whiteKnights
            | self.whitePawns;
        self.blackSquares = self.blackKing
            | self.blackQueen
            | self.blackRooks
            | self.blackBishops
            | self.blackKnights
            | self.blackPawns;
        self.emptySquares = ~(self.whiteSquares | self.blackSquares);
    }

    inline fn setBitboardBit(bb: bitboard, s: i8) bitboard {
        return bb | Square.squareBit(@intCast(s));
    }

    inline fn clearBitboardBit(bb: bitboard, s: i8) bitboard {
        return bb & ~Square.squareBit(@intCast(s));
    }

    pub inline fn isSquareOccupied(self: Board, square: Square) bool {
        const bb: bitboard = square.getBitboard();
        return (self.whiteSquares & bb) != 0 or (self.blackSquares & bb) != 0;
    }

    pub inline fn isSquareEmpty(self: Board, square: Square) bool {
        const bb: bitboard = square.getBitboard();
        return (self.emptySquares & bb) != 0;
    }

    pub fn getPieceOnSquare(self: Board, square: Square) Piece {
        const bb: bitboard = square.getBitboard();
        if ((self.whiteSquares & bb) != 0) {
            if ((self.whiteKing & bb) != 0) return Piece.WhiteKing;
            if ((self.whiteQueen & bb) != 0) return Piece.WhiteQueen;
            if ((self.whiteRooks & bb) != 0) return Piece.WhiteRook;
            if ((self.whiteBishops & bb) != 0) return Piece.WhiteBishop;
            if ((self.whiteKnights & bb) != 0) return Piece.WhiteKnight;
            if ((self.whitePawns & bb) != 0) return Piece.WhitePawn;
        } else if ((self.blackSquares & bb) != 0) {
            if ((self.blackKing & bb) != 0) return Piece.BlackKing;
            if ((self.blackQueen & bb) != 0) return Piece.BlackQueen;
            if ((self.blackRooks & bb) != 0) return Piece.BlackRook;
            if ((self.blackBishops & bb) != 0) return Piece.BlackBishop;
            if ((self.blackKnights & bb) != 0) return Piece.BlackKnight;
            if ((self.blackPawns & bb) != 0) return Piece.BlackPawn;
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
        return switch (colour) {
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

    /// draw returns a string representation of the board.
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
            @memmove(bufs[rank][0..lines[l].len], lines[l]);
            for (0..8) |file| {
                const f: i8 = @intCast(file);
                const piece = self.getPieceOnSquare(Square.fromFileAndRank(f, r));
                bufs[rank][file * 2 + 2] = piece.toChar();
            }
            out.appendSlice(alloc, bufs[rank][0..lines[l].len]) catch unreachable;
        }
        return out.items;
    }

    pub fn internalBitboards(self: Board) []const u8 {
        const alloc = std.heap.page_allocator;
        var out = std.ArrayList(u8).initCapacity(alloc, (15 + 64) * 15) catch unreachable;
        var buffer: [100]u8 = undefined;
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "White King:   {b:0>64}\n", .{self.whiteKing}) catch unreachable) catch unreachable;
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "White Queen:  {b:0>64}\n", .{self.whiteQueen}) catch unreachable) catch unreachable;
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "White Rooks:  {b:0>64}\n", .{self.whiteRooks}) catch unreachable) catch unreachable;
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "White Bishops:{b:0>64}\n", .{self.whiteBishops}) catch unreachable) catch unreachable;
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "White Knights:{b:0>64}\n", .{self.whiteKnights}) catch unreachable) catch unreachable;
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "White Pawns:  {b:0>64}\n", .{self.whitePawns}) catch unreachable) catch unreachable;
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "Black King:   {b:0>64}\n", .{self.blackKing}) catch unreachable) catch unreachable;
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "Black Queen:  {b:0>64}\n", .{self.blackQueen}) catch unreachable) catch unreachable;
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "Black Rooks:  {b:0>64}\n", .{self.blackRooks}) catch unreachable) catch unreachable;
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "Black Bishops:{b:0>64}\n", .{self.blackBishops}) catch unreachable) catch unreachable;
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "Black Knights:{b:0>64}\n", .{self.blackKnights}) catch unreachable) catch unreachable;
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "Black Pawns:  {b:0>64}\n", .{self.blackPawns}) catch unreachable) catch unreachable;
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "White Squares:{b:0>64}\n", .{self.whiteSquares}) catch unreachable) catch unreachable;
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "Black Squares:{b:0>64}\n", .{self.blackSquares}) catch unreachable) catch unreachable;
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "Empty Squares:{b:0>64}\n", .{self.emptySquares}) catch unreachable) catch unreachable;
        return out.items;
    }

    /// toFEN returns the board in Forsyth-Edwards Notation.
    pub fn toFEN(self: Board) []const u8 {
        const alloc = std.heap.page_allocator;

        const maxRankValue = 7;
        const numFiles = 8;

        // 71 is the theoretical maximum length of the piece placement part of a FEN string
        var fen = std.ArrayList(u8).initCapacity(alloc, 8 * 8 + 7) catch unreachable;
        var emptyCount: u8 = 0;

        for (0..8) |r_| {
            const r = maxRankValue - r_;
            // Add rank separator except for first rank
            if (r < maxRankValue) {
                fen.append(alloc, '/') catch unreachable;
            }

            // Process each file in the rank
            for (0..numFiles) |f| {
                const sq = Square.fromFileAndRank(@as(i8, @intCast(f)), @as(i8, @intCast(r)));
                const p = self.getPieceOnSquare(sq);

                if (p == Piece.None) {
                    emptyCount += 1;
                    continue;
                }

                // If we had empty squares before, append the count
                if (emptyCount > 0) {
                    fen.append(alloc, @as(u8, '0' + emptyCount)) catch unreachable;
                    emptyCount = 0;
                }

                fen.append(alloc, p.toChar()) catch unreachable;
            }

            // If there are trailing empty squares, append the count
            if (emptyCount > 0) {
                fen.append(alloc, @as(u8, '0' + emptyCount)) catch unreachable;
                emptyCount = 0;
            }
        }

        return fen.items;
    }

    pub fn update(self: *Board, m: Move, cr: CastlingRights) !void {
        const p1 = self.getPieceOnSquare(m.s1);
        if (p1 == Piece.None) {
            return BoardError.SquareEmpty;
        }
        const p2 = self.getPieceOnSquare(m.s2);
        const s2bitmask = m.s2.getBitboard();

        // Move piece from s1 to s2
        if (p2 != Piece.None) {
            // Remove what was on s2
            const p2BB = try self.getBBForPiece(p2);
            try self.setBBForPiece(p2, p2BB & ~s2bitmask);
        }

        // Move what was on s1 to s2
        const s1bitmask = m.s1.getBitboard();
        const p1BB_ = try self.getBBForPiece(p1);
        try self.setBBForPiece(p1, (p1BB_ & ~s1bitmask) | s2bitmask);

        // Check promotion
        if (m.promotion != PieceType.None) {
            const promoPiece = newPiece(m.promotion, p1.colour());
            const p1BB = try self.getBBForPiece(p1);
            try self.setBBForPiece(p1, p1BB & ~s2bitmask); // Remove the piece being promoted
            const promoBB = try self.getBBForPiece(promoPiece);
            try self.setBBForPiece(promoPiece, promoBB | s2bitmask); // Place the promoted piece
        }

        // Remove captured en passant piece
        if (m.hasTag(EnPassant)) {
            const epBitmask = m.s2.getBitboard();
            if (p1.colour() == .White) {
                self.blackPawns &= ~(epBitmask << 8);
            } else {
                self.whitePawns &= ~(epBitmask >> 8);
            }
        }

        // Move rook for castling
        if (m.hasTag(KingSideCastle)) {
            switch (p1.colour()) {
                .White => {
                    self.whiteRooks = (self.whiteRooks & ~cr.whiteKingSideRookSquare().getBitboard()) | Square.squareBit(Square.F1);
                },
                .Black => {
                    self.blackRooks = (self.blackRooks & ~cr.blackKingSideRookSquare().getBitboard()) | Square.squareBit(Square.F8);
                },
                .None => {
                }
            }
        } else if (m.hasTag(QueenSideCastle)) {
            switch (p1.colour()) {
                .White => {
                    self.whiteRooks = (self.whiteRooks & ~cr.whiteQueenSideRookSquare().getBitboard()) | Square.squareBit(Square.D1);
                },
                .Black => {
                    self.blackRooks = (self.blackRooks & ~cr.blackQueenSideRookSquare().getBitboard()) | Square.squareBit(Square.D8);
                },
                .None => {
                }
            }
        }

        self.calcConvenienceBBs();
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

test "Board toFEN" {
    std.debug.print("Testing Board toFEN...\n", .{});
    var board = Board{};

    // Place pieces to form the starting position
    // White pieces
    try board.placePiece(Piece.WhiteRook, Square.fromFileAndRank(Square.FileA, Square.Rank1));
    try board.placePiece(Piece.WhiteKnight, Square.fromFileAndRank(Square.FileB, Square.Rank1));
    try board.placePiece(Piece.WhiteBishop, Square.fromFileAndRank(Square.FileC, Square.Rank1));
    try board.placePiece(Piece.WhiteQueen, Square.fromFileAndRank(Square.FileD, Square.Rank1));
    try board.placePiece(Piece.WhiteKing, Square.fromFileAndRank(Square.FileE, Square.Rank1));
    try board.placePiece(Piece.WhiteBishop, Square.fromFileAndRank(Square.FileF, Square.Rank1));
    try board.placePiece(Piece.WhiteKnight, Square.fromFileAndRank(Square.FileG, Square.Rank1));
    try board.placePiece(Piece.WhiteRook, Square.fromFileAndRank(Square.FileH, Square.Rank1));
    for (0..8) |f_| {
        const f = @as(i8, @intCast(f_));
        try board.placePiece(Piece.WhitePawn, Square.fromFileAndRank(f, Square.Rank2));
    }

    // Black pieces
    try board.placePiece(Piece.BlackRook, Square.fromFileAndRank(Square.FileA, Square.Rank8));
    try board.placePiece(Piece.BlackKnight, Square.fromFileAndRank(Square.FileB, Square.Rank8));
    try board.placePiece(Piece.BlackBishop, Square.fromFileAndRank(Square.FileC, Square.Rank8));
    try board.placePiece(Piece.BlackQueen, Square.fromFileAndRank(Square.FileD, Square.Rank8));
    try board.placePiece(Piece.BlackKing, Square.fromFileAndRank(Square.FileE, Square.Rank8));
    try board.placePiece(Piece.BlackBishop, Square.fromFileAndRank(Square.FileF, Square.Rank8));
    try board.placePiece(Piece.BlackKnight, Square.fromFileAndRank(Square.FileG, Square.Rank8));
    try board.placePiece(Piece.BlackRook, Square.fromFileAndRank(Square.FileH, Square.Rank8));
    for (0..8) |f_| {
        const f = @as(i8, @intCast(f_));
        try board.placePiece(Piece.BlackPawn, Square.fromFileAndRank(f, Square.Rank7));
    }
    // std.debug.print("Board:\n{s}\n", .{board.draw()});
    const fen = board.toFEN();
    const expected_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR";
    // std.debug.print("FEN: {s}\n", .{fen});
    try std.testing.expectEqualStrings(expected_fen, fen);
}
