const std = @import("std");
const Board = @import("board.zig").Board;
const Engine = @import("engine.zig").Engine;
const Colour = @import("piece.zig").Colour;
const CastlingRights = @import("castling.zig");
const Square = @import("square.zig").Square;
const Move = @import("move.zig").Move;
const MoveError = @import("move.zig").MoveError;

pub const Position = struct {
    board: Board = Board{},
    castling: CastlingRights = .{},
    validMoves: []Move = undefined,
    /// The number of half moves since the last capture or pawn advance, used for the fifty-move rule.
    halfMoveClock: i32 = 0,
    /// The number of full moves, starting at 1 and incremented after each black move.
    moveCount: i32 = 0,
    turn: Colour = .White,
    enPassantSquare: Square = .None,
    inCheck: bool = false,

    /// update returns a new Position resulting from the given move.
    /// The move is not validated, use Game.move() for validation.
    /// This function is optimized for move generation where validation is handled separately.
    pub fn update(self: Position, move: Move) !Position {
        var moveCount = self.moveCount;
        if (self.turn == Colour.Black) {
            moveCount += 1;
        }

        if (move.s1 == .None or move.s2 == .None) {
            return self;
        }

        const castlingRights = try self.updateCastlingRights(move);
        const piece = self.board.getPieceOnSquare(move.s1);
        const halfMoveClock = self.halfMoveClock;
        if (piece.@"type"() == .Pawn or piece.hasTag(.Capture)) {
            // Reset half-move clock on pawn move or capture
            halfMoveClock = 0;
        } else {
            halfMoveClock += 1;
        }

        var board = self.board;
        board.update(move, self.castling);

        return .{
            .board = board,
            .castling = castlingRights,
            .halfMoveClock = halfMoveClock,
            .moveCount = moveCount,
            .turn = self.turn.opposite(),
            .enPassantSquare = self.updateEnPassantSquare(move),
            .inCheck = false, // This should be updated during move validation
        };
    }

    fn updateCastlingRights(self: Position, move: Move) !CastlingRights {
        const piece = self.board.getPieceOnSquare(move.s1);
        const pieceType = piece.@"type"();
        if (pieceType == .None
            or (pieceType != .King and pieceType != .Rook)
            or (move.s1.rank() != .@"1" and move.s1.rank() != .@"8")) {
            return self.castling;
        }
        return switch (piece) {
            .WhiteKing => self.castling.removeAllCastlingRights(.White),
            .BlackKing => self.castling.removeAllCastlingRights(.Black),
            .WhiteRook => {
                const whiteKingSquare = self.board.getKingSquare(.White);
                if (whiteKingSquare.f < move.s1.f) {
                    return self.castling.removeCastlingRight(.White, .Kingside);
                }
                return self.castling.removeCastlingRight(.White, .Queenside);
            },
            .BlackRook => {
                const blackKingSquare = self.board.getKingSquare(.Black);
                if (blackKingSquare.f < move.s1.f) {
                    return self.castling.removeCastlingRight(.Black, .Kingside);
                }
                return self.castling.removeCastlingRight(.Black, .Queenside);
            },
            else => self.castling,
        };
    }

    // fn updateEnPassantSquare(self: Position, move: Move) Square {
    //     const piece = self.board.getPieceOnSquare(move.s1);
    //     if (piece.@"type"() != .Pawn) {
    //         return .None;
    //     }
    //
    // }

    pub fn getValidMoves(self: *const Position) []Move {
        if (self.validMoves) {
            return self.validMoves;
        }
        self.validMoves = Engine.calcMoves(self, false);
        return self.validMoves;
    }

    pub fn hasValidMoves(self: *const Position) bool {
        return self.validMoves and self.validMoves.len > 0;
    }

    pub fn copy(self: *const Position) Position {
        return Position{
            .board = self.board,
            .castling = self.castling,
            .halfMoveClock = self.halfMoveClock,
            .moveCount = self.moveCount,
            .turn = self.turn,
            .enPassantSquare = self.enPassantSquare,
            .inCheck = self.inCheck,
        };
    }

    pub fn toString(self: *const Position) []const u8 {
        const alloc = std.heap.page_allocator;
        var out = std.ArrayList(u8).initCapacity(alloc, 256) catch unreachable;
        var buf: [256]u8 = undefined;
        out.appendSlice(alloc, std.fmt.bufPrint(&buf, "T: {c}, CR: {s}, HMC: {d}, MC: {d}, EP: {s}, Board:\n{s}\n",
        .{
            self.turn.toChar(),
            self.castling.toString(),
            self.halfMoveClock,
            self.moveCount,
            self.enPassantSquare.toString(),
            self.board.draw()
        }) catch unreachable) catch unreachable;
        return out.items;
    }
};

test "Position initialization" {
    const position = Position{};

    // Check if the board is initialized correctly
    try std.testing.expectEqual(0, position.board.whiteKing);
    try std.testing.expectEqual(0, position.board.blackKing);
    try std.testing.expectEqual(0xFFFF_FFFF_FFFF_FFFF, position.board.emptySquares);
    try std.testing.expectEqual(Square.None, position.enPassantSquare);
    try std.testing.expectEqual(Colour.White, position.turn);
}