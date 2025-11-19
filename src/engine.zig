const std = @import("std");
const Position = @import("position.zig").Position;
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
const CastlingRights = @import("castling.zig").CastlingRights;
const Square = @import("square.zig").Square;
const Move = @import("move.zig").Move;
const Piece = @import("piece.zig").Piece;
const PieceType = @import("piece.zig").PieceType;

const numSquaresOnBoard = Square.numSquaresOnBoard;
const maxPossibleMoves = 218; // Maximum possible legal moves in any chess position

const Engine = struct {
    
    pub fn calcMoves(pos: *const Position, first: bool) []Move {
        const sm = standardMoves(pos, first);
        const cm = castlingMoves(pos);
        return sm ++ cm;
    }

    /// standardMoves generates all standard (non-castling) legal moves for the given position.
    /// If first is true, only the first move found is returned.
    fn standardMoves(pos: *const Position, _: bool) []Move {
        // MemoryPool is used here for efficient allocation of many Move instances.
        const alloc = std.heap.MemoryPool(Move);
        var moves = try std.ArrayList(Move).initCapacity(alloc, maxPossibleMoves);
        // var count = 0;
        // var m = Move{};

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
                if (pBB & Square.squareBit(s1) == 0) continue;
                const s2BB = bbForPossibleMoves(pos, p.@"type"(), s1) & bbAllowed;
                if (s2BB == 0) continue;
                for (0..numSquaresOnBoard) |j| {
                    const s2 = Square.fromIndex(@as(i8, @intCast(j)));                    
                }
            }
        }

        return moves.toOwnedSlice();
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
        const sqBB = Square.squareBit(@as(usize, @intCast(sq.s)));
        var bbEnPassant: bitboard = 0;
        if (pos.enPassantSquare != .None) {
            bbEnPassant = Square.squareBit(@as(usize, @intCast(pos.enPassantSquare.s)));
        }
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
        const sqBB = Square.squareBit(sq);
        const dMask = bbDiagonals[sq.s];
        const adMask = bbAntiDiagonals[sq.s];
        return linearAttack(occupied, sqBB, dMask) | linearAttack(occupied, sqBB, adMask);
    }

    /// hvAttack returns a bitboard of possible horizontal and vertical moves
    /// for a sliding piece, considering occupied squares as blocking further movement.
    fn hvAttack(occupied: bitboard, sq: Square) bitboard {
        const sqBB = Square.squareBit(sq);
        const rankMask = bbRanks[sq.rank()];
        const fileMask = bbFiles[sq.file()];
        return linearAttack(occupied, sqBB, rankMask) | linearAttack(occupied, sqBB, fileMask);
    }

    /// linearAttack returns a bitboard of possible moves
    /// in a single direction (rank, file or diagonal) for a sliding piece,
    /// considering occupied squares as blocking further movement.
    fn linearAttack(occupied: bitboard, sqBB: bitboard, mask: bitboard) bitboard {
        const oInMask = occupied & mask;
        return ((oInMask -% 2 * sqBB) ^ @bitReverse(@bitReverse(oInMask) -% 2 * @bitReverse(sqBB))) & mask;
    }

    fn castlingMoves(_: *const Position) []Move {
        const alloc = std.heap.page_allocator;
        var moves = try std.ArrayList(Move).initCapacity(alloc, 0);

        return moves.toOwnedSlice();
    }
};