const std = @import("std");

const Position = @import("position.zig").Position;
const Board = @import("board.zig").Board;
const Piece = @import("piece.zig").Piece;
const Colour = @import("piece.zig").Colour;
const CastlingRights = @import("castling.zig").CastlingRights;
const CastlingSide = @import("castling.zig").CastlingSide;
const PieceError = @import("piece.zig").PieceError;
const Square = @import("square.zig").Square;
const File = @import("file.zig").File;
const Rank = @import("rank.zig").Rank;

pub const startFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

pub const FENError = error{
    InvalidFEN,
    InvalidBoard,
    InvalidCastlingRightsForGivenBoard,
    InvalidEnPassantSquare,
    InvalidHalfMoveClock,
    InvalidMoveCount,
};

pub fn decodeFEN(fen: []const u8) !Position {
    // Split the FEN string into parts
    var it = std.mem.splitScalar(u8, fen, ' ');

    var position = Position{};

    var partsCount: usize = 0;
    while (it.next()) |p| {
        switch (partsCount) {
            0 => {
                try fenBoard(&position.board, p);
            },
            1 => {
                if (p.len != 1) {
                    return FENError.InvalidFEN;
                }
                position.turn = Colour.fromChar(p[0]);
                if (position.turn == Colour.None) {
                    return FENError.InvalidFEN;
                }
            },
            2 => {
                try fenCastlingRights(position.board, &position.castling, p);
            },
            3 => {
                try fenEnPassantSquare(&position.enPassantSquare, p);
            },
            4 => {
                try fenInt32Field(&position.halfMoveClock, p, 0, FENError.InvalidHalfMoveClock);
            },
            5 => {
                try fenInt32Field(&position.moveCount, p, 1, FENError.InvalidMoveCount);
            },
            else => return FENError.InvalidFEN,
        }
        partsCount += 1;
    }

    return position;
}

fn fenBoard(board: *Board, boardStr: []const u8) !void {
    // std.debug.print("boardStr={s}\n", .{boardStr});
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
                try board.placePiece(piece, Square.fromIndex(rank * 8 + fileIndex));
                // std.debug.print("Placed piece {c} at rank {d}, file {d}\n", .{piece.toChar(), rank, fileIndex});
                fileIndex += 1;
            }
        }
    }
}

fn fenCastlingRights(_: Board, castling: *CastlingRights, castlingStr: []const u8) !void {
    castling.* = try CastlingRights.fromString(castlingStr, File.E);
}

fn fenEnPassantSquare(enPassantSquare: *Square, enPassantStr: []const u8) !void {
    if (enPassantStr.len == 0 or enPassantStr[0] == '-') {
        enPassantSquare.* = Square.None;
        return;
    }

    const s = Square.fromString(enPassantStr);
    if (s == .None) {
        return FENError.InvalidFEN;
    }
    if (s.rank() != .@"3" and s.rank() != .@"6") {
        return FENError.InvalidEnPassantSquare;
    }

    enPassantSquare.* = s;
}

fn fenInt32Field(field: *i32, fieldStr: []const u8, minVal: i32, fenError: FENError) !void {
    const value = std.fmt.parseInt(i32, fieldStr, 10) catch |err| {
        return err;
    };
    if (value < minVal) {
        return fenError;
    }
    field.* = value;
}

test "decodeFEN start position" {
    const alloc = std.testing.allocator;
    std.debug.print("Decoding valid FEN...\n", .{});
    const position = try decodeFEN(startFEN);

    // std.debug.print("Board after decoding FEN:\n{s}\n", .{position.board.draw()});
    const expected = "  a b c d e f g h\n"
        ++ "8 r n b q k b n r\n"
        ++ "7 p p p p p p p p\n"
        ++ "6                \n"
        ++ "5                \n"
        ++ "4                \n"
        ++ "3                \n"
        ++ "2 P P P P P P P P\n"
        ++ "1 R N B Q K B N R\n";
    // std.debug.print("Board:\n{s}", .{position.board.draw()});
    const board_str = position.board.draw(alloc);
    defer alloc.free(board_str);
    try std.testing.expectEqualStrings(expected, board_str);
    // position.board.debugInternalBitboards();
    try std.testing.expectEqual(Square.A1.bitmask() + Square.H1.bitmask(), position.board.whiteRooks);
    try std.testing.expectEqual(Square.B1.bitmask() + Square.G1.bitmask(), position.board.whiteKnights);
    try std.testing.expectEqual(Square.C1.bitmask() + Square.F1.bitmask(), position.board.whiteBishops);
    try std.testing.expectEqual(Square.D1.bitmask(), position.board.whiteQueen);
    try std.testing.expectEqual(Square.E1.bitmask(), position.board.whiteKing);
    try std.testing.expectEqual(Square.A2.bitmask() + Square.B2.bitmask() +
        Square.C2.bitmask() + Square.D2.bitmask() +
        Square.E2.bitmask() + Square.F2.bitmask() +
        Square.G2.bitmask() + Square.H2.bitmask(), position.board.whitePawns);
    try std.testing.expectEqual(Square.A8.bitmask() + Square.H8.bitmask(), position.board.blackRooks);
    try std.testing.expectEqual(Square.B8.bitmask() + Square.G8.bitmask(), position.board.blackKnights);
    try std.testing.expectEqual(Square.C8.bitmask() + Square.F8.bitmask(), position.board.blackBishops);
    try std.testing.expectEqual(Square.D8.bitmask(), position.board.blackQueen);
    try std.testing.expectEqual(Square.E8.bitmask(), position.board.blackKing);
    try std.testing.expectEqual(Square.A7.bitmask() + Square.B7.bitmask() +
        Square.C7.bitmask() + Square.D7.bitmask() +
        Square.E7.bitmask() + Square.F7.bitmask() +
        Square.G7.bitmask() + Square.H7.bitmask(), position.board.blackPawns);
    try std.testing.expectEqual(Square.A3.bitmask() + Square.A4.bitmask() +
        Square.A5.bitmask() + Square.A6.bitmask() +
        Square.B3.bitmask() + Square.B4.bitmask() +
        Square.B5.bitmask() + Square.B6.bitmask() +
        Square.C3.bitmask() + Square.C4.bitmask() +
        Square.C5.bitmask() + Square.C6.bitmask() +
        Square.D3.bitmask() + Square.D4.bitmask() +
        Square.D5.bitmask() + Square.D6.bitmask() +
        Square.E3.bitmask() + Square.E4.bitmask() +
        Square.E5.bitmask() + Square.E6.bitmask() +
        Square.F3.bitmask() + Square.F4.bitmask() +
        Square.F5.bitmask() + Square.F6.bitmask() +
        Square.G3.bitmask() + Square.G4.bitmask() +
        Square.G5.bitmask() + Square.G6.bitmask() +
        Square.H3.bitmask() + Square.H4.bitmask() +
        Square.H5.bitmask() + Square.H6.bitmask(), position.board.emptySquares);

    try std.testing.expectEqual(Colour.White, position.turn);
    try std.testing.expectEqual(Square.None, position.enPassantSquare);
    try std.testing.expectEqual(0, position.halfMoveClock);
    try std.testing.expectEqual(1, position.moveCount);
}

test "decodeFEN valid FEN" {
    std.debug.print("Decoding FEN with en passant square...\n", .{});
    const fen = "rnbqkb1r/ppp2ppp/3p1n2/4p3/4P3/3B1N2/PPPP1PPP/RNBQ1RK1 b kq - 1 4";
    const position = try decodeFEN(fen);

    try std.testing.expectEqual(Square.None, position.enPassantSquare);
    try std.testing.expectEqual(Colour.Black, position.turn);
    try std.testing.expectEqualStrings("kq", position.castling.toString());
    try std.testing.expectEqual(1, position.halfMoveClock);
    try std.testing.expectEqual(4, position.moveCount);
}