const std = @import("std");
const Colour = @import("piece.zig").Colour;
const Square = @import("square.zig").Square;

pub const CastlingError = error {
    InvalidCastlingRights,
};

pub const CastlingSide = enum(u8) {
    Queenside,
    Kingside,
    None,
};

/// CastlingRights holds four u8 values representing the right for each colour and side to perform castling.
/// It also holds the starting file of the king,
/// and a boolean indicating whether the castling rights are in standard FEN notation or X-FEN notation for Chess960.
pub const CastlingRights = packed struct {
    whiteKingSide: u8 = ' ',
    whiteQueenSide: u8 = ' ',
    blackKingSide: u8 = ' ',
    blackQueenSide: u8 = ' ',

    kingFile: u8 = 0,
    standard: bool = true,

    // inline fn validFile(f: i8) bool {
    //     return f >= @as(i8, 0) and f <= @as(i8, 7);
    // }

    // inline fn validSide(side: CastlingSide, kf: i8, rf: i8) bool {
    //     if (side == CastlingSide.None) {
    //         return false;
    //     }
    //     if (side == CastlingSide.Kingside) {
    //         return rf > kf;
    //     } else {
    //         return rf < kf;
    //     }
    // }

    pub fn whiteKingSideRookSquare(self: CastlingRights) Square {
        return switch (self.whiteKingSide) {
            'K' => Square.fromIndex(Square.H1),
            'A'...'H' => Square.fromFileAndRank(@as(i8, @intCast(self.whiteKingSide - 'A')), 0),
            else => Square.None,
        };
    }

    pub fn whiteQueenSideRookSquare(self: CastlingRights) Square {
        return switch (self.whiteQueenSide) {
            'Q' => Square.fromIndex(Square.A1),
            'A'...'H' => Square.fromFileAndRank(@as(i8, @intCast(self.whiteQueenSide - 'A')), 0),
            else => Square.None,
        };
    }

    pub fn blackKingSideRookSquare(self: CastlingRights) Square {
        return switch (self.blackKingSide) {
            'k' => Square.fromIndex(Square.H8),
            'a'...'h' => Square.fromFileAndRank(@as(i8, @intCast(self.blackKingSide - 'a')), 7),
            else => Square.None,
        };
    }

    pub fn blackQueenSideRookSquare(self: CastlingRights) Square {
        return switch (self.blackQueenSide) {
            'q' => Square.fromIndex(Square.A8),
            'a'...'h' => Square.fromFileAndRank(@as(i8, @intCast(self.blackQueenSide - 'a')), 7),
            else => Square.None,
        };
    }

    /// Creates CastlingRights from FEN notation.
    pub fn fromString(rightsStr: []const u8, kingFile: comptime_int) !CastlingRights {
        // The king can only be on files B-G for castling to be possible
        if (kingFile < Square.FileB or kingFile > Square.FileG) {
            return CastlingError.InvalidCastlingRights;
        }
        var whiteKingSide: u8 = ' ';
        var whiteQueenSide: u8 = ' ';
        var blackKingSide: u8 = ' ';
        var blackQueenSide: u8 = ' ';

        var standard: bool = true;

        for (rightsStr) |c| {
            switch (c) {
                // Standard FEN notation for castling rights
                'K' => {
                    whiteKingSide = c;
                },
                'Q' => {
                    whiteQueenSide = c;
                },
                'k' => {
                    blackKingSide = c;
                },
                'q' => {
                    blackQueenSide = c;
                },

                // X-FEN notation for Chess960 castling rights
                'A'...'H' => {
                    standard = false;
                    if (c < @as(u8, kingFile + 'A')) {
                        whiteQueenSide = c;
                    } else if (c > @as(u8, kingFile + 'A')) {
                        whiteKingSide = c;
                    } else {
                        return CastlingError.InvalidCastlingRights;
                    }
                },
                'a'...'h' => {
                    standard = false;
                    if (c < @as(u8, kingFile + 'a')) {
                        blackQueenSide = c;
                    } else if (c > @as(u8, kingFile + 'a')) {
                        blackKingSide = c;
                    } else {
                        return CastlingError.InvalidCastlingRights;
                    }
                },
                '-' => {}, // No castling rights
                else => return CastlingError.InvalidCastlingRights,
            }
        }
        // std.debug.print("Parsed castling rights: white={b}, black={b}, c960={s}\n", .{white, black, if (c960) "true" else "false"});
        return .{
            .whiteKingSide = whiteKingSide, .whiteQueenSide = whiteQueenSide,
            .blackKingSide = blackKingSide, .blackQueenSide = blackQueenSide,
            .kingFile = @as(u8, kingFile),
            .standard = standard
        };
    }

    pub fn toString(self: CastlingRights) []const u8 {
        var result: [4]u8 = .{ 0, 0, 0, 0 };
        var idx: usize = 0;

        // White castling rights
        if (self.whiteKingSide != ' ') {
            if (self.standard) {
                result[idx] = 'K';
            } else {
                result[idx] = self.whiteKingSide;
            }
            idx += 1;
        }
        if (self.whiteQueenSide != ' ') {
            if (self.standard) {
                result[idx] = 'Q';
            } else {
                result[idx] = self.whiteQueenSide;
            }
            idx += 1;
        }

        // Black castling rights
        if (self.blackKingSide != ' ') {
            if (self.standard) {
                result[idx] = 'k';
            } else {
                result[idx] = self.blackKingSide;
            }
            idx += 1;
        }
        if (self.blackQueenSide != ' ') {
            if (self.standard) {
                result[idx] = 'q';
            } else {
                result[idx] = self.blackQueenSide;
            }
            idx += 1;
        }

        if (idx == 0) {
            return "-";
        }
        return result[0..idx];
    }

    pub fn removeAllCastlingRights(self: CastlingRights, colour: Colour) !CastlingRights {
        return switch (colour) {
            .White => .{
                .whiteKingSide = ' ',
                .whiteQueenSide = ' ',
                .blackKingSide = self.blackKingSide,
                .blackQueenSide = self.blackQueenSide,
                .kingFile = self.kingFile,
                .standard = self.standard
            },
            .Black => .{
                .whiteKingSide = self.whiteKingSide,
                .whiteQueenSide = self.whiteQueenSide,
                .blackKingSide = ' ',
                .blackQueenSide = ' ',
                .kingFile = self.kingFile,
                .standard = self.standard
            },
            .None => CastlingError.InvalidCastlingRights,
        };
    }

    pub fn removeCastlingRight(self: CastlingRights, colour: Colour, side: CastlingSide) !CastlingRights {
        if (side == .None or colour == .None) {
            return CastlingError.InvalidCastlingRights;
        }
        return switch (colour) {
            .White => switch (side) {
                .Kingside => .{
                    .whiteKingSide = ' ',
                    .whiteQueenSide = self.whiteQueenSide,
                    .blackKingSide = self.blackKingSide,
                    .blackQueenSide = self.blackQueenSide,
                    .kingFile = self.kingFile,
                    .standard = self.standard
                },
                .Queenside => .{
                    .whiteKingSide = self.whiteKingSide,
                    .whiteQueenSide = ' ',
                    .blackKingSide = self.blackKingSide,
                    .blackQueenSide = self.blackQueenSide,
                    .kingFile = self.kingFile,
                    .standard = self.standard
                },
                else => CastlingError.InvalidCastlingRights,
            },
            .Black => switch (side) {
                .Kingside => .{
                    .whiteKingSide = self.whiteKingSide,
                    .whiteQueenSide = self.whiteQueenSide,
                    .blackKingSide = ' ',
                    .blackQueenSide = self.blackQueenSide,
                    .kingFile = self.kingFile,
                    .standard = self.standard
                },
                .Queenside => .{
                    .whiteKingSide = self.whiteKingSide,
                    .whiteQueenSide = self.whiteQueenSide,
                    .blackKingSide = self.blackKingSide,
                    .blackQueenSide = ' ',
                    .kingFile = self.kingFile,
                    .standard = self.standard
                },
                else => CastlingError.InvalidCastlingRights,
            },
            else => CastlingError.InvalidCastlingRights,
        };
    }
};

test "Castling rights" {
    std.debug.print("Testing castling rights...\n", .{});

    var rights = try CastlingRights.fromString("KQkq", Square.FileE);
    try std.testing.expectEqualStrings("KQkq", rights.toString());
    try std.testing.expectEqual(Square.fromIndex(Square.H1), rights.whiteKingSideRookSquare());
    try std.testing.expectEqual(Square.fromIndex(Square.A1), rights.whiteQueenSideRookSquare());
    try std.testing.expectEqual(Square.fromIndex(Square.H8), rights.blackKingSideRookSquare());
    try std.testing.expectEqual(Square.fromIndex(Square.A8), rights.blackQueenSideRookSquare());

    rights = try rights.removeAllCastlingRights(Colour.White);
    try std.testing.expectEqualStrings("kq", rights.toString());

    rights = try CastlingRights.fromString("KQkq", Square.FileE);
    rights = try rights.removeAllCastlingRights(Colour.Black);
    try std.testing.expectEqualStrings("KQ", rights.toString());

    rights = try rights.removeAllCastlingRights(Colour.White);
    try std.testing.expectEqualStrings("-", rights.toString());

    rights = try CastlingRights.fromString("HAha", Square.FileE);
    try std.testing.expectEqualStrings("HAha", rights.toString());
    try std.testing.expectEqual(Square.fromIndex(Square.H1), rights.whiteKingSideRookSquare());
    try std.testing.expectEqual(Square.fromIndex(Square.A1), rights.whiteQueenSideRookSquare());
    try std.testing.expectEqual(Square.fromIndex(Square.H8), rights.blackKingSideRookSquare());
    try std.testing.expectEqual(Square.fromIndex(Square.A8), rights.blackQueenSideRookSquare());

    rights = try CastlingRights.fromString("CAca", Square.FileB);
    try std.testing.expectEqualStrings("CAca", rights.toString());
    try std.testing.expectEqual(Square.fromIndex(Square.C1), rights.whiteKingSideRookSquare());
    try std.testing.expectEqual(Square.fromIndex(Square.A1), rights.whiteQueenSideRookSquare());
    try std.testing.expectEqual(Square.fromIndex(Square.C8), rights.blackKingSideRookSquare());
    try std.testing.expectEqual(Square.fromIndex(Square.A8), rights.blackQueenSideRookSquare());

    try std.testing.expectError(CastlingError.InvalidCastlingRights, CastlingRights.fromString("CAcA", Square.FileA));
    try std.testing.expectError(CastlingError.InvalidCastlingRights, CastlingRights.fromString("CAcA", Square.FileC));
    try std.testing.expectError(CastlingError.InvalidCastlingRights, CastlingRights.fromString("", Square.FileA));
    try std.testing.expectError(CastlingError.InvalidCastlingRights, CastlingRights.fromString("", Square.FileH));

    rights = try CastlingRights.fromString("-", Square.FileE);
    try std.testing.expectEqualStrings("-", rights.toString());

    rights = try CastlingRights.fromString("-", Square.FileD);
    try std.testing.expectEqualStrings("-", rights.toString());

    // // Update white castling rights (king on E, rooks on A and H)
    // castling = try castling.updateCastlingRights(.White, .Kingside, 4 ,7);
    // try std.testing.expect(castling.k == 0b0000100000000000);
    // try std.testing.expect(castling.r == 0b0000000100000000);
    // try std.testing.expectEqualStrings("K", castling.toString());
    // castling = try castling.updateCastlingRights(.White, .Queenside, 4, 0);
    // try std.testing.expect(castling.k == 0b0000100000000000);
    // try std.testing.expect(castling.r == 0b1000000100000000);
    // try std.testing.expectEqualStrings("KQ", castling.toString());
    //
    // // Update castling rights for black (king on E, rooks on A and H)
    // castling = try castling.updateCastlingRights(.Black, .Kingside, 4, 7);
    // try std.testing.expect(castling.k == 0b0000100000001000);
    // try std.testing.expect(castling.r == 0b1000000100000001);
    // try std.testing.expectEqualStrings("KQk", castling.toString());
    // castling = try castling.updateCastlingRights(.Black, .Queenside, 4, 0);
    // try std.testing.expect(castling.k == 0b0000100000001000);
    // try std.testing.expect(castling.r == 0b1000000110000001);
    // try std.testing.expectEqualStrings("KQkq", castling.toString());
    //
    // // Remove white kingside castling rights
    // castling = try castling.removeCastlingRights(.White, .Kingside);
    // try std.testing.expect(castling.k == 0b0000100000001000);
    // try std.testing.expect(castling.r == 0b1000000010000001);
    // try std.testing.expectEqualStrings("Qkq", castling.toString());
    //
    // // Remove white queenside castling rights
    // castling = try castling.removeCastlingRights(.White, .Queenside);
    // try std.testing.expect(castling.k == 0b0000000000001000);
    // try std.testing.expect(castling.r == 0b0000000010000001);
    // try std.testing.expectEqualStrings("kq", castling.toString());
    //
    // // Remove black kingside castling rights
    // castling = try castling.removeCastlingRights(.Black, .Kingside);
    // try std.testing.expect(castling.k == 0b0000000000001000);
    // try std.testing.expect(castling.r == 0b0000000010000000);
    // try std.testing.expectEqualStrings("q", castling.toString());
    //
    // // Remove black queenside castling rights
    // castling = try castling.removeCastlingRights(.Black, .Queenside);
    // try std.testing.expect(castling.k == 0b0000000000000000);
    // try std.testing.expect(castling.r == 0b0000000000000000);
    // try std.testing.expectEqualStrings("-", castling.toString());
}

// test "Chess960 castling rights" {
//     std.debug.print("Testing Chess960 castling rights...\n", .{});
//     var castling = CastlingRights{};
//
//     // // Update white castling rights (king on F, rooks on B and G)
//     // castling = try castling.updateCastlingRights(.White, .Kingside, 5, 6);
//     // castling = try castling.updateCastlingRights(.White, .Queenside, 5, 1);
//     // try std.testing.expect(castling.k == 0b0000010000000000);
//     // try std.testing.expect(castling.r == 0b0100001000000000);
//     //
//     // // Update black castling rights (king on F, rooks on B and G)
//     // castling = try castling.updateCastlingRights(.Black, .Kingside, 5, 6);
//     // castling = try castling.updateCastlingRights(.Black, .Queenside, 5, 1);
//     // try std.testing.expect(castling.k == 0b0000010000000100);
//     // try std.testing.expect(castling.r == 0b0100001001000010);
//     //
//     // // Remove white kingside castling rights
//     // castling = try castling.removeCastlingRights(.White, .Kingside);
//     // try std.testing.expect(castling.k == 0b0000010000000100);
//     // try std.testing.expect(castling.r == 0b0100000001000010);
//     //
//     // // Remove white queenside castling rights
//     // castling = try castling.removeCastlingRights(.White, .Queenside);
//     // try std.testing.expect(castling.k == 0b0000000000000100);
//     // try std.testing.expect(castling.r == 0b0000000001000010);
//     //
//     // // Remove black kingside castling rights
//     // castling = try castling.removeCastlingRights(.Black, .Kingside);
//     // try std.testing.expect(castling.k == 0b0000000000000100);
//     // try std.testing.expect(castling.r == 0b0000000001000000);
//     //
//     // // Remove black queenside castling rights
//     // castling = try castling.removeCastlingRights(.Black, .Queenside);
//     // try std.testing.expect(castling.k == 0b0000000000000000);
//     // try std.testing.expect(castling.r == 0b0000000000000000);
// }
