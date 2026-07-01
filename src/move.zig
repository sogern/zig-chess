const std = @import("std");
const Square = @import("square.zig").Square;
const PieceType = @import("piece.zig").PieceType;
const startFEN = @import("fen.zig").startFEN;
const decodeFEN = @import("fen.zig").decodeFEN;
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

pub const MoveError = error{
    InvalidMove,
};

/// A move is the movement of a piece from one square to another.
pub const Move = struct {
    parent: ?*Move = null,
    /// Position after the move
    position: *Position = undefined,
    /// NAG (Numeric Annotation Glyph) for the move, if any. See: https://en.wikipedia.org/wiki/Portable_Game_Notation#Numeric_Annotation_Glyphs
    nag: ?u16 = null,
    /// Main line and variations
    children: []Move = undefined,
    number: u32 = 0,
    tags: MoveTag = 0,
    s1: Square = Square.None, // From square
    s2: Square = Square.None, // To square
    promotion: PieceType = PieceType.None,

    pub fn toString(self: *const Move) []const u8 {
        return std.fmt.allocPrint(
            std.heap.page_allocator,
            "{s}->{s}, p:{c}",
            .{ self.s1.string(), self.s2.string(), self.promotion.string() },
        ) catch unreachable;
    }

    pub fn hasTag(self: *const Move, tag: MoveTag) bool {
        return (self.tags & tag) != 0;
    }

    pub fn addTag(self: *Move, tag: MoveTag) void {
        self.tags |= tag;
    }

    pub fn ply(self: *const Move) i32 {
        const moveNumber = @as(i32, @intCast(self.number));
        if (self.position.turn == .Black) {
            return (moveNumber - 1) * 2 + 1;
        }
        return moveNumber * 2;
    }
};

test "Move toString" {
    const move = Move{
        .s1 = Square.E2,
        .s2 = Square.E4,
    };
    try std.testing.expectEqualStrings("e2->e4, p: ", move.toString());
}

test "Move hasTag and addTag" {
    var move = Move{};
    try std.testing.expect(!move.hasTag(Capture));
    move.addTag(Capture);
    try std.testing.expect(move.hasTag(Capture));
}

test "Move ply" {
    var position = Position{};
    position.turn = .White;

    var move1 = Move{
        .position = &position,
        .number = 1,
    };
    try std.testing.expectEqual(@as(i32, 2), move1.ply());

    position.turn = .Black;
    var move2 = Move{
        .position = &position,
        .number = 1,
    };
    try std.testing.expectEqual(@as(i32, 1), move2.ply());
}

fn unsafeDecodeFEN(fen: []const u8) *Position {
    const out = std.heap.page_allocator.create(Position) catch unreachable;
    out.* = decodeFEN(fen) catch unreachable;
    return out;
}

// fn moveIsValid(position: *const Position, move: Move) bool {
//     // Placeholder implementation
//     return true;
// }

// test "Move valid moves" {
//     const testCase = struct {
//         position: *Position,
//         move: Move,
//         postPosition: *Position = null,
//     };
//     const testCases: []const testCase = &[_]testCase{
//         // Pawn moves
//         .{
//             .move = Move{.s1 = Square.SqE2, .s2 = Square.SqE4 },
//             .position = unsafeDecodeFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
//         },
//     };
// }