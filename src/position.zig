const std = @import("std");
const Board = @import("board.zig").Board;
const Colour = @import("piece.zig").Colour;
const CastlingRights = @import("castling.zig").CastlingRights;
const Square = @import("square.zig").Square;

pub const Position = struct {
    board: *Board,
    castling: CastlingRights,
    halfMoveCount: i32,
    moveCount: i32,
    turn: Colour,
    enPassantSquare: Square,
    inCheck: bool,
    alloc: std.mem.Allocator,

    pub fn create(alloc: std.mem.Allocator) !*Position {
        const position = try alloc.create(Position);
        position.* = Position{
            .board = try Board.create(alloc),
            .castling = CastlingRights.init(),
            .halfMoveCount = 0,
            .moveCount = 0,
            .turn = Colour.White,
            .enPassantSquare = Square.None,
            .inCheck = false,
            .alloc = alloc,
        };
        return position;
    }

    pub fn deinit(self: *Position) void {
        self.board.deinit();
        self.alloc.destroy(self.board);
    }
};

test "Position initialization" {
    const alloc = std.testing.allocator;
    const position = try Position.create(alloc);
    defer {
        position.deinit();
        alloc.destroy(position);
    }

    // Check if the board is initialized correctly
    try std.testing.expect(position.board.whiteKing == 0);
    try std.testing.expect(position.board.blackKing == 0);
}