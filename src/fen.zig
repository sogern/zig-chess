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
            0 => |_| {
                try fenBoard(&position.board, p);
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
                try fenCastlingRights(position.board, &position.castling, p);
            },
            3 => |_| {
                try fenEnPassantSquare(&position.enPassantSquare, p);
            },
            4 => |_| {
                try fenInt32Field(&position.halfMoveClock, p, 0, FENError.InvalidHalfMoveClock);
            },
            5 => |_| {
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
                try board.placePiece(piece, Square.fromFileAndRank(@as(i8, @intCast(fileIndex)), @as(i8, @intCast(rank))));
                // std.debug.print("Placed piece {c} at rank {d}, file {d}\n", .{piece.toChar(), rank, fileIndex});
                fileIndex += 1;
            }
        }
    }
}

fn fenCastlingRights(_: Board, castling: *CastlingRights, castlingStr: []const u8) !void {
    castling.* = try CastlingRights.fromString(castlingStr, Square.FileE);
}

fn fenEnPassantSquare(enPassantSquare: *Square, enPassantStr: []const u8) !void {
    if (enPassantStr.len == 0 or enPassantStr[0] == '-') {
        enPassantSquare.* = Square.None;
        return;
    }

    const s = Square.fromString(enPassantStr);
    if (s.equals(Square.None)) {
        return FENError.InvalidFEN;
    }
    if (s.r != Square.Rank3 and s.r != Square.Rank6) {
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
    std.debug.print("Decoding valid FEN...\n", .{});
    const position = try decodeFEN(startFEN);

    // std.debug.print("Board after decoding FEN:\n{s}\n", .{position.board.draw()});
    const expected = "  A B C D E F G H\n"
        ++ "8 r n b q k b n r\n"
        ++ "7 p p p p p p p p\n"
        ++ "6                \n"
        ++ "5                \n"
        ++ "4                \n"
        ++ "3                \n"
        ++ "2 P P P P P P P P\n"
        ++ "1 R N B Q K B N R\n";
    // std.debug.print("Board:\n{s}", .{position.board.draw()});
    try std.testing.expectEqualStrings(expected, position.board.draw());
    // position.board.debugInternalBitboards();
    try std.testing.expectEqual(Square.squareBit(Square.A1) + Square.squareBit(Square.H1), position.board.whiteRooks);
    try std.testing.expectEqual(Square.squareBit(Square.B1) + Square.squareBit(Square.G1), position.board.whiteKnights);
    try std.testing.expectEqual(Square.squareBit(Square.C1) + Square.squareBit(Square.F1), position.board.whiteBishops);
    try std.testing.expectEqual(Square.squareBit(Square.D1), position.board.whiteQueen);
    try std.testing.expectEqual(Square.squareBit(Square.E1), position.board.whiteKing);
    try std.testing.expectEqual(Square.squareBit(Square.A2) + Square.squareBit(Square.B2) +
        Square.squareBit(Square.C2) + Square.squareBit(Square.D2) +
        Square.squareBit(Square.E2) + Square.squareBit(Square.F2) +
        Square.squareBit(Square.G2) + Square.squareBit(Square.H2), position.board.whitePawns);
    try std.testing.expectEqual(Square.squareBit(Square.A8) + Square.squareBit(Square.H8), position.board.blackRooks);
    try std.testing.expectEqual(Square.squareBit(Square.B8) + Square.squareBit(Square.G8), position.board.blackKnights);
    try std.testing.expectEqual(Square.squareBit(Square.C8) + Square.squareBit(Square.F8), position.board.blackBishops);
    try std.testing.expectEqual(Square.squareBit(Square.D8), position.board.blackQueen);
    try std.testing.expectEqual(Square.squareBit(Square.E8), position.board.blackKing);
    try std.testing.expectEqual(Square.squareBit(Square.A7) + Square.squareBit(Square.B7) +
        Square.squareBit(Square.C7) + Square.squareBit(Square.D7) +
        Square.squareBit(Square.E7) + Square.squareBit(Square.F7) +
        Square.squareBit(Square.G7) + Square.squareBit(Square.H7), position.board.blackPawns);
    try std.testing.expectEqual(Square.squareBit(Square.A3) + Square.squareBit(Square.A4) +
        Square.squareBit(Square.A5) + Square.squareBit(Square.A6) +
        Square.squareBit(Square.B3) + Square.squareBit(Square.B4) +
        Square.squareBit(Square.B5) + Square.squareBit(Square.B6) +
        Square.squareBit(Square.C3) + Square.squareBit(Square.C4) +
        Square.squareBit(Square.C5) + Square.squareBit(Square.C6) +
        Square.squareBit(Square.D3) + Square.squareBit(Square.D4) +
        Square.squareBit(Square.D5) + Square.squareBit(Square.D6) +
        Square.squareBit(Square.E3) + Square.squareBit(Square.E4) +
        Square.squareBit(Square.E5) + Square.squareBit(Square.E6) +
        Square.squareBit(Square.F3) + Square.squareBit(Square.F4) +
        Square.squareBit(Square.F5) + Square.squareBit(Square.F6) +
        Square.squareBit(Square.G3) + Square.squareBit(Square.G4) +
        Square.squareBit(Square.G5) + Square.squareBit(Square.G6) +
        Square.squareBit(Square.H3) + Square.squareBit(Square.H4) +
        Square.squareBit(Square.H5) + Square.squareBit(Square.H6), position.board.emptySquares);

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