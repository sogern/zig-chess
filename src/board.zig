const std = @import("std");
const bitboard = @import("bitboard.zig").bitboard;
const Piece = @import("piece.zig").Piece;
const CastlingRights = @import("castling.zig");
const Colour = @import("piece.zig").Colour;
const PieceError = @import("piece.zig").PieceError;
const PieceType = @import("piece.zig").PieceType;
const Square = @import("square.zig").Square;
const File = @import("file.zig").File;
const Rank = @import("rank.zig").Rank;
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
    emptySquares: bitboard = 0xFFFF_FFFF_FFFF_FFFF,

    pub fn getBBForPiece(self: @This(), piece: Piece) !bitboard {
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

    pub fn setBBForPiece(self: *@This(), piece: Piece, bb: bitboard) !void {
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

    pub fn getBBForColour(self: @This(), colour: Colour) bitboard {
        return switch (colour) {
            .White => self.whiteSquares,
            .Black => self.blackSquares,
            else => 0,
        };
    }

    fn calcConvenienceBBs(self: *@This()) void {
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

    inline fn setBitboardBit(bb: bitboard, s: Square) bitboard {
        return bb | s.bitmask();
    }

    test setBitboardBit {
        var bb: bitboard = 0;
        bb = Board.setBitboardBit(bb, Square.E4);
        try std.testing.expectEqual(Square.E4.bitmask(), bb);
    }

    inline fn clearBitboardBit(bb: bitboard, s: Square) bitboard {
        return bb & ~s.bitmask();
    }

    test clearBitboardBit {
        const bb = Board.clearBitboardBit(0xFFFF_FFFF_FFFF_FFFF, .E4);
        try std.testing.expectEqual(~Square.E4.bitmask(), bb);
    }

    pub inline fn isSquareOccupied(self: @This(), square: Square) bool {
        const bb: bitboard = square.bitmask();
        return (self.whiteSquares & bb) != 0 or (self.blackSquares & bb) != 0;
    }

    pub inline fn isSquareEmpty(self: @This(), square: Square) bool {
        const bb: bitboard = square.bitmask();
        return (self.emptySquares & bb) != 0;
    }

    pub fn getPieceOnSquare(self: @This(), square: Square) Piece {
        const bb: bitboard = square.bitmask();
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

    pub fn placePiece(self: *@This(), p: Piece, square: Square) !void {
        if (self.isSquareOccupied(square)) {
            return BoardError.SquareOccupied;
        }
        const bit: bitboard = setBitboardBit(0, square);
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
            .None => return PieceError.InvalidPiece,
        }
        self.emptySquares = clearBitboardBit(self.emptySquares, square);
    }

    pub fn getKingSquare(self: @This(), colour: Colour) Square {
        return switch (colour) {
            .White => {
                if (self.whiteKing == 0) return .None;
                return Square.fromIndex(@clz(self.whiteKing));
            },
            .Black => {
                if (self.blackKing == 0) return .None;
                return Square.fromIndex(@clz(self.blackKing));
            },
            .None => .None,
        };
    }

    test getKingSquare {
        var board: Board = .{};

        // Place a white king on e1
        const e1 = Square.fromFileAndRank(.E, .@"1");
        try board.placePiece(.WhiteKing, e1);
        const whiteKingSquare = board.getKingSquare(.White);
        try std.testing.expectEqual(e1, whiteKingSquare);

        // Place a black king on e8
        const e8 = Square.fromFileAndRank(.E, .@"8");
        try board.placePiece(.BlackKing, e8);
        const blackKingSquare = board.getKingSquare(.Black);
        try std.testing.expectEqual(e8, blackKingSquare);
    }

    /// Returns a human-readable representation of the board.
    /// Caller owns the returned string.
    pub fn draw(self: @This(), alloc: std.mem.Allocator) []const u8 {
        const lines = [_][]const u8{
            "  a b c d e f g h\n",
            "8                \n",
            "7                \n",
            "6                \n",
            "5                \n",
            "4                \n",
            "3                \n",
            "2                \n",
            "1                \n",
        };
        var out = std.ArrayList(u8).initCapacity(alloc, lines[0].len * lines.len) catch @panic("OOM");
        out.appendSlice(alloc, lines[0]) catch @panic("OOM");
        for (0..8) |rank| {
            var buf:[20]u8 = undefined;
            const r = 7 - rank;
            const l = rank + 1;
            @memcpy(buf[0..lines[l].len], lines[l]);
            for (0..8) |f| {
                const piece = self.getPieceOnSquare(Square.fromIndex(((r * 8) + f)));
                buf[f * 2 + 2] = piece.char();
            }
            out.appendSlice(alloc, buf[0..lines[l].len]) catch @panic("OOM");
        }
        return out.toOwnedSlice(alloc) catch @panic("OOM");
    }

    test draw {
        const alloc = std.testing.allocator;
        var board: @This() = .{};

        // Place some pieces
        try board.placePiece(.WhiteKing, .E4);
        try board.placePiece(.BlackQueen, .D6);
        try board.placePiece(.WhiteRook, .A1);

        const expected = "  a b c d e f g h\n"
            ++ "8                \n"
            ++ "7                \n"
            ++ "6       q        \n"
            ++ "5                \n"
            ++ "4         K      \n"
            ++ "3                \n"
            ++ "2                \n"
            ++ "1 R              \n";
        const board_str = board.draw(alloc);
        defer alloc.free(board_str);
        try std.testing.expectEqualStrings(expected, board_str);
    }

    pub fn internalBitboards(self: @This(), alloc: std.mem.Allocator) []const u8 {
        var out = std.ArrayList(u8).initCapacity(alloc, (15 + 64) * 15) catch @panic("OOM");
        var buffer: [100]u8 = undefined;
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "White King:   {b:0>64}\n", .{self.whiteKing}) catch unreachable) catch @panic("OOM");
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "White Queen:  {b:0>64}\n", .{self.whiteQueen}) catch unreachable) catch @panic("OOM");
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "White Rooks:  {b:0>64}\n", .{self.whiteRooks}) catch unreachable) catch @panic("OOM");
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "White Bishops:{b:0>64}\n", .{self.whiteBishops}) catch unreachable) catch @panic("OOM");
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "White Knights:{b:0>64}\n", .{self.whiteKnights}) catch unreachable) catch @panic("OOM");
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "White Pawns:  {b:0>64}\n", .{self.whitePawns}) catch unreachable) catch @panic("OOM");
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "Black King:   {b:0>64}\n", .{self.blackKing}) catch unreachable) catch @panic("OOM");
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "Black Queen:  {b:0>64}\n", .{self.blackQueen}) catch unreachable) catch @panic("OOM");
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "Black Rooks:  {b:0>64}\n", .{self.blackRooks}) catch unreachable) catch @panic("OOM");
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "Black Bishops:{b:0>64}\n", .{self.blackBishops}) catch unreachable) catch @panic("OOM");
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "Black Knights:{b:0>64}\n", .{self.blackKnights}) catch unreachable) catch @panic("OOM");
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "Black Pawns:  {b:0>64}\n", .{self.blackPawns}) catch unreachable) catch @panic("OOM");
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "White Squares:{b:0>64}\n", .{self.whiteSquares}) catch unreachable) catch @panic("OOM");
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "Black Squares:{b:0>64}\n", .{self.blackSquares}) catch unreachable) catch @panic("OOM");
        out.appendSlice(alloc, std.fmt.bufPrint(&buffer, "Empty Squares:{b:0>64}\n", .{self.emptySquares}) catch unreachable) catch @panic("OOM");
        return out.toOwnedSlice(alloc) catch @panic("OOM");
    }

    /// Returns the board in Forsyth-Edwards Notation.
    /// Caller owns the returned string.
    pub fn fen(self: @This(), alloc: std.mem.Allocator) []const u8 {
        // 71 is the theoretical maximum length of the piece placement part of a FEN string
        var out = std.ArrayList(u8).initCapacity(alloc, 8 * 8 + 7) catch @panic("OOM");
        var emptyCount: u8 = 0;

        for (0..8) |rank| {
            const r = 7 - rank;
            // Add rank separator except for first rank
            if (r < 7) {
                out.append(alloc, '/') catch @panic("OOM");
            }

            // Process each file in the rank
            for (0..8) |f| {
                const sq = Square.fromIndex(((r * 8) + f));
                const p = self.getPieceOnSquare(sq);

                if (p == Piece.None) {
                    emptyCount += 1;
                    continue;
                }

                // If we had empty squares before, append the count
                if (emptyCount > 0) {
                    out.append(alloc, '0' + emptyCount) catch @panic("OOM");
                    emptyCount = 0;
                }

                out.append(alloc, p.char()) catch @panic("OOM");
            }

            // If there are trailing empty squares, append the count
            if (emptyCount > 0) {
                out.append(alloc, '0' + emptyCount) catch @panic("OOM");
                emptyCount = 0;
            }
        }
        return out.toOwnedSlice(alloc) catch @panic("OOM");
    }

    test fen {
        const alloc = std.testing.allocator;
        var board: @This() = .{};

        // Place pieces to form the starting position
        // White pieces
        try board.placePiece(.WhiteRook, .A1);
        try board.placePiece(.WhiteKnight, .B1);
        try board.placePiece(.WhiteBishop, .C1);
        try board.placePiece(.WhiteQueen, .D1);
        try board.placePiece(.WhiteKing, .E1);
        try board.placePiece(.WhiteBishop, .F1);
        try board.placePiece(.WhiteKnight, .G1);
        try board.placePiece(.WhiteRook, .H1);
        for (0..8) |f| {
            try board.placePiece(.WhitePawn, Square.fromFileAndRank(File.fromIndex(f), .@"2"));
        }
        // Black pieces
        try board.placePiece(.BlackRook, .A8);
        try board.placePiece(.BlackKnight, .B8);
        try board.placePiece(.BlackBishop, .C8);
        try board.placePiece(.BlackQueen, .D8);
        try board.placePiece(.BlackKing, .E8);
        try board.placePiece(.BlackBishop, .F8);
        try board.placePiece(.BlackKnight, .G8);
        try board.placePiece(.BlackRook, .H8);
        for (0..8) |f| {
            try board.placePiece(.BlackPawn, Square.fromFileAndRank(File.fromIndex(f), .@"7"));
        }
        const fenStr = board.fen(alloc);
        defer alloc.free(fenStr);
        const expected_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR";
        try std.testing.expectEqualStrings(expected_fen, fenStr);
    }

    pub fn update(self: *@This(), m: Move, cr: CastlingRights) !void {
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
            const promoPiece = Piece.fromTypeAndColour(m.promotion, p1.colour());
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
                .None => {}
            }
        } else if (m.hasTag(QueenSideCastle)) {
            switch (p1.colour()) {
                .White => {
                    self.whiteRooks = (self.whiteRooks & ~cr.whiteQueenSideRookSquare().getBitboard()) | Square.squareBit(Square.D1);
                },
                .Black => {
                    self.blackRooks = (self.blackRooks & ~cr.blackQueenSideRookSquare().getBitboard()) | Square.squareBit(Square.D8);
                },
                .None => {}
            }
        }
        self.calcConvenienceBBs();
    }
};

test "Board creation and piece placement" {
    var board: Board = .{};

    // Place a white king on e4
    try board.placePiece(.WhiteKing, .E4);

    // Check if the white king is placed correctly
    const expectedBB: bitboard = Square.E4.bitmask();
    try std.testing.expectEqual(expectedBB, board.whiteKing);
    try std.testing.expectEqual(expectedBB, board.whiteSquares);
    const expectedEmptyQuares: bitboard = 0xFFFF_FFFF_FFFF_FFFF & ~expectedBB;
    try std.testing.expectEqual(expectedEmptyQuares, board.emptySquares);
}

test {
    @import("std").testing.refAllDecls(@This());
}