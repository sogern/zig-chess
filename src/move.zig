const std = @import("std");
const Square = @import("square.zig").Square;
const PieceType = @import("piece.zig").PieceType;
const startFEN = @import("position.zig").startFEN;
const positionFromFEN = @import("position.zig").positionFromFEN;
const Position = @import("position.zig").Position;

/// MoveTag represents a notable consequence of a move.
pub const MoveTag = u16;

pub const KingSideCastle = @as(MoveTag, 0x0001);
pub const QueenSideCastle = @as(MoveTag, 0x0002);
/// Capture indicates that the move captures an opponent's piece.
pub const Capture = @as(MoveTag, 0x0004);
/// EnPassant indicates that the move captures via en passant.
pub const EnPassant = @as(MoveTag, 0x0008);
/// Check indicates that the move puts the opponent in check.
pub const Check = @as(MoveTag, 0x0010);
/// InCheck indicates that the move puts the current player in check and is therefore illegal.
pub const InCheck = @as(MoveTag, 0x0020);

/// A move is the movement of a piece from one square to another.
pub const Move = struct {
    parent: ?*Move = null,
    /// Position after the move
    position: *Position,
    /// NAG (Numeric Annotation Glyph) for the move, if any. See: https://en.wikipedia.org/wiki/Portable_Game_Notation#Numeric_Annotation_Glyphs
    nag: ?u16 = null,
    /// Main line and variations
    children: []*Move = &.{},
    number: u32 = 0,
    tags: MoveTag = 0,
    s1: Square, // From square
    s2: Square, // To square
    promotion: PieceType = PieceType.None,

    pub fn toString(self: *const Move) []const u8 {
        return std.fmt.allocPrint(
            std.heap.page_allocator,
            "{s}->{s}, p:{c}",
            .{ self.s1.toString(), self.s2.toString(), self.promotion.toString() },
        ) catch unreachable;
    }
};

test "Move toString" {
    var allocator = std.testing.allocator;

    const pos = try positionFromFEN(allocator, startFEN);
    defer allocator.destroy(pos);

    const move = Move{
        .position = pos,
        .s1 = Square.fromString("e2"),
        .s2 = Square.fromString("e4"),
    };
    try std.testing.expectEqualStrings("e2->e4, p: ", move.toString());
}