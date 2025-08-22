const std = @import("std");
const Board = @import("board.zig").Board;
const Colour = @import("piece.zig").Colour;
const CastlingRights = @import("castling.zig").CastlingRights;
const Square = @import("square.zig").Square;

pub const Position = struct {
    board: Board = Board{},
    castling: CastlingRights = .{},
    /// The number of half moves since the last capture or pawn advance, used for the fifty-move rule.
    halfMoveClock: i32 = 0,
    /// The number of full moves, starting at 1 and incremented after each black move.
    moveCount: i32 = 0,
    turn: Colour = .White,
    enPassantSquare: Square = .None,
    inCheck: bool = false,
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