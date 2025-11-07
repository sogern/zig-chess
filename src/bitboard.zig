const std = @import("std");
const Square = @import("square.zig").Square;

/// A bitboard is a 64-bit integer representing the state of a chessboard.
/// Each bit corresponds to a square on the board, indexed from 0 to 63,
/// starting from the most significant bit (A1) to the least significant bit (H8).
pub const bitboard = u64;

const bbFileA: bitboard = 0x8080808080808080;
const bbFileB: bitboard = 0x4040404040404040;
const bbFileC: bitboard = 0x2020202020202020;
const bbFileD: bitboard = 0x1010101010101010;
const bbFileE: bitboard = 0x0808080808080808;
const bbFileF: bitboard = 0x0404040404040404;
const bbFileG: bitboard = 0x0202020202020202;
const bbFileH: bitboard = 0x0101010101010101;
const bbRank1: bitboard = 0xFF00000000000000;
const bbRank2: bitboard = 0x00FF000000000000;
const bbRank3: bitboard = 0x0000FF0000000000;
const bbRank4: bitboard = 0x000000FF00000000;
const bbRank5: bitboard = 0x00000000FF000000;
const bbRank6: bitboard = 0x0000000000FF0000;
const bbRank7: bitboard = 0x000000000000FF00;
const bbRank8: bitboard = 0x00000000000000FF;

// Lookup tables for piece movement
//
//   a b c d e f g h
// 8 . . . . . . . . LSB byte (A8)
// 7 . . . . . . . .
// 6 . . . . . . . .
// 5 . . . . . . . .
// 4 . . . . . . . .
// 3 . . . . . . . .
// 2 . . . . . . . .
// 1 . . . . . . . . MSB byte (A1)

const bbDiagonals = [_]bitboard{
    // Diagonals from left to right
    0x8040201008040201, // A1 (a1-h8 diagonal)
    0x4020100804020100, // B1 (b1-h7 diagonal)
    0x2010080402010000, // C1 (c1-h6 diagonal)
    0x1008040201000000, // D1 (d1-h5 diagonal)
    0x0804020100000000, // E1 (e1-h4 diagonal)
    0x0402010000000000, // F1 (f1-h3 diagonal)
    0x0201000000000000, // G1 (g1-h2 diagonal)
    0x0100000000000000, // H1 (h1-h1 diagonal)

    0x0080402010080402, // A2 (a2-g7 diagonal)
    0x8040201008040201, // B2 (a1-h8 diagonal)
    0x4020100804020100, // C2 (b1-h7 diagonal)
    0x2010080402010000, // D2 (c1-h6 diagonal)
    0x1008040201000000, // E2 (d1-h5 diagonal)
    0x0804020100000000, // F2 (e1-h4 diagonal)
    0x0402010000000000, // G2 (f1-h3 diagonal)
    0x0201000000000000, // H2 (g1-h2 diagonal)

    0x0000804020100804, // A3 (a3-f8 diagonal)
    0x0080402010080402, // B3 (a2-g8 diagonal)
    0x8040201008040201, // C3 (a1-h8 diagonal)
    0x4020100804020100, // D3 (b1-h7 diagonal)
    0x2010080402010000, // E3 (c1-h6 diagonal)
    0x1008040201000000, // F3 (d1-h5 diagonal)
    0x0804020100000000, // G3 (e1-h4 diagonal)
    0x0402010000000000, // H3 (f1-h3 diagonal)

    0x0000008040201008, // A4 (a4-e8 diagonal)
    0x0000804020100804, // B4 (a3-f8 diagonal)
    0x0080402010080402, // C4 (a2-g8 diagonal)
    0x8040201008040201, // D4 (a1-h8 diagonal)
    0x4020100804020100, // E4 (b1-h7 diagonal)
    0x2010080402010000, // F4 (c1-h6 diagonal)
    0x1008040201000000, // G4 (d1-h5 diagonal)
    0x0804020100000000, // H4 (e1-h4 diagonal)

    0x0000000080402010, // A5 (a5-d8 diagonal)
    0x0000008040201008, // B5 (a4-e8 diagonal)
    0x0000804020100804, // C5 (a3-f8 diagonal)
    0x0080402010080402, // D5 (a2-g8 diagonal)
    0x8040201008040201, // E5 (a1-h8 diagonal)
    0x4020100804020100, // F5 (b1-h7 diagonal)
    0x2010080402010000, // G5 (c1-h6 diagonal)
    0x1008040201000000, // H5 (d1-h5 diagonal)

    0x0000000000804020, // A6 (a6-c8 diagonal)
    0x0000000080402010, // B6 (a5-d8 diagonal)
    0x0000008040201008, // C6 (a4-e8 diagonal)
    0x0000804020100804, // D6 (a3-f8 diagonal)
    0x0080402010080402, // E6 (a2-g8 diagonal)
    0x8040201008040201, // F6 (a1-h8 diagonal)
    0x4020100804020100, // G6 (b1-h7 diagonal)
    0x2010080402010000, // H6 (c1-h6 diagonal)

    0x0000000000008040, // A7 (a7-b8 diagonal)
    0x0000000000804020, // B7 (a6-c8 diagonal)
    0x0000000080402010, // C7 (a5-d8 diagonal)
    0x0000008040201008, // D7 (a4-e8 diagonal)
    0x0000804020100804, // E7 (a3-f8 diagonal)
    0x0080402010080402, // F7 (a2-g8 diagonal)
    0x8040201008040201, // G7 (a1-h8 diagonal)
    0x4020100804020100, // H7 (b1-h7 diagonal)

    0x0000000000000080, // A8 (a8-a8 diagonal)
    0x0000000000008040, // B8 (a7-b8 diagonal)
    0x0000000000804020, // C8 (a6-c8 diagonal)
    0x0000000080402010, // D8 (a5-d8 diagonal)
    0x0000008040201008, // E8 (a4-e8 diagonal)
    0x0000804020100804, // F8 (a3-f8 diagonal)
    0x0080402010080402, // G8 (a2-g8 diagonal)
    0x8040201008040201, // H8 (a1-h8 diagonal)
};

const bbAntiDiagonals = [_]bitboard{
    // Diagonals from right to left
    0x8000000000000000, // A1 (a1-a1 diagonal)
    0x4080000000000000, // B1 (b1-a2 diagonal)
    0x2040800000000000, // C1 (c1-a3 diagonal)
    0x1020408000000000, // D1 (d1-a4 diagonal)
    0x0810204080000000, // E1 (e1-a5 diagonal)
    0x0408102040800000, // F1 (f1-a6 diagonal)
    0x0204081020408000, // G1 (g1-a7 diagonal)
    0x0102040810204080, // H1 (h1-a8 diagonal)

    0x4080000000000000, // A2 (b1-a2 diagonal)
    0x2040800000000000, // B2 (c1-a3 diagonal)
    0x1020408000000000, // C2 (d1-a4 diagonal)
    0x0810204080000000, // D2 (e1-a5 diagonal)
    0x0408102040800000, // E2 (f1-a6 diagonal)
    0x0204081020408000, // F2 (g1-a7 diagonal)
    0x0102040810204080, // G2 (h1-a8 diagonal)
    0x0001020408102040, // H2 (h2-b8 diagonal)

    0x2040800000000000, // A3 (c1-a3 diagonal)
    0x1020408000000000, // B3 (d1-a4 diagonal)
    0x0810204080000000, // C3 (e1-a5 diagonal)
    0x0408102040800000, // D3 (f1-a6 diagonal)
    0x0204081020408000, // E3 (g1-a7 diagonal)
    0x0102040810204080, // F3 (h1-a8 diagonal)
    0x0001020408102040, // G3 (h2-b8 diagonal)
    0x0000010204081020, // H3 (h3-c8 diagonal)

    0x1020408000000000, // A4 (d1-a4 diagonal)
    0x0810204080000000, // B4 (e1-a5 diagonal)
    0x0408102040800000, // C4 (f1-a6 diagonal)
    0x0204081020408000, // D4 (g1-a7 diagonal)
    0x0102040810204080, // E4 (h1-a8 diagonal)
    0x0001020408102040, // F4 (h2-b8 diagonal)
    0x0000010204081020, // G4 (h3-c8 diagonal)
    0x0000000102040810, // H4 (h4-d8 diagonal)

    0x0810204080000000, // A5 (e1-a5 diagonal)
    0x0408102040800000, // B5 (f1-a6 diagonal)
    0x0204081020408000, // C5 (g1-a7 diagonal)
    0x0102040810204080, // D5 (h1-a8 diagonal)
    0x0001020408102040, // E5 (h2-b8 diagonal)
    0x0000010204081020, // F5 (h3-c8 diagonal)
    0x0000000102040810, // G5 (h4-d8 diagonal)
    0x0000000001020408, // H5 (h5-e8 diagonal)

    0x0408102040800000, // A6 (f1-a6 diagonal)
    0x0204081020408000, // B6 (g1-a7 diagonal)
    0x0102040810204080, // C6 (h1-a8 diagonal)
    0x0001020408102040, // D6 (h2-b8 diagonal)
    0x0000010204081020, // E6 (h3-c8 diagonal)
    0x0000000102040810, // F6 (h4-d8 diagonal)
    0x0000000001020408, // G6 (h5-e8 diagonal)
    0x0000000000010204, // H6 (h6-f8 diagonal)

    0x0204081020408000, // A7 (g1-a7 diagonal)
    0x0102040810204080, // B7 (h1-a8 diagonal)
    0x0001020408102040, // C7 (h2-b8 diagonal)
    0x0000010204081020, // D7 (h3-c8 diagonal)
    0x0000000102040810, // E7 (h4-d8 diagonal)
    0x0000000001020408, // F7 (h5-e8 diagonal)
    0x0000000000010204, // G7 (h6-f8 diagonal)
    0x0000000000000102, // H7 (h7-g8 diagonal)

    0x0102040810204080, // A8 (h1-a8 diagonal)
    0x0001020408102040, // B8 (h2-b8 diagonal)
    0x0000010204081020, // C8 (h3-c8 diagonal)
    0x0000000102040810, // D8 (h4-d8 diagonal)
    0x0000000001020408, // E8 (h5-e8 diagonal)
    0x0000000000010204, // F8 (h6-f8 diagonal)
    0x0000000000000102, // G8 (h7-g8 diagonal)
    0x0000000000000001, // H8 (h8-h8 diagonal)
};

const bbKnightMoves = [_]bitboard{
    0x0000000000000000, // A1
    0x0000000000000000, // B1
    0x0000000000000000, // C1
    0x0000000000000000, // D1
    0x0000000000000000, // E1
    0x0000000000000000, // F1
    0x0000000000000000, // G1
    0x0000000000000000, // H1

    0x0000000000000000, // A2
    0x0000000000000000, // B2
    0x0000000000000000, // C2
    0x0000000000000000, // D2
    0x0000000000000000, // E2
    0x0000000000000000, // F2
    0x0000000000000000, // G2
    0x0000000000000000, // H2

    0x0000000000000000, // A3
    0x0000000000000000, // B3
    0x0000000000000000, // C3
    0x0000000000000000, // D3
    0x0000000000000000, // E3
    0x0000000000000000, // F3
    0x0000000000000000, // G3
    0x0000000000000000, // H3

    0x0000000000000000, // A4
    0x0000000000000000, // B4
    0x0000000000000000, // C4
    0x0000000000000000, // D4
    0x0000000000000000, // E4
    0x0000000000000000, // F4
    0x0000000000000000, // G4
    0x0000000000000000, // H4

    0x0000000000000000, // A5
    0x0000000000000000, // B5
    0x0000000000000000, // C5
    0x0000000000000000, // D5
    0x0000000000000000, // E5
    0x0000000000000000, // F5
    0x0000000000000000, // G5
    0x0000000000000000, // H5

    0x0000000000000000, // A6
    0x0000000000000000, // B6
    0x0000000000000000, // C6
    0x0000000000000000, // D6
    0x0000000000000000, // E6
    0x0000000000000000, // F6
    0x0000000000000000, // G6
    0x0000000000000000, // H6

    0x0000000000000000, // A7
    0x0000000000000000, // B7
    0x0000000000000000, // C7
    0x0000000000000000, // D7
    0x0000000000000000, // E7
    0x0000000000000000, // F7
    0x0000000000000000, // G7
    0x0000000000000000, // H7

    0x0000000000000000, // A8
    0x0000000000000000, // B8
    0x0000000000000000, // C8
    0x0000000000000000, // D8
    0x0000000000000000, // E8
    0x0000000000000000, // F8
    0x0000000000000000, // G8
    0x0000000000000000, // H8
};

test "Generate knight moves" {
    const alloc = std.heap.page_allocator;

    const knightMove = struct {
        from_square: []const u8,
        to_squares: [][]const u8,
    };

    var kms = std.ArrayList(knightMove).initCapacity(alloc, 8) catch unreachable;

    // A knight can move in an "L" shape: two squares in one direction and then one square perpendicular.
    // Without board boundaries, a knight has up to 8 possible moves from any square.
    const files = "abcdefgh";
    const ranks = "12345678";
    const piece_moves: [8][2]i8 = .{
        .{2, 1}, .{2, -1}, .{-2, 1}, .{-2, -1},
        .{1, 2}, .{1, -2}, .{-1, 2}, .{-1, -2},
    };
    for (ranks) |rank_char| {
        const rank_idx = @as(i8, @intCast(rank_char - '1'));
        for (files) |file_char| {
            const f_idx = @as(i8, @intCast(file_char - 'a'));
            var from_square = [_]u8{file_char, rank_char};
            var to_squares = std.ArrayList([2]u8).initCapacity(alloc, 8) catch unreachable;
            for (piece_moves) |move| {
                const new_file = f_idx + move[0];
                const new_rank = rank_idx + move[1];
                if (new_file >= 0 and new_file < 8 and new_rank >= 0 and new_rank < 8) {
                    const to_file_char = @as(u8, @intCast(new_file + 'a'));
                    const to_rank_char = @as(u8, @intCast(new_rank + '1'));
                    const to_square = [_]u8{to_file_char, to_rank_char};
                    to_squares.appendSlice(alloc, &to_square) catch unreachable;
                }
            }
            kms.appendSlice(alloc, knightMove{
                .from_square = from_square[0..],
                .to_squares = to_squares.items,
            });
        }
    }

    // const knightMoves = []knightMove;
    // const kms: []knightMove = try std.zon.parse.fromSlice(
    //     knightMoves,
    //     std.heap.page_allocator,
    //     @embedFile("data/knightMoves.zon"),
    //     null,
    //     .{}
    // );

    std.debug.print("Knight moves:\n", .{});

    for (kms) |km| {
        const fs = Square.fromString(km.from_square);
        if (fs.equals(Square.None)) {
            std.debug.print("Invalid from square: {s}\n", .{km.from_square});
            return;
        }
        var bb: bitboard = 0;
        for (km.to_squares) |to_square| {
            const ts = Square.fromString(to_square);
            if (ts.equals(Square.None)) {
                std.debug.print("Invalid to square: {s}\n", .{to_square});
                return;
            }
            bb |= Square.squareBit(@as(usize, @intCast(ts.s)));
        }

        std.debug.print("0x{x:0>16}, // {s}\n", .{bb, fs.toString()});
    }
}
