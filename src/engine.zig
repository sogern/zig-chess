const std = @import("std");
const Position = @import("position.zig").Position;
const decodeFEN = @import("fen.zig").decodeFEN;
const bitboard = @import("bitboard.zig").bitboard;
const bbKnightMoves = @import("bitboard.zig").bbKnightMoves;
const bbKingMoves = @import("bitboard.zig").bbKingMoves;
const bbDiagonals = @import("bitboard.zig").bbDiagonals;
const bbAntiDiagonals = @import("bitboard.zig").bbAntiDiagonals;
const bbFileH = @import("bitboard.zig").bbFileH;
const bbFileA = @import("bitboard.zig").bbFileA;
const bbRank8 = @import("bitboard.zig").bbRank8;
const bbRank6 = @import("bitboard.zig").bbRank6;
const bbRank3 = @import("bitboard.zig").bbRank3;
const bbRank1 = @import("bitboard.zig").bbRank1;
const bbRanks = @import("bitboard.zig").bbRanks;
const bbFiles = @import("bitboard.zig").bbFiles;
const Board = @import("board.zig").Board;
const Colour = @import("piece.zig").Colour;
const CastlingRights = @import("castling.zig");
const Square = @import("square.zig").Square;
const Move = @import("move.zig").Move;
const KingSideCastle = @import("move.zig").KingSideCastle;
const QueenSideCastle = @import("move.zig").QueenSideCastle;
const Capture = @import("move.zig").Capture;
const EnPassant = @import("move.zig").EnPassant;
const Check = @import("move.zig").Check;
const InCheck = @import("move.zig").InCheck;
const Piece = @import("piece.zig").Piece;
const newPiece = @import("piece.zig").newPiece;
const PieceType = @import("piece.zig").PieceType;
const Method = @import("game.zig").Method;
const numSquaresOnBoard = Square.numSquaresOnBoard;
const maxPossibleMoves = 218; // Maximum possible legal moves in any chess position
const promoPieceTypes = [_]PieceType{ .Queen, .Rook, .Bishop, .Knight };

const Engine = struct {

    /// calcMoves generates all legal moves for the given position.
    /// If first is true, returns after finding the first legal move.
    /// Useful for quick position validation.
    /// 
    /// The moves are generated in the following order:
    /// 1. Standard moves and captures
    /// 2. Castling moves (if available)
    /// 
    /// Each move is validated to ensure it does not leave the king in check.
    pub fn calcMoves(pos: *const Position, first: bool) []Move {
        const sm = standardMoves(pos, first);
        const cm = castlingMoves(pos);
        return sm ++ cm;
    }

    /// status returns the current game status based on the position.
    /// 
    /// The status is determined by:
    /// - Whether the side to move is in check
    /// - Whether any legal moves exist
    /// 
    /// If the position has cached valid moves, those are used.
    /// Otherwise, moves are calculated to determine the status.
    pub fn status(pos: *const Position) Method {
        var hasMove: bool = false;
        if (pos.hasValidMoves()) {
            hasMove = true;
        } else {
            hasMove = calcMoves(pos, true).len > 0;
        }
        if (!pos.inCheck and !hasMove) {
            return .Stalemate;
        } else if (pos.inCheck and !hasMove) {
            return .Checkmate;
        }
        return .NoMethod;
    }

    /// standardMoves generates all standard (non-castling) legal moves for the given position.
    /// If first is true, returns after finding the first move.
    fn standardMoves(pos: *const Position, first: bool) []Move {
        // TODO: Use memory pool for Move allocations
        const alloc = std.heap.page_allocator;
        var moves = try std.ArrayList(Move).initCapacity(alloc, maxPossibleMoves);
        // var count = 0;
        var m = Move{};

        var bbAllowed = ~pos.board.whiteSquares;
        if (pos.turn == .Black) {
            bbAllowed = ~pos.board.blackSquares;
        }

        inline for (@typeInfo(Piece).@"enum".fields) |f| {
            const p: Piece = f.value;
            // std.debug.print("yay {c}", .{p.toChar()});
            if (pos.turn != p.colour()) continue;

            const pBB = try pos.board.getBBForPiece(p);
            if (pBB == 0) continue;

            for (0..numSquaresOnBoard) |i| {
                const s1 = Square.fromIndex(@as(i8, @intCast(i)));
                if (pBB & s1.getBitboard() == 0) continue;

                const s2BB = bbForPossibleMoves(pos, p.@"type"(), s1) & bbAllowed;
                if (s2BB == 0) continue;

                for (0..numSquaresOnBoard) |j| {
                    const s2 = Square.fromIndex(@as(i8, @intCast(j)));
                    if (s2BB & s2.getBitboard() == 0) continue;

                    // Reuse m to avoid allocations
                    m.s1 = s1;
                    m.s2 = s2;
                    m.tags = 0;

                    if ((p == .WhitePawn and s2.r == Square.Rank8) or
                        (p == .BlackPawn and s2.r == Square.Rank1)) {
                        for (promoPieceTypes) |pt| {
                            m.promotion = pt;
                            addTags(&m, pos); // TODO: Why addTags here, and not before for loop?
                            if (!m.hasTag(InCheck)) {
                                try moves.append(m);
                                // count += 1;
                                if (first) {
                                    return moves.toOwnedSlice();
                                }
                            }
                        }
                    } else {
                        m.promotion = PieceType.None;
                        addTags(&m, pos);
                        if (!m.hasTag(InCheck)) {
                            try moves.append(m);
                            // count += 1;
                            if (first) {
                                return moves.toOwnedSlice();
                            }
                        }
                    }
                }
            }
        }

        return moves.toOwnedSlice();
    }

    /// addTags updates a move's tags based on the resulting position.
    fn addTags(m: *Move, pos: *const Position) !void {
        std.debug.print("Evaluating move {s}->{s}\n", .{m.s1.toString(), m.s2.toString()});
        const p: Piece = pos.board.getPieceOnSquare(m.s1);
        if (pos.board.isSquareOccupied(m.s2)) {
            std.debug.print("Capture detected on move {s}->{s}\n", .{m.s1.toString(), m.s2.toString()});
            m.addTag(Capture);
        } else if (m.s2.equals(pos.enPassantSquare) and p.@"type"() == .Pawn) {
            std.debug.print("En Passant detected on move {s}->{s}\n", .{m.s1.toString(), m.s2.toString()});
            m.addTag(EnPassant);
        }

        // Determine if move is castling
        if ((p == .WhiteKing and (m.s1.r == Square.Rank1 and m.s1.f == pos.castling.kingFile)) or
            (p == .BlackKing and (m.s1.r == Square.Rank8 and m.s1.f == pos.castling.kingFile))) {
            std.debug.print("King move detected for castling check on move {s}->{s}\n", .{m.s1.toString(), m.s2.toString()});
            if (m.s2.equals(Square.SqG1) or 
                m.s2.equals(Square.SqG8)) {
                std.debug.print("King Side Castle detected on move {s}->{s}\n", .{m.s1.toString(), m.s2.toString()});
                m.addTag(KingSideCastle);
            } else if (
                m.s2.equals(Square.SqC1) or
                m.s2.equals(Square.SqC8)) {
                std.debug.print("Queen Side Castle detected on move {s}->{s}\n", .{m.s1.toString(), m.s2.toString()});
                m.addTag(QueenSideCastle);
            }
        }
        
        // Determine if in check after move (makes move invalid)
        var cp: Position = pos.copy(); // Copy position
        try cp.board.update(m.*, cp.castling);
        std.debug.print("Position after move:\n{s}", .{cp.toString()});
        if (try isInCheck(&cp)) {
            std.debug.print("Move {s}->{s} results in self check\n", .{m.s1.toString(), m.s2.toString()});
            m.addTag(InCheck);
        }
        // Determine if opponent is in check after move
        cp.turn = cp.turn.opposite();
        if (try isInCheck(&cp)) {
            std.debug.print("Move {s}->{s} puts opponent in check\n", .{m.s1.toString(), m.s2.toString()});
            m.addTag(Check); // Reuse Capture tag to indicate check to opponent
        }
    }

    /// isInCheck determines if the side to move is in check in the given position.
    fn isInCheck(pos: *const Position) !bool {
        var kingSquare = pos.board.getKingSquare(.White);
        if (pos.turn == .Black) {
            kingSquare = pos.board.getKingSquare(.Black);
        }
        // King should only be missing in tests / examples
        if (kingSquare.equals(Square.None)) {
            return false;
        }
        return squaresAreAttacked(pos, &[_]Square{kingSquare});
    }

    /// squaresAreAttacked returns true if any of the given squares are attacked
    /// by the opponent in the given position.
    /// 
    /// The function checks attacks from:
    /// - Sliding pieces (queen, rook, bishop)
    /// - Knights
    /// - Pawns
    /// - King  
    fn squaresAreAttacked(pos: *const Position, sqs: []const Square) !bool {
        const oppositeColour = pos.turn.opposite();
        const occupied = ~pos.board.emptySquares;
        for (sqs) |sq| {
            // Quick check to see if attack vector is possible
            const oppositeBB = pos.board.getBBForColour(oppositeColour);
            if ((diaAttack(occupied, sq) | hvAttack(occupied, sq)) & oppositeBB | (bbKnightMoves[@as(usize, @intCast(sq.s))] & oppositeBB) == 0) {
                continue;
            }

            // Check queen attack vector
            const queenBB = try pos.board.getBBForPiece(newPiece(.Queen, oppositeColour));
            var bb = (diaAttack(occupied, sq) | hvAttack(occupied, sq)) & queenBB;
            if (bb != 0) {
                return true;
            }
            // Check rook attack vector
            const rookBB = try pos.board.getBBForPiece(newPiece(.Rook, oppositeColour));
            bb = hvAttack(occupied, sq) & rookBB;
            if (bb != 0) {
                return true;
            }
            // Check bishop attack vector
            const bishopBB = try pos.board.getBBForPiece(newPiece(.Bishop, oppositeColour));
            bb = diaAttack(occupied, sq) & bishopBB;
            if (bb != 0) {
                return true;
            }
            // Check knight attack vector
            const knightBB = try pos.board.getBBForPiece(newPiece(.Knight, oppositeColour));
            bb = bbKnightMoves[@as(usize, @intCast(sq.s))] & knightBB;
            if (bb != 0) {
                return true;
            }
            // Check pawn attack vector
            if (pos.turn == .White) {
                const capRight = (pos.board.blackPawns & ~bbFileH & ~bbRank1) << 7;
                const capLeft = (pos.board.blackPawns & ~bbFileA & ~bbRank1) << 9;
                bb = (capRight | capLeft) & sq.getBitboard();
                if (bb != 0) {
                    return true;
                }
            } else {
                const capRight = (pos.board.whitePawns & ~bbFileH & ~bbRank8) >> 9;
                const capLeft = (pos.board.whitePawns & ~bbFileA & ~bbRank8) >> 7;
                bb = (capRight | capLeft) & sq.getBitboard();
                if (bb != 0) {
                    return true;
                }
            }
            // Check king attack vector
            const kingBB = try pos.board.getBBForPiece(newPiece(.King, oppositeColour));
            bb = bbKingMoves[@as(usize, @intCast(sq.s))] & kingBB;
            if (bb != 0) {
                return true;
            }
        }
        return false;
    }

    /// bbForPossibleMoves returns a bitboard of target squares the piece of the given type can potentially move,
    /// without considering whether the moves are legal (e.g., leaving the king in check).
    fn bbForPossibleMoves(pos: *const Position, pt: PieceType, sq: Square) bitboard {
        return switch (pt) {
            .Pawn => pawnMoves(pos, sq),
            .Knight => bbKnightMoves[sq.s],
            .Bishop => diaAttack(~pos.board.emptySquares, sq),
            .Rook => hvAttack(~pos.board.emptySquares, sq),
            .Queen => diaAttack(~pos.board.emptySquares, sq) | hvAttack(~pos.board.emptySquares, sq),
            .King => bbKingMoves[sq.s],
            .None => 0,
        };
    }

    /// pawnMoves returns a bitboard of possible moves for a pawn on the given square in the given position.
    /// The function considers single and double forward moves, as well as diagonal and en passant captures.
    fn pawnMoves(pos: *const Position, sq: Square) bitboard {
        const sqBB = sq.getBitboard();
        const bbEnPassant: bitboard = pos.enPassantSquare.getBitboard();
        if (pos.turn == .White) {
            const capRight = ((sqBB & ~bbFileH & ~bbRank8) >> 9) & (pos.board.blackSquares | bbEnPassant);
            const capLeft = ((sqBB & ~bbFileA & ~bbRank8) >> 7) & (pos.board.blackSquares | bbEnPassant);
            const oneStep = ((sqBB & ~bbRank8) >> 8) & pos.board.emptySquares;
            const twoStep = ((oneStep & bbRank3) >> 8) & pos.board.emptySquares;
            return capRight | capLeft | oneStep | twoStep;
        } else {
            const capRight = ((sqBB & ~bbFileH & ~bbRank1) << 7) & (pos.board.whiteSquares | bbEnPassant);
            const capLeft = ((sqBB & ~bbFileA & ~bbRank1) << 9) & (pos.board.whiteSquares | bbEnPassant);
            const oneStep = ((sqBB & ~bbRank1) << 8) & pos.board.emptySquares;
            const twoStep = ((oneStep & bbRank6) << 8) & pos.board.emptySquares;
            return capRight | capLeft | oneStep | twoStep;
        }
    }

    /// diaAttack returns a bitboard of possible diagonal moves
    /// for a sliding piece, considering occupied squares as blocking further movement.
    fn diaAttack(occupied: bitboard, sq: Square) bitboard {
        const sqBB = sq.getBitboard();
        const dMask = bbDiagonals[@as(usize, @intCast(sq.s))];
        const adMask = bbAntiDiagonals[@as(usize, @intCast(sq.s))];
        return linearAttack(occupied, sqBB, dMask) | linearAttack(occupied, sqBB, adMask);
    }

    /// hvAttack returns a bitboard of possible horizontal and vertical moves
    /// for a sliding piece, considering occupied squares as blocking further movement.
    fn hvAttack(occupied: bitboard, sq: Square) bitboard {
        const sqBB = sq.getBitboard();
        const rankMask = bbRanks[(@as(usize, @intCast(sq.r)))];
        const fileMask = bbFiles[@as(usize, @intCast(sq.f))];
        return linearAttack(occupied, sqBB, rankMask) | linearAttack(occupied, sqBB, fileMask);
    }

    /// linearAttack returns a bitboard of possible moves
    /// in a single direction (rank, file or diagonal) for a sliding piece,
    /// considering occupied squares as blocking further movement.
    fn linearAttack(occupied: bitboard, sqBB: bitboard, mask: bitboard) bitboard {
        const oInMask = occupied & mask;
        return ((oInMask -% 2 * sqBB) ^ @bitReverse(@bitReverse(oInMask) -% 2 * @bitReverse(sqBB))) & mask;
    }

    fn castlingMoves(pos: *const Position) []Move {
        const alloc = std.heap.page_allocator;
        var moves = try std.ArrayList(Move).initCapacity(alloc, 2); // Max 2 castling moves (king side and queen side)

        const kingSide = pos.castling.canCastle(pos.turn, .Kingside);
        const queenSide = pos.castling.canCastle(pos.turn, .Queenside);

        if (pos.castling.standard) {
            // White king side
            if (pos.turn == .White and kingSide and
                (~pos.board.emptySquares & (Square.squareBit(Square.F1) | Square.squareBit(Square.G1))) == 0 and
                !squaresAreAttacked(pos, &[_]Square{Square.F1, Square.G1}) and
                !pos.inCheck) {
                var m = Move{.s1 = Square.SqE1, .s2 = Square.SqG1};
                m.addTag(KingSideCastle);
                try moves.append(m);
            }

            // White queen side
            if (pos.turn == .White and queenSide and
                (~pos.board.emptySquares & (Square.squareBit(Square.B1) | Square.squareBit(Square.C1) | Square.squareBit(Square.D1))) == 0 and
                !squaresAreAttacked(pos, &[_]Square{Square.C1, Square.D1}) and
                !pos.inCheck) {
                var m = Move{.s1 = Square.SqE1, .s2 = Square.SqC1};
                m.addTag(QueenSideCastle);
                try moves.append(m);
            }

            // Black king side
            if (pos.turn == .Black and kingSide and
                (~pos.board.emptySquares & (Square.squareBit(Square.F8) | Square.squareBit(Square.G8))) == 0 and
                !squaresAreAttacked(pos, &[_]Square{Square.F8, Square.G8}) and
                !pos.inCheck) {
                var m = Move{.s1 = Square.SqE8, .s2 = Square.SqG8};
                m.addTag(KingSideCastle);
                try moves.append(m);
            }

            // Black queen side
            if (pos.turn == .Black and queenSide and
                (~pos.board.emptySquares & (Square.squareBit(Square.B8) | Square.squareBit(Square.C8) | Square.squareBit(Square.D8))) == 0 and
                !squaresAreAttacked(pos, &[_]Square{Square.C8, Square.D8}) and
                !pos.inCheck) {
                var m = Move{.s1 = Square.SqE8, .s2 = Square.SqC8};
                m.addTag(QueenSideCastle);
                try moves.append(m);
            }
        } else {
            // TODO: Check if king and/or rooks are already on target squares (chess960)
            // Else check if squares between king and rook are empty and not attacked
        }

        return moves.toOwnedSlice();
    }
};

test "Add tags" {
    const testCase = struct {
        name: []const u8,
        move: Move,
        expectedTags: u16,
        fen: []const u8,
    };
    const testCases = [_]testCase{
        .{
            .name = "move with queen side castle",
			.move = Move{.s1 = Square.SqE8, .s2 = Square.SqC8},
			.expectedTags = QueenSideCastle,
			.fen =  "r3kb1r/p2nqppp/5n2/1B2p1B1/4P3/1Q6/PPP2PPP/R3K2R b KQkq - 1 12",
        },
        .{
			.name = "move with king side castle",
			.move = Move{.s1 = Square.SqE1, .s2 = Square.SqG1},
			.expectedTags = KingSideCastle | Check,
			.fen =  "r4b1r/ppp3pp/8/4p3/2Pq4/3P4/PP2QPPP/2k1K2R w K - 0 18",
		},
        .{
            .name = "move with king side castle and check",
            .move = Move{.s1 = Square.SqE1, .s2 = Square.SqG1},
            .expectedTags = KingSideCastle | Check,
            .fen = "r4b1r/ppp3pp/8/4p3/2Pq4/3P1Q2/PP3PPP/1k2K2R w K - 2 19",
        },
        .{
            .name = "move with check",
            .move = Move{.s1 = Square.SqD7, .s2 = Square.SqA4},
            .expectedTags = Check,
            .fen = "rn2k1r1/ppqb4/4p1n1/3pPp1Q/8/P1PP4/4NPPP/R1BK1B1R b q - 0 14",
        },
        .{
            .name = "move leaves king in check",
            .move = Move{.s1 = Square.SqG6, .s2 = Square.SqF8},
            .expectedTags = InCheck,
            .fen = "r3k1r1/ppq5/2n1p1n1/3p1pBQ/b2P3P/P1P5/4NPP1/R3KB1R b q - 0 18",
        },
        .{
            .name = "capture move",
            .move = Move{.s1 = Square.SqG2, .s2 = Square.SqG3},
            .expectedTags = Capture,
            .fen = "8/7p/3k2p1/8/2p2P2/R5bP/6K1/4r3 w - - 0 44",
        },
        .{
            .name = "normal move without tags",
            .move = Move{.s1 = Square.SqD6, .s2 = Square.SqD5},
            .expectedTags = 0,
            .fen = "8/7p/3k2p1/8/2p2P2/R5KP/8/4r3 b - - 0 44",
        },
        .{
            .name = "en passant move",
            .move = Move{.s1 = Square.SqE4, .s2 = Square.SqF3},
            .expectedTags = EnPassant | Check,
            .fen = "r3k2r/pbppqpb1/1pn3p1/7p/1N2pPn1/1PP4N/PB1P2PP/2QRKR2 b kq f3 0 1",
        },
        .{
            .name = "normal move without tags",
            .move = Move{.s1 = Square.SqB7, .s2 = Square.SqA6},
            .expectedTags = 0,
            .fen = "r3k2r/pbppqpb1/1pn3p1/7p/1N2pPn1/1PP4N/PB1P2PP/2QRKR2 b kq f3 0 1",
        },
        .{
            .name = "en passant move with check",
            .move = Move{.s1 = Square.SqE4, .s2 = Square.SqF3},
            .expectedTags = EnPassant | Check,
            .fen = "r3k1r1/pbppqpb1/1pn3p1/7p/1N2pPn1/1PP4N/PB1P2PP/2QRK1R1 b q f3 0 2",
        },

    };

    for (testCases) |tc| {
        const pos = try decodeFEN(tc.fen);
        std.debug.print("Running test: {s}\nPosition before:\n{s}", .{tc.name, pos.toString()});
        var m = tc.move;
        try Engine.addTags(&m, &pos);
        // std.debug.print("Position after:\n{s}", .{pos.toString()});
        try std.testing.expectEqual(tc.expectedTags, m.tags);
    }
}