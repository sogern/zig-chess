const std = @import("std");
const Board = @import("board.zig").Board;
const Colour = @import("piece.zig").Colour;
const CastlingRights = @import("castling.zig").CastlingRights;
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

        if (move.s1 == Square.None or move.s2 == Square.None) {
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
        board.update(move);

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
            or (move.s1.r != Square.Rank1 and move.s1.r != Square.Rank8)) {
            return self.castling;
        }
        return switch (piece) {
            .WhiteKing => self.castling.removeAllCastlingRights(.White),
            .BlackKing => self.castling.removeAllCastlingRights(.Black),
            .WhiteRook => {
                const whiteKingSquare = self.board.getKingSquare(.White);
                if (whiteKingSquare.f < move.s1.f) {
                    return self.castling.removeCastlingRights(Colour, .Kingside);
                }
                return self.castling.removeCastlingRights(Colour, .Queenside);
            },
            .BlackRook => {
                const blackKingSquare = self.board.getKingSquare(.Black);
                if (blackKingSquare.f < move.s1.f) {
                    return self.castling.removeCastlingRights(Colour, .Kingside);
                }
                return self.castling.removeCastlingRights(Colour, .Queenside);
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