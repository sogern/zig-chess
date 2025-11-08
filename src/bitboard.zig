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
    0x0020400000000000, // a1
    0x0010a00000000000, // b1
    0x0088500000000000, // c1
    0x0044280000000000, // d1
    0x0022140000000000, // e1
    0x00110a0000000000, // f1
    0x0008050000000000, // g1
    0x0004020000000000, // h1
    0x2000204000000000, // a2
    0x100010a000000000, // b2
    0x8800885000000000, // c2
    0x4400442800000000, // d2
    0x2200221400000000, // e2
    0x1100110a00000000, // f2
    0x0800080500000000, // g2
    0x0400040200000000, // h2
    0x4020002040000000, // a3
    0xa0100010a0000000, // b3
    0x5088008850000000, // c3
    0x2844004428000000, // d3
    0x1422002214000000, // e3
    0x0a1100110a000000, // f3
    0x0508000805000000, // g3
    0x0204000402000000, // h3
    0x0040200020400000, // a4
    0x00a0100010a00000, // b4
    0x0050880088500000, // c4
    0x0028440044280000, // d4
    0x0014220022140000, // e4
    0x000a1100110a0000, // f4
    0x0005080008050000, // g4
    0x0002040004020000, // h4
    0x0000402000204000, // a5
    0x0000a0100010a000, // b5
    0x0000508800885000, // c5
    0x0000284400442800, // d5
    0x0000142200221400, // e5
    0x00000a1100110a00, // f5
    0x0000050800080500, // g5
    0x0000020400040200, // h5
    0x0000004020002040, // a6
    0x000000a0100010a0, // b6
    0x0000005088008850, // c6
    0x0000002844004428, // d6
    0x0000001422002214, // e6
    0x0000000a1100110a, // f6
    0x0000000508000805, // g6
    0x0000000204000402, // h6
    0x0000000040200020, // a7
    0x00000000a0100010, // b7
    0x0000000050880088, // c7
    0x0000000050880088, // c7
    0x0000000028440044, // d7
    0x0000000028440044, // d7
    0x0000000014220022, // e7
    0x0000000014220022, // e7
    0x000000000a110011, // f7
    0x0000000005080008, // g7
    0x0000000002040004, // h7
    0x0000000000402000, // a8
    0x0000000000a01000, // b8
    0x0000000000a01000, // b8
    0x0000000000508800, // c8
    0x0000000000284400, // d8
    0x0000000000142200, // e8
    0x00000000000a1100, // f8
    0x0000000000050800, // g8
    0x0000000000020400, // h8
};

const bbBishopMoves = [_]bitboard{
    0x0040201008040201, // a1
    0x00a0100804020100, // b1
    0x0050880402010000, // c1
    0x0028448201000000, // d1
    0x0014224180000000, // e1
    0x000a112040800000, // f1
    0x0005081020408000, // g1
    0x0002040810204080, // h1
    0x4000402010080402, // a2
    0xa000a01008040201, // b2
    0x5000508804020100, // c2
    0x2800284482010000, // d2
    0x1400142241800000, // e2
    0x0a000a1120408000, // f2
    0x0500050810204080, // g2
    0x0200020408102040, // h2
    0x2040004020100804, // a3
    0x10a000a010080402, // b3
    0x8850005088040201, // c3
    0x4428002844820100, // d3
    0x2214001422418000, // e3
    0x110a000a11204080, // f3
    0x0805000508102040, // g3
    0x0402000204081020, // h3
    0x1020400040201008, // a4
    0x0810a000a0100804, // b4
    0x0488500050880402, // c4
    0x8244280028448201, // d4
    0x4122140014224180, // e4
    0x20110a000a112040, // f4
    0x1008050005081020, // g4
    0x0804020002040810, // h4
    0x0810204000402010, // a5
    0x040810a000a01008, // b5
    0x0204885000508804, // c5
    0x0182442800284482, // d5
    0x8041221400142241, // e5
    0x4020110a000a1120, // f5
    0x2010080500050810, // g5
    0x1008040200020408, // h5
    0x0408102040004020, // a6
    0x02040810a000a010, // b6
    0x0102048850005088, // c6
    0x0001824428002844, // d6
    0x0080412214001422, // e6
    0x804020110a000a11, // f6
    0x4020100805000508, // g6
    0x2010080402000204, // h6
    0x0204081020400040, // a7
    0x0102040810a000a0, // b7
    0x0001020488500050, // c7
    0x0000018244280028, // d7
    0x0000804122140014, // e7
    0x00804020110a000a, // f7
    0x8040201008050005, // g7
    0x4020100804020002, // h7
    0x0102040810204000, // a8
    0x000102040810a000, // b8
    0x0000010204885000, // c8
    0x0000000182442800, // d8
    0x0000008041221400, // e8
    0x0000804020110a00, // f8
    0x0080402010080500, // g8
    0x8040201008040200, // h8
};

const pieceMove = struct {
    from_square: [2]u8,
    to_squares: [][2]u8,
};

fn printPieceMoves(moves: []pieceMove) void {
    for (moves) |km| {
        const fs = Square.fromString(km.from_square[0..]);
        if (fs.equals(Square.None)) {
            std.debug.print("Invalid from square: {s}\n", .{km.from_square});
            return;
        }
        var bb: bitboard = 0;
        for (km.to_squares) |to_square| {
            const ts = Square.fromString(to_square[0..]);
            if (ts.equals(Square.None)) {
                std.debug.print("Invalid to square: {s}\n", .{to_square});
                return;
            }
            bb |= Square.squareBit(@as(usize, @intCast(ts.s)));
        }

        std.debug.print("0x{x:0>16}, // {s}\n", .{ bb, fs.toString() });
    }
}

fn generatePieceMoves(move_offsets: [][2]i8, init_capacity: usize) ![]pieceMove {
    const alloc = std.heap.page_allocator;
    var moves = try std.ArrayList(pieceMove).initCapacity(alloc, init_capacity);

    const files = "abcdefgh";
    const ranks = "12345678";

    for (ranks) |rank_char| {
        const rank_idx = @as(i8, @intCast(rank_char - '1'));
        for (files) |file_char| {
            const f_idx = @as(i8, @intCast(file_char - 'a'));
            const from_square = [_]u8{ file_char, rank_char };
            var to_squares = try std.ArrayList([2]u8).initCapacity(alloc, init_capacity);
            for (move_offsets) |move| {
                const f = f_idx + move[0];
                const r = rank_idx + move[1];
                if (f >= 0 and f < 8 and r >= 0 and r < 8) {
                    const to_square = [_]u8{ @as(u8, @intCast(f + 'a')), @as(u8, @intCast(r + '1')) };
                    try to_squares.append(alloc, to_square);
                }
            }
            const ts = try to_squares.toOwnedSlice(alloc);
            try moves.append(alloc, pieceMove{
                .from_square = from_square,
                .to_squares = ts,
            });
        }
    }

    return try moves.toOwnedSlice(alloc);
}

test "Generate knight moves" {
    const alloc = std.heap.page_allocator;
    var move_offsets = try std.ArrayList([2]i8).initCapacity(alloc, 8);

    // A knight moves in an "L" shape: two squares in one direction and then one square perpendicular.
    // Without board boundaries, a knight has up to 8 possible moves from any square.
    try move_offsets.appendSlice(alloc, &[_][2]i8{
        .{ 2, 1 }, .{ 2, -1 }, .{ -2, 1 }, .{ -2, -1 },
        .{ 1, 2 }, .{ 1, -2 }, .{ -1, 2 }, .{ -1, -2 },
    });
    const moves = try generatePieceMoves(try move_offsets.toOwnedSlice(alloc), 8);
    std.debug.print("Knight moves:\n", .{});
    printPieceMoves(moves);
}

test "Generate bishop moves" {
    const alloc = std.heap.page_allocator;
    var move_offsets = try std.ArrayList([2]i8).initCapacity(alloc, 8 * 4);

    // A bishop moves diagonally any number of squares.
    // Here we define the maximum offsets in each diagonal direction.
    for (1..8) |offset| {
        const o = @as(i8, @intCast(offset));
        try move_offsets.append(alloc, .{ o, o }); // up-right
        try move_offsets.append(alloc, .{ o, -o }); // down-right
        try move_offsets.append(alloc, .{ -o, o }); // up-left
        try move_offsets.append(alloc, .{ -o, -o }); // down-left
    }

    const moves = try generatePieceMoves(try move_offsets.toOwnedSlice(alloc), 13);
    std.debug.print("Bishop moves:\n", .{});
    printPieceMoves(moves);
}
