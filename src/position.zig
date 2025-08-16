const std = @import("std");
const Board = @import("board.zig").Board;

pub const Position = struct {
    board: *Board,
    alloc: std.mem.Allocator,

    pub fn create(alloc: std.mem.Allocator) !*Position {
        const position = try alloc.create(Position);
        position.* = Position{
            .board = try Board.create(alloc),
            .alloc = alloc,
        };
        return position;
    }

    pub fn deinit(self: *Position) void {
        self.board.deinit();
        self.alloc.destroy(self.board);
    }
};

test "Position creation and deinitialization" {
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