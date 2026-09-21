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

// test "Debug bitboard" {
//     const bbAntiDiagonals: [64]bitboard = @import("bitboard/antiDiagonals.zon");

//     const alloc = std.testing.allocator;
//     const sqBB: bitboard = Square.B4.bitmask();
//     debugBitboard(alloc, sqBB, "sqBB");
//     const occupied: bitboard = 0x10004800000800;
//     debugBitboard(alloc, occupied, "occupied");
//     const mask = bbAntiDiagonals[Square.B4.index()];
//     debugBitboard(alloc, mask, "mask");
//     const oInMask = occupied & mask;
//     debugBitboard(alloc, oInMask, "oInMask");
//     const twoXsqBB = sqBB << 1; // Multiply by 2
//     debugBitboard(alloc, twoXsqBB, "twoXsqBB");
//     const oInMaskMinusTwoXsqBB = oInMask -% twoXsqBB;
//     debugBitboard(alloc, oInMaskMinusTwoXsqBB, "oInMaskMinusTwoXsqBB");
//     const oInMaskReversed = @bitReverse(oInMask);
//     debugBitboard(alloc, oInMaskReversed, "oInMaskReversed");
//     const sqBBReversed = @bitReverse(sqBB);
//     debugBitboard(alloc, sqBBReversed, "sqBBReversed");
//     const twoXsqBBReversed = sqBBReversed << 1; // Multiply by 2
//     debugBitboard(alloc, twoXsqBBReversed, "twoXsqBBReversed");
//     const oInMaskReversedMinusTwoXsqBBReversed = oInMaskReversed -% twoXsqBBReversed;
//     debugBitboard(alloc, oInMaskReversedMinusTwoXsqBBReversed, "oInMaskReversedMinusTwoXsqBBReversed");
//     const oInMaskReversedMinusTwoXsqBBReversedReversed = @bitReverse(oInMaskReversedMinusTwoXsqBBReversed);
//     debugBitboard(alloc, oInMaskReversedMinusTwoXsqBBReversedReversed, "oInMaskReversedMinusTwoXsqBBReversedReversed");
//     const xorResult = oInMaskMinusTwoXsqBB ^ oInMaskReversedMinusTwoXsqBBReversedReversed;
//     debugBitboard(alloc, xorResult, "xorResult");
//     const finalResult = xorResult & mask;
//     debugBitboard(alloc, finalResult, "finalResult");

//     const formula = ((oInMask -% 2 * sqBB) ^ @bitReverse(@bitReverse(oInMask) -% 2 * @bitReverse(sqBB))) & mask;
//     debugBitboard(alloc, formula, "formula");
// }
