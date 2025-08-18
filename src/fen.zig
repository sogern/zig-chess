const std = @import("std");

const Position = @import("position.zig").Position;
const Board = @import("board.zig").Board;
const Piece = @import("piece.zig").Piece;
const Colour = @import("piece.zig").Colour;
const CastlingRights = @import("castling.zig").CastlingRights;
const CastlingSide = @import("castling.zig").CastlingSide;
const PieceError = @import("piece.zig").PieceError;
const Square = @import("square.zig").Square;

pub const startFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

pub const FENError = error{
    InvalidFEN,
    InvalidBoard,
};

pub fn decodeFEN(alloc: std.mem.Allocator, fen: []const u8) !*Position {
    // Split the FEN string into parts
    var it = std.mem.splitScalar(u8, fen, ' ');

    const position = try Position.create(alloc);

    var partsCount: usize = 0;
    while (it.next()) |p| {
        switch (partsCount) {
            0 => |_| {
                try fenBoard(alloc, position.board, p);
            },
            1 => |_| {
                if (p.len != 1) {
                    return FENError.InvalidFEN;
                }
                position.turn = Colour.fromChar(p[0]);
                if (position.turn == Colour.None) {
                    return FENError.InvalidFEN;
                }
            },
            2 => |_| {
                try fenCastlingRights(alloc, position.board, &position.castling, p);
            },
            3 => |_| {},
            4 => |_| {},
            5 => |_| {},
            else => return FENError.InvalidFEN,
        }
        partsCount += 1;
    }

    return position;
}

pub fn fenBoard(_: std.mem.Allocator, board: *Board, boardStr: []const u8) !void {
    std.debug.print("boardStr={s}\n", .{boardStr});
    var rankCount: usize = 0;
    var start: usize = 0;
    var rankBuffer: [8][]const u8 = undefined;
    for (0..boardStr.len) |i| {
        // std.debug.print("i={d}\n", .{ i });
        if (rankCount == 7 and i == boardStr.len - 1) {
            // std.debug.print("final rank\n", .{});
            const rankStr = boardStr[start .. i + 1];
            // std.debug.print("rankCount={d}, rankStr={s}\n", .{ rankCount, rankStr });
            rankBuffer[rankCount] = rankStr;
            rankCount += 1;
        } else if (rankCount < 7 and boardStr[i] == '/') {
            const rankStr = boardStr[start..i];
            // std.debug.print("rankCount={d}, rankStr={s}\n", .{ rankCount, rankStr });
            rankBuffer[rankCount] = rankStr;
            rankCount += 1;
            start = i + 1;
        }
    }

    if (rankCount != 8) {
        // std.debug.print("rankCount={d}\n", .{ rankCount });
        return FENError.InvalidBoard;
    }

    for (0..8) |rankIndex| {
        const rankStr = rankBuffer[rankIndex];
        var fileIndex: usize = 0;
        for (rankStr) |c| {
            if (c >= '1' and c <= '8') {
                fileIndex += @as(usize, @intCast(c)) - @as(usize, @intCast('0'));
            } else {
                const rank = 7 - rankIndex; // FEN starts with rank 8
                const piece = Piece.fromChar(c);
                if (piece == Piece.None) {
                    return PieceError.InvalidPiece;
                }
                try board.placePiece(piece, Square.fromFileAndRank(@as(i8, @intCast(fileIndex)), @as(i8, @intCast(rank))));
                // std.debug.print("Placed piece {c} at rank {d}, file {d}\n", .{piece.toChar(), rank, fileIndex});
                fileIndex += 1;
            }
        }
    }
}

pub fn fenCastlingRights(_: std.mem.Allocator, _: *Board, castling: *CastlingRights, castlingStr: []const u8) !void {
    if (castlingStr.len == 0 or castlingStr[0] == '-') {
        castling.* = CastlingRights.init();
        return;
    }

    for (castlingStr) |c| {
        if (c != 'K' or c != 'k' or c != 'Q' or c != 'q' or ((c < 'A' or c > 'H') and (c < 'a' or c > 'h'))) {
            return FENError.InvalidFEN;
        }
        switch (c) {
            'K' => try castling.updateCastlingRights(Colour.White, CastlingSide.Kingside, 4, 7),
            'k' => try castling.updateCastlingRights(Colour.Black, CastlingSide.Kingside, 4, 7),
            'Q' => try castling.updateCastlingRights(Colour.White, CastlingSide.Queenside, 4, 0),
            'q' => try castling.updateCastlingRights(Colour.Black, CastlingSide.Queenside, 4, 0),
            else => {
                // Chess960 castling FEN
                // var kf: i8 = 0;
                // if (c >= 'A' and c <= 'H') {
                //     const colour = Colour.White;
                // } else if (c >= 'a' and c <= 'h') {
                //     kf = @intCast(c - 'a');
                // } else {
                //     return FENError.InvalidFEN;
                // }
            },
        }
    }
}

test "decodeFEN valid FEN" {
    std.debug.print("Decoding valid FEN...\n", .{});
    const alloc = std.testing.allocator;
    const position = try decodeFEN(alloc, startFEN);
    defer {
        position.deinit();
        alloc.destroy(position);
    }

    // Check if the board is initialized correctly
    std.debug.print("Board after decoding FEN:\n{s}\n", .{position.board.toDebugString()});
    try std.testing.expect(position.board.whiteRooks == (@as(u64, 1) << Square.A1) + (@as(u64, 1) << Square.H1));
    try std.testing.expect(position.board.whiteKnights == (@as(u64, 1) << Square.B1) + (@as(u64, 1) << Square.G1));
    try std.testing.expect(position.board.whiteBishops == (@as(u64, 1) << Square.C1) + (@as(u64, 1) << Square.F1));
    try std.testing.expect(position.board.whiteQueen == (@as(u64, 1) << Square.D1));
    try std.testing.expect(position.board.whiteKing == (@as(u64, 1) << Square.E1));
    try std.testing.expect(position.board.whitePawns ==
        (@as(u64, 1) << Square.A2) + (@as(u64, 1) << Square.B2) +
            (@as(u64, 1) << Square.C2) + (@as(u64, 1) << Square.D2) +
            (@as(u64, 1) << Square.E2) + (@as(u64, 1) << Square.F2) +
            (@as(u64, 1) << Square.G2) + (@as(u64, 1) << Square.H2));
    try std.testing.expect(position.board.blackRooks == (@as(u64, 1) << Square.A8) + (@as(u64, 1) << Square.H8));
    try std.testing.expect(position.board.blackKnights == (@as(u64, 1) << Square.B8) + (@as(u64, 1) << Square.G8));
    try std.testing.expect(position.board.blackBishops == (@as(u64, 1) << Square.C8) + (@as(u64, 1) << Square.F8));
    try std.testing.expect(position.board.blackQueen == (@as(u64, 1) << Square.D8));
    try std.testing.expect(position.board.blackKing == (@as(u64, 1) << Square.E8));
    try std.testing.expect(position.board.blackPawns ==
        (@as(u64, 1) << Square.A7) + (@as(u64, 1) << Square.B7) +
            (@as(u64, 1) << Square.C7) + (@as(u64, 1) << Square.D7) +
            (@as(u64, 1) << Square.E7) + (@as(u64, 1) << Square.F7) +
            (@as(u64, 1) << Square.G7) + (@as(u64, 1) << Square.H7));
    try std.testing.expect(position.board.emptySquares ==
        (@as(u64, 1) << Square.A3) + (@as(u64, 1) << Square.A4) +
            (@as(u64, 1) << Square.A5) + (@as(u64, 1) << Square.A6) +
            (@as(u64, 1) << Square.B3) + (@as(u64, 1) << Square.B4) +
            (@as(u64, 1) << Square.B5) + (@as(u64, 1) << Square.B6) +
            (@as(u64, 1) << Square.C3) + (@as(u64, 1) << Square.C4) +
            (@as(u64, 1) << Square.C5) + (@as(u64, 1) << Square.C6) +
            (@as(u64, 1) << Square.D3) + (@as(u64, 1) << Square.D4) +
            (@as(u64, 1) << Square.D5) + (@as(u64, 1) << Square.D6) +
            (@as(u64, 1) << Square.E3) + (@as(u64, 1) << Square.E4) +
            (@as(u64, 1) << Square.E5) + (@as(u64, 1) << Square.E6) +
            (@as(u64, 1) << Square.F3) + (@as(u64, 1) << Square.F4) +
            (@as(u64, 1) << Square.F5) + (@as(u64, 1) << Square.F6) +
            (@as(u64, 1) << Square.G3) + (@as(u64, 1) << Square.G4) +
            (@as(u64, 1) << Square.G5) + (@as(u64, 1) << Square.G6) +
            (@as(u64, 1) << Square.H3) + (@as(u64, 1) << Square.H4) +
            (@as(u64, 1) << Square.H5) + (@as(u64, 1) << Square.H6));
}