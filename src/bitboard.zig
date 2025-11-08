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
    // Diagonals from lower left to upper right
    0x8040201008040201, // a1
    0x4020100804020100, // b1
    0x2010080402010000, // c1
    0x1008040201000000, // d1
    0x0804020100000000, // e1
    0x0402010000000000, // f1
    0x0201000000000000, // g1
    0x0100000000000000, // h1
    0x0080402010080402, // a2
    0x8040201008040201, // b2
    0x4020100804020100, // c2
    0x2010080402010000, // d2
    0x1008040201000000, // e2
    0x0804020100000000, // f2
    0x0402010000000000, // g2
    0x0201000000000000, // h2
    0x0000804020100804, // a3
    0x0080402010080402, // b3
    0x8040201008040201, // c3
    0x4020100804020100, // d3
    0x2010080402010000, // e3
    0x1008040201000000, // f3
    0x0804020100000000, // g3
    0x0402010000000000, // h3
    0x0000008040201008, // a4
    0x0000804020100804, // b4
    0x0080402010080402, // c4
    0x8040201008040201, // d4
    0x4020100804020100, // e4
    0x2010080402010000, // f4
    0x1008040201000000, // g4
    0x0804020100000000, // h4
    0x0000000080402010, // a5
    0x0000008040201008, // b5
    0x0000804020100804, // c5
    0x0080402010080402, // d5
    0x8040201008040201, // e5
    0x4020100804020100, // f5
    0x2010080402010000, // g5
    0x1008040201000000, // h5
    0x0000000000804020, // a6
    0x0000000080402010, // b6
    0x0000008040201008, // c6
    0x0000804020100804, // d6
    0x0080402010080402, // e6
    0x8040201008040201, // f6
    0x4020100804020100, // g6
    0x2010080402010000, // h6
    0x0000000000008040, // a7
    0x0000000000804020, // b7
    0x0000000080402010, // c7
    0x0000008040201008, // d7
    0x0000804020100804, // e7
    0x0080402010080402, // f7
    0x8040201008040201, // g7
    0x4020100804020100, // h7
    0x0000000000000080, // a8
    0x0000000000008040, // b8
    0x0000000000804020, // c8
    0x0000000080402010, // d8
    0x0000008040201008, // e8
    0x0000804020100804, // f8
    0x0080402010080402, // g8
    0x8040201008040201, // h8
};

const bbAntiDiagonals = [_]bitboard{
    // Diagonals from upper left to lower right
    0x8000000000000000, // a1
    0x4080000000000000, // b1
    0x2040800000000000, // c1
    0x1020408000000000, // d1
    0x0810204080000000, // e1
    0x0408102040800000, // f1
    0x0204081020408000, // g1
    0x0102040810204080, // h1
    0x4080000000000000, // a2
    0x2040800000000000, // b2
    0x1020408000000000, // c2
    0x0810204080000000, // d2
    0x0408102040800000, // e2
    0x0204081020408000, // f2
    0x0102040810204080, // g2
    0x0001020408102040, // h2
    0x2040800000000000, // a3
    0x1020408000000000, // b3
    0x0810204080000000, // c3
    0x0408102040800000, // d3
    0x0204081020408000, // e3
    0x0102040810204080, // f3
    0x0001020408102040, // g3
    0x0000010204081020, // h3
    0x1020408000000000, // a4
    0x0810204080000000, // b4
    0x0408102040800000, // c4
    0x0204081020408000, // d4
    0x0102040810204080, // e4
    0x0001020408102040, // f4
    0x0000010204081020, // g4
    0x0000000102040810, // h4
    0x0810204080000000, // a5
    0x0408102040800000, // b5
    0x0204081020408000, // c5
    0x0102040810204080, // d5
    0x0001020408102040, // e5
    0x0000010204081020, // f5
    0x0000000102040810, // g5
    0x0000000001020408, // h5
    0x0408102040800000, // a6
    0x0204081020408000, // b6
    0x0102040810204080, // c6
    0x0001020408102040, // d6
    0x0000010204081020, // e6
    0x0000000102040810, // f6
    0x0000000001020408, // g6
    0x0000000000010204, // h6
    0x0204081020408000, // a7
    0x0102040810204080, // b7
    0x0001020408102040, // c7
    0x0000010204081020, // d7
    0x0000000102040810, // e7
    0x0000000001020408, // f7
    0x0000000000010204, // g7
    0x0000000000000102, // h7
    0x0102040810204080, // a8
    0x0001020408102040, // b8
    0x0000010204081020, // c8
    0x0000000102040810, // d8
    0x0000000001020408, // e8
    0x0000000000010204, // f8
    0x0000000000000102, // g8
    0x0000000000000001, // h8
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

const bbRookMoves = [_]bitboard{
    0x7f80808080808080, // a1
    0xbf40404040404040, // b1
    0xdf20202020202020, // c1
    0xef10101010101010, // d1
    0xf708080808080808, // e1
    0xfb04040404040404, // f1
    0xfd02020202020202, // g1
    0xfe01010101010101, // h1
    0x807f808080808080, // a2
    0x40bf404040404040, // b2
    0x20df202020202020, // c2
    0x10ef101010101010, // d2
    0x08f7080808080808, // e2
    0x04fb040404040404, // f2
    0x02fd020202020202, // g2
    0x01fe010101010101, // h2
    0x80807f8080808080, // a3
    0x4040bf4040404040, // b3
    0x2020df2020202020, // c3
    0x1010ef1010101010, // d3
    0x0808f70808080808, // e3
    0x0404fb0404040404, // f3
    0x0202fd0202020202, // g3
    0x0101fe0101010101, // h3
    0x8080807f80808080, // a4
    0x404040bf40404040, // b4
    0x202020df20202020, // c4
    0x101010ef10101010, // d4
    0x080808f708080808, // e4
    0x040404fb04040404, // f4
    0x020202fd02020202, // g4
    0x010101fe01010101, // h4
    0x808080807f808080, // a5
    0x40404040bf404040, // b5
    0x20202020df202020, // c5
    0x10101010ef101010, // d5
    0x08080808f7080808, // e5
    0x04040404fb040404, // f5
    0x02020202fd020202, // g5
    0x01010101fe010101, // h5
    0x80808080807f8080, // a6
    0x4040404040bf4040, // b6
    0x2020202020df2020, // c6
    0x1010101010ef1010, // d6
    0x0808080808f70808, // e6
    0x0404040404fb0404, // f6
    0x0202020202fd0202, // g6
    0x0101010101fe0101, // h6
    0x8080808080807f80, // a7
    0x404040404040bf40, // b7
    0x202020202020df20, // c7
    0x101010101010ef10, // d7
    0x080808080808f708, // e7
    0x040404040404fb04, // f7
    0x020202020202fd02, // g7
    0x010101010101fe01, // h7
    0x808080808080807f, // a8
    0x40404040404040bf, // b8
    0x20202020202020df, // c8
    0x10101010101010ef, // d8
    0x08080808080808f7, // e8
    0x04040404040404fb, // f8
    0x02020202020202fd, // g8
    0x01010101010101fe, // h8
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

test "Generate diagonals" {
    const alloc = std.heap.page_allocator;
    var move_offsets = try std.ArrayList([2]i8).initCapacity(alloc, (2 * 7) + 1);

    // Diagonals from lower left to upper right, including the starting square.
    try move_offsets.append(alloc, .{ 0, 0 }); // starting square
    for (1..8) |offset| {
        const o = @as(i8, @intCast(offset));
        try move_offsets.append(alloc, .{ o, o }); // up-right
        try move_offsets.append(alloc, .{ -o, -o }); // down-left
    }

    const moves = try generatePieceMoves(try move_offsets.toOwnedSlice(alloc), 15);
    std.debug.print("Diagonal moves (lower left to upper right):\n", .{});
    printPieceMoves(moves);
}

test "Generate anti-diagonals" {
    const alloc = std.heap.page_allocator;
    var move_offsets = try std.ArrayList([2]i8).initCapacity(alloc, (2 * 7) + 1);

    // Diagonals from upper left to lower right, including the starting square.
    try move_offsets.append(alloc, .{ 0, 0 }); // starting square
    for (1..8) |offset| {
        const o = @as(i8, @intCast(offset));
        try move_offsets.append(alloc, .{ o, -o }); // up-left
        try move_offsets.append(alloc, .{ -o, o }); // down-right
    }

    const moves = try generatePieceMoves(try move_offsets.toOwnedSlice(alloc), 15);
    std.debug.print("Anti-diagonal moves (upper left to lower right):\n", .{});
    printPieceMoves(moves);
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
    var move_offsets = try std.ArrayList([2]i8).initCapacity(alloc, 7 * 4);

    // A bishop moves diagonally any number of squares.
    // Without board boundaries, a bishop has up to 32 possible moves from any square.
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

test "Generate rook moves" {
    const alloc = std.heap.page_allocator;
    var move_offsets = try std.ArrayList([2]i8).initCapacity(alloc, 7 * 4);

    // A rook moves horizontally or vertically any number of squares.
    // Without board boundaries, a rook has up to 28 possible moves from any square.
    for (1..8) |offset| {
        const o = @as(i8, @intCast(offset));
        try move_offsets.append(alloc, .{ o, 0 }); // right
        try move_offsets.append(alloc, .{ -o, 0 }); // left
        try move_offsets.append(alloc, .{ 0, o }); // up
        try move_offsets.append(alloc, .{ 0, -o }); // down
    }

    const moves = try generatePieceMoves(try move_offsets.toOwnedSlice(alloc), 14);
    std.debug.print("Rook moves:\n", .{});
    printPieceMoves(moves);
}
