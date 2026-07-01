const std = @import("std");
const Square = @import("square.zig").Square;

/// A bitboard is a 64-bit unsigned integer representing a chessboard.
/// Each bit corresponds to a square on the board indexed from 0 to 63,
/// starting from the most significant bit (A1) to the least significant bit (H8):
///
///   a b c d e f g h
/// 8 . . . . . . . . LSB (H8)
/// 7 . . . . . . . .
/// 6 . . . . . . . .
/// 5 . . . . . . . .
/// 4 . . . . . . . .
/// 3 . . . . . . . .
/// 2 . . . . . . . .
/// 1 . . . . . . . . MSB (A1)
pub const bitboard = u64;

// TODO: Move bitboard generating code to a separate generator.zig file
// const pieceMove = struct {
//     from_square: [2]u8,
//     to_squares: [][2]u8,
// };

// fn printPieceMoves(moves: []pieceMove) void {
//     for (moves) |km| {
//         const fs = Square.fromString(km.from_square[0..]);
//         if (fs.equals(Square.None)) {
//             std.debug.print("Invalid from square: {s}\n", .{km.from_square});
//             return;
//         }
//         var bb: bitboard = 0;
//         for (km.to_squares) |to_square| {
//             const ts = Square.fromString(to_square[0..]);
//             if (ts.equals(Square.None)) {
//                 std.debug.print("Invalid to square: {s}\n", .{to_square});
//                 return;
//             }
//             bb |= ts.getBitboard();
//         }

//         std.debug.print("0x{x:0>16}, // {s}\n", .{ bb, fs.toString() });
//     }
// }

// fn generatePieceMoves(move_offsets: [][2]i8, init_capacity: usize) ![]pieceMove {
//     const alloc = std.heap.page_allocator;
//     var moves = try std.ArrayList(pieceMove).initCapacity(alloc, init_capacity);

//     const files = "abcdefgh";
//     const ranks = "12345678";

//     for (ranks) |rank_char| {
//         const rank_idx = @as(i8, @intCast(rank_char - '1'));
//         for (files) |file_char| {
//             const f_idx = @as(i8, @intCast(file_char - 'a'));
//             const from_square = [_]u8{ file_char, rank_char };
//             var to_squares = try std.ArrayList([2]u8).initCapacity(alloc, init_capacity);
//             for (move_offsets) |move| {
//                 const f = f_idx + move[0];
//                 const r = rank_idx + move[1];
//                 if (f >= 0 and f < 8 and r >= 0 and r < 8) {
//                     const to_square = [_]u8{ @as(u8, @intCast(f + 'a')), @as(u8, @intCast(r + '1')) };
//                     try to_squares.append(alloc, to_square);
//                 }
//             }
//             const ts = try to_squares.toOwnedSlice(alloc);
//             try moves.append(alloc, pieceMove{
//                 .from_square = from_square,
//                 .to_squares = ts,
//             });
//         }
//     }

//     return try moves.toOwnedSlice(alloc);
// }

// test "Generate files" {
//     const alloc = std.heap.page_allocator;
//     var move_offsets = try std.ArrayList([2]i8).initCapacity(alloc, (2 * 7) + 1);

//     // Vertical moves along the same file, including the starting square.
//     try move_offsets.append(alloc, .{ 0, 0 }); // starting square
//     for (1..8) |offset| {
//         const o = @as(i8, @intCast(offset));
//         try move_offsets.appendSlice(alloc, &[_][2]i8{
//             .{ 0, o }, .{ 0, -o }, // up and down
//         });
//     }

//     const moves = try generatePieceMoves(try move_offsets.toOwnedSlice(alloc), 15);
//     std.debug.print("File moves:\n", .{});
//     printPieceMoves(moves);
// }

// test "Generate ranks" {
//     const alloc = std.heap.page_allocator;
//     var move_offsets = try std.ArrayList([2]i8).initCapacity(alloc, (2 * 7) + 1);

//     // Horizontal moves along the same rank, including the starting square.
//     try move_offsets.append(alloc, .{ 0, 0 }); // starting square
//     for (1..8) |offset| {
//         const o = @as(i8, @intCast(offset));
//         try move_offsets.appendSlice(alloc, &[_][2]i8{
//             .{ o, 0 }, .{ -o, 0 }, // right and left
//         });
//     }

//     const moves = try generatePieceMoves(try move_offsets.toOwnedSlice(alloc), 15);
//     std.debug.print("Rank moves:\n", .{});
//     printPieceMoves(moves);
// }

// test "Generate diagonals" {
//     const alloc = std.heap.page_allocator;
//     var move_offsets = try std.ArrayList([2]i8).initCapacity(alloc, (2 * 7) + 1);

//     // Diagonals from lower left to upper right, including the starting square.
//     try move_offsets.append(alloc, .{ 0, 0 }); // starting square
//     for (1..8) |offset| {
//         const o = @as(i8, @intCast(offset));
//         try move_offsets.appendSlice(alloc, &[_][2]i8{
//             .{ o, o }, .{ -o, -o }, // up-right and down-left
//         });
//     }

//     const moves = try generatePieceMoves(try move_offsets.toOwnedSlice(alloc), 15);
//     std.debug.print("Diagonal moves (lower left to upper right):\n", .{});
//     printPieceMoves(moves);
// }

// test "Generate anti-diagonals" {
//     const alloc = std.heap.page_allocator;
//     var move_offsets = try std.ArrayList([2]i8).initCapacity(alloc, (2 * 7) + 1);

//     // Diagonals from upper left to lower right, including the starting square.
//     try move_offsets.append(alloc, .{ 0, 0 }); // starting square
//     for (1..8) |offset| {
//         const o = @as(i8, @intCast(offset));
//         try move_offsets.appendSlice(alloc, &[_][2]i8{
//             .{ o, -o }, .{ -o, o }, // up-left and down-right
//         });
//     }

//     const moves = try generatePieceMoves(try move_offsets.toOwnedSlice(alloc), 15);
//     std.debug.print("Anti-diagonal moves (upper left to lower right):\n", .{});
//     printPieceMoves(moves);
// }

// test "Generate knight moves" {
//     const alloc = std.heap.page_allocator;
//     var move_offsets = try std.ArrayList([2]i8).initCapacity(alloc, 8);

//     // A knight moves in an "L" shape: two squares in one direction and then one square perpendicular.
//     // Without board boundaries, a knight has up to 8 possible moves from any square.
//     try move_offsets.appendSlice(alloc, &[_][2]i8{
//         .{ 2, 1 }, .{ 2, -1 }, .{ -2, 1 }, .{ -2, -1 },
//         .{ 1, 2 }, .{ 1, -2 }, .{ -1, 2 }, .{ -1, -2 },
//     });
//     const moves = try generatePieceMoves(try move_offsets.toOwnedSlice(alloc), 8);
//     std.debug.print("Knight moves:\n", .{});
//     printPieceMoves(moves);
// }

// test "Generate bishop moves" {
//     const alloc = std.heap.page_allocator;
//     var move_offsets = try std.ArrayList([2]i8).initCapacity(alloc, 7 * 4);

//     // A bishop moves diagonally any number of squares.
//     // Without board boundaries, a bishop has up to 32 possible moves from any square.
//     for (1..8) |offset| {
//         const o = @as(i8, @intCast(offset));
//         try move_offsets.appendSlice(alloc, &[_][2]i8{
//             .{ o, o }, .{ o, -o }, .{ -o, o }, .{ -o, -o }, // up-right, down-right, up-left, down-left
//         });
//     }

//     const moves = try generatePieceMoves(try move_offsets.toOwnedSlice(alloc), 13);
//     std.debug.print("Bishop moves:\n", .{});
//     printPieceMoves(moves);
// }

// test "Generate rook moves" {
//     const alloc = std.heap.page_allocator;
//     var move_offsets = try std.ArrayList([2]i8).initCapacity(alloc, 7 * 4);

//     // A rook moves horizontally or vertically any number of squares.
//     // Without board boundaries, a rook has up to 28 possible moves from any square.
//     for (1..8) |offset| {
//         const o = @as(i8, @intCast(offset));
//         try move_offsets.appendSlice(alloc, &[_][2]i8{
//             .{ o, 0 }, .{ -o, 0 }, .{ 0, o }, .{ 0, -o }, // right, left, up, down
//         });
//     }

//     const moves = try generatePieceMoves(try move_offsets.toOwnedSlice(alloc), 14);
//     std.debug.print("Rook moves:\n", .{});
//     printPieceMoves(moves);
// }

// test "Generate queen moves" {
//     const alloc = std.heap.page_allocator;
//     var move_offsets = try std.ArrayList([2]i8).initCapacity(alloc, 7 * 8);

//     // A queen moves horizontally, vertically, or diagonally any number of squares.
//     // Without board boundaries, a queen has up to 56 possible moves from any square.
//     for (1..8) |offset| {
//         const o = @as(i8, @intCast(offset));
//         try move_offsets.appendSlice(alloc, &[_][2]i8{
//             .{ o, 0 }, .{ -o, 0 }, .{ 0, o }, .{ 0, -o }, // right, left, up, down
//             .{ o, o }, .{ o, -o }, .{ -o, o }, .{ -o, -o }, // up-right, down-right, up-left, down-left
//         });
//     }

//     const moves = try generatePieceMoves(try move_offsets.toOwnedSlice(alloc), 27);
//     std.debug.print("Queen moves:\n", .{});
//     printPieceMoves(moves);
// }

// test "Generate king moves" {
//     const alloc = std.heap.page_allocator;
//     var move_offsets = try std.ArrayList([2]i8).initCapacity(alloc, 8);

//     // A king moves one square in any direction.
//     // Without board boundaries, a king has up to 8 possible moves from any square.
//     try move_offsets.appendSlice(alloc, &[_][2]i8{
//         .{ 1, 0 }, .{ -1, 0 }, .{ 0, 1 },  .{ 0, -1 },
//         .{ 1, 1 }, .{ 1, -1 }, .{ -1, 1 }, .{ -1, -1 },
//     });
//     const moves = try generatePieceMoves(try move_offsets.toOwnedSlice(alloc), 8);
//     std.debug.print("King moves:\n", .{});
//     printPieceMoves(moves);
// }

/// Returns a human-readable representation of the bitboard.
/// Caller owns the returned string.
pub fn drawBitboard(alloc: std.mem.Allocator, bb: bitboard) []const u8 {
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
            const sq = (f + 1) + (r * 8) - 1;
            const bbForSquare = Square.fromIndex(sq).bitmask();
            if (bb & bbForSquare != 0) {
                buf[f * 2 + 2] = 'X';
            } else {
                buf[f * 2 + 2] = ' ';
            }
        }
        out.appendSlice(alloc, buf[0..lines[l].len]) catch @panic("OOM");
    }
    return out.toOwnedSlice(alloc) catch @panic("OOM");
}

/// Prints a bitboard in a human-readable format.
fn debugBitboard(alloc: std.mem.Allocator, bb: bitboard, name: []const u8) void {
    const debugStr = drawBitboard(alloc, bb);
    defer alloc.free(debugStr);
    std.debug.print("{s}: 0x{x:0>16}\n{s}\n", .{name, bb, debugStr});
}

test "Debug bitboard" {
    const bbAntiDiagonals: [64]bitboard = @import("bitboard/antiDiagonals.zon");

    const alloc = std.testing.allocator;
    const sqBB: bitboard = Square.B4.bitmask();
    debugBitboard(alloc, sqBB, "sqBB");
    const occupied: bitboard = 0x10004800000800;
    debugBitboard(alloc, occupied, "occupied");
    const mask = bbAntiDiagonals[Square.B4.index()];
    debugBitboard(alloc, mask, "mask");
    const oInMask = occupied & mask;
    debugBitboard(alloc, oInMask, "oInMask");
    const twoXsqBB = sqBB << 1; // Multiply by 2
    debugBitboard(alloc, twoXsqBB, "twoXsqBB");
    const oInMaskMinusTwoXsqBB = oInMask -% twoXsqBB;
    debugBitboard(alloc, oInMaskMinusTwoXsqBB, "oInMaskMinusTwoXsqBB");
    const oInMaskReversed = @bitReverse(oInMask);
    debugBitboard(alloc, oInMaskReversed, "oInMaskReversed");
    const sqBBReversed = @bitReverse(sqBB);
    debugBitboard(alloc, sqBBReversed, "sqBBReversed");
    const twoXsqBBReversed = sqBBReversed << 1; // Multiply by 2
    debugBitboard(alloc, twoXsqBBReversed, "twoXsqBBReversed");
    const oInMaskReversedMinusTwoXsqBBReversed = oInMaskReversed -% twoXsqBBReversed;
    debugBitboard(alloc, oInMaskReversedMinusTwoXsqBBReversed, "oInMaskReversedMinusTwoXsqBBReversed");
    const oInMaskReversedMinusTwoXsqBBReversedReversed = @bitReverse(oInMaskReversedMinusTwoXsqBBReversed);
    debugBitboard(alloc, oInMaskReversedMinusTwoXsqBBReversedReversed, "oInMaskReversedMinusTwoXsqBBReversedReversed");
    const xorResult = oInMaskMinusTwoXsqBB ^ oInMaskReversedMinusTwoXsqBBReversedReversed;
    debugBitboard(alloc, xorResult, "xorResult");
    const finalResult = xorResult & mask;
    debugBitboard(alloc, finalResult, "finalResult");

    const formula = ((oInMask -% 2 * sqBB) ^ @bitReverse(@bitReverse(oInMask) -% 2 * @bitReverse(sqBB))) & mask;
    debugBitboard(alloc, formula, "formula");
}
