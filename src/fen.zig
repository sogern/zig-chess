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

fn fenCastlingRights(board: Board, castling: *CastlingRights, castlingStr: []const u8) !void {
    if (castlingStr.len == 0 or castlingStr[0] == '-') {
        castling.* = CastlingRights{};
        return;
    }

    for (castlingStr) |c| {
        switch (c) {
            'K' => try castling.updateCastlingRights(Colour.White, CastlingSide.Kingside, 4, 7),
            'k' => try castling.updateCastlingRights(Colour.Black, CastlingSide.Kingside, 4, 7),
            'Q' => try castling.updateCastlingRights(Colour.White, CastlingSide.Queenside, 4, 0),
            'q' => try castling.updateCastlingRights(Colour.Black, CastlingSide.Queenside, 4, 0),
            else => {
                // Chess960 castling FEN
                if (c >= 'A' and c <= 'H') {
                    const colour = Colour.White;
                    const ks = board.getKingSquare(colour);
                    if (ks.equals(Square.None)) {
                        return FENError.InvalidCastlingRightsForGivenBoard;
                    }
                    const rf = @as(i8, @intCast(c - 'A'));
                    if (rf < ks.f) {
                        try castling.updateCastlingRights(colour, CastlingSide.Queenside, ks.f, rf);
                    } else {
                        try castling.updateCastlingRights(colour, CastlingSide.Kingside, ks.f, rf);
                    }
                } else if (c >= 'a' and c <= 'h') {
                    const colour = Colour.Black;
                    const ks = board.getKingSquare(colour);
                    if (ks.equals(Square.None)) {
                        return FENError.InvalidCastlingRightsForGivenBoard;
                    }
                    const rf = @as(i8, @intCast(c - 'a'));
                    if (rf < ks.f) {
                        try castling.updateCastlingRights(colour, CastlingSide.Queenside, ks.f, rf);
                    } else {
                        try castling.updateCastlingRights(colour, CastlingSide.Kingside, ks.f, rf);
                    }
                } else {
                    return FENError.InvalidFEN;
                }
            },
        }
    }
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

test "decodeFEN valid FEN" {
    std.debug.print("Decoding valid FEN...\n", .{});
    const position = try decodeFEN(startFEN);

    // std.debug.print("Board after decoding FEN:\n{s}\n", .{position.board.toDebugString()});
    const expected = "  a b c d e f g h\n"
        ++ "  ---------------\n"
        ++ "8 r n b q k b n r\n"
        ++ "7 p p p p p p p p\n"
        ++ "6                \n"
        ++ "5                \n"
        ++ "4                \n"
        ++ "3                \n"
        ++ "2 P P P P P P P P\n"
        ++ "1 R N B Q K B N R\n"
        ++ "  ---------------\n";
    try std.testing.expectEqualStrings(expected, position.board.toDebugString());

    try std.testing.expectEqual(Square.A1Bit + Square.H1Bit, position.board.whiteRooks);
    try std.testing.expectEqual(Square.B1Bit + Square.G1Bit, position.board.whiteKnights);
    try std.testing.expectEqual(Square.C1Bit + Square.F1Bit, position.board.whiteBishops);
    try std.testing.expectEqual(Square.D1Bit, position.board.whiteQueen);
    try std.testing.expectEqual(Square.E1Bit, position.board.whiteKing);
    try std.testing.expectEqual(Square.A2Bit + Square.B2Bit +
        Square.C2Bit + Square.D2Bit +
        Square.E2Bit + Square.F2Bit +
        Square.G2Bit + Square.H2Bit, position.board.whitePawns);
    try std.testing.expectEqual(Square.A8Bit + Square.H8Bit, position.board.blackRooks);
    try std.testing.expectEqual(Square.B8Bit + Square.G8Bit, position.board.blackKnights);
    try std.testing.expectEqual(Square.C8Bit + Square.F8Bit, position.board.blackBishops);
    try std.testing.expectEqual(Square.D8Bit, position.board.blackQueen);
    try std.testing.expectEqual(Square.E8Bit, position.board.blackKing);
    try std.testing.expectEqual(Square.A7Bit + Square.B7Bit +
        Square.C7Bit + Square.D7Bit +
        Square.E7Bit + Square.F7Bit +
        Square.G7Bit + Square.H7Bit, position.board.blackPawns);
    try std.testing.expectEqual(Square.A3Bit + Square.A4Bit +
        Square.A5Bit + Square.A6Bit +
        Square.B3Bit + Square.B4Bit +
        Square.B5Bit + Square.B6Bit +
        Square.C3Bit + Square.C4Bit +
        Square.C5Bit + Square.C6Bit +
        Square.D3Bit + Square.D4Bit +
        Square.D5Bit + Square.D6Bit +
        Square.E3Bit + Square.E4Bit +
        Square.E5Bit + Square.E6Bit +
        Square.F3Bit + Square.F4Bit +
        Square.F5Bit + Square.F6Bit +
        Square.G3Bit + Square.G4Bit +
        Square.G5Bit + Square.G6Bit +
        Square.H3Bit + Square.H4Bit +
        Square.H5Bit + Square.H6Bit, position.board.emptySquares);
}

test "decodeFEN enPassant square" {
    std.debug.print("Decoding FEN with en passant square...\n", .{});
    const fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1";
    const position = try decodeFEN(fen);

    const expected = Square.fromFileAndRank(Square.FileE, Square.Rank3);
    try std.testing.expectEqual(expected, position.enPassantSquare);
}