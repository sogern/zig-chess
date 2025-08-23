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


/// CastlingRights are two 16-bit integers representing the castling rights.
/// MSB bits represent white's rights, LSB bits represent black's rights.
/// Each colour's 8 bits correspond to a file on the board from MSB (A) to LSB (H).
/// The reason for converting KQ kq, AH ah etc. from FEN to this format
/// is to maintain a bitmask we can use in the board struct to easily resolve the legal castling moves.
pub const CastlingRights = packed struct {
    // The rooks' files
    r: u16 = 0,
    // The kings' files
    k: u16 = 0,

    inline fn validFile(f: i8) bool {
        return f >= @as(i8, 0) and f <= @as(i8, 7);
    }

    inline fn validSide(side: CastlingSide, kf: i8, rf: i8) bool {
        if (side == CastlingSide.None) {
            return false;
        }
        if (side == CastlingSide.Kingside) {
            return rf > kf;
        } else {
            return rf < kf;
        }
    }

    /// Sets castling rights for given colour.
    /// The rook must be on the left (queenside) or right (kingside) of the king.
    pub fn updateCastlingRights(self: CastlingRights, colour: Colour, side: CastlingSide, kingFile: i8, rookFile: i8) !CastlingRights {
        if (colour == Colour.None or !validFile(kingFile) or !validFile(rookFile) or !validSide(side, kingFile, rookFile)) {
            return CastlingError.InvalidCastlingRights;
        }
        var k: u16 = @as(u16, 1) << @intCast(7 - kingFile);
        var r: u16 = @as(u16, 1) << @intCast(7 - rookFile);
        if (colour == Colour.White) {
            r = r | (self.r >> 8);
            k = k << 8;
            r = r << 8;
            // Include any existing castling rights for black
            k |= self.k & 0x00FF;
            r |= self.r & 0x00FF;
        } else {
            r = r | (self.r & 0x00FF);
            // Include any existing castling rights for white
            k |= self.k & 0xFF00;
            r |= self.r & 0xFF00;
        }
        return .{ .k = k, .r = r };
    }

    pub fn removeCastlingRights(self: CastlingRights, colour: Colour, side: CastlingSide) !CastlingRights {
        if  (side == .None or colour == .None) {
            return CastlingError.InvalidCastlingRights;
        }
        var k = self.k;
        var r = self.r;
        if (colour == .White) {
            k = k >> 8;
            r = r >> 8;
            if (k == 0 or r == 0) {
                return self; // No rights to remove
            }
            const ki = @as(i8, @ctz(k)); // King bit index
            if (side == .Kingside) {
                const ksri = @as(i8, @ctz(r)); // Kingside rook bit index
                if (ksri > ki) {
                    return self; // No rook to the right of the king
                }
                r = r & ~(@as(u16, 1) << @intCast(ksri)); // Remove kingside rook
                if (r == 0) {
                    k = 0; // Clear k if no rooks left
                }
            } else {
                // Remember we are operating on a 16-bit integer, and the first 8 bits are always zero at this point
                // Thus we subtract those from the count
                const qsri = 7 - (@as(i8, @clz(r)) - 8); // Queenside rook bit index
                if (qsri < ki) {
                    return self; // No rook to the left of the king
                }
                r = r & ~(@as(u16, 1) << @intCast(qsri)); // Remove queenside rook
                if (r == 0) {
                    k = 0; // Clear k if no rooks left
                }
            }
            k = k << 8;
            r = r << 8;
            // Include any existing castling rights for black
            k |= self.k & 0x00FF;
            r |= self.r & 0x00FF;
        } else {
            k = k & 0x00FF;
            r = r & 0x00FF;
            if (k == 0 or r == 0) {
                return self; // No rights to remove
            }
            const ki = @as(i8, @ctz(k)); // King bit index
            if (side == .Kingside) {
                const ksri = @as(i8, @ctz(r)); // Kingside rook bit index
                if (ksri > ki) {
                    return self; // No rook to the right of the king
                }
                r = r & ~(@as(u16, 1) << @intCast(ksri)); // Remove kingside rook
                if (r == 0) {
                    k = 0; // Clear k if no rooks left
                }
            } else {
                // Remember we are operating on a 16-bit integer, and the first 8 bits are always zero at this point
                // Thus we subtract those from the count
                const qsri = 7 - (@as(i8, @clz(r)) - 8); // Queenside rook bit index
                if (qsri < ki) {
                    return self; // No rook to the left of the king
                }
                r = r & ~(@as(u16, 1) << @intCast(qsri)); // Remove queenside rook
                if (r == 0) {
                    k = 0; // Clear k if no rooks left
                }
            }
            // Include any existing castling rights for white
            k |= self.k & 0xFF00;
            r |= self.r & 0xFF00;
        }
        return .{ .k = k, .r = r };
    }

    pub fn removeAllCastlingRights(self: CastlingRights, colour: Colour) !CastlingRights {
        return switch (colour) {
            .White => .{ .k = self.k & 0x00FF, .r = self.r & 0x00FF },
            .Black => .{ .k = self.k & 0xFF00, .r = self.r & 0xFF00 },
            .None => CastlingError.InvalidCastlingRights,
        };
    }
};

test "Castling rights" {
    std.debug.print("Testing castling rights...\n", .{});
    var castling = CastlingRights{};

    // Update white castling rights (king on E, rooks on A and H)
    castling = try castling.updateCastlingRights(.White, .Kingside, 4 ,7);
    try std.testing.expect(castling.k == 0b0000100000000000);
    try std.testing.expect(castling.r == 0b0000000100000000);
    castling = try castling.updateCastlingRights(.White, .Queenside, 4, 0);
    try std.testing.expect(castling.k == 0b0000100000000000);
    try std.testing.expect(castling.r == 0b1000000100000000);

    // Update castling rights for black (king on E, rooks on A and H)
    castling = try castling.updateCastlingRights(.Black, .Kingside, 4, 7);
    try std.testing.expect(castling.k == 0b0000100000001000);
    try std.testing.expect(castling.r == 0b1000000100000001);
    castling = try castling.updateCastlingRights(.Black, .Queenside, 4, 0);
    try std.testing.expect(castling.k == 0b0000100000001000);
    try std.testing.expect(castling.r == 0b1000000110000001);

    // Remove white kingside castling rights
    castling = try castling.removeCastlingRights(.White, .Kingside);
    try std.testing.expect(castling.k == 0b0000100000001000);
    try std.testing.expect(castling.r == 0b1000000010000001);

    // Remove white queenside castling rights
    castling = try castling.removeCastlingRights(.White, .Queenside);
    try std.testing.expect(castling.k == 0b0000000000001000);
    try std.testing.expect(castling.r == 0b0000000010000001);

    // Remove black kingside castling rights
    castling = try castling.removeCastlingRights(.Black, .Kingside);
    try std.testing.expect(castling.k == 0b0000000000001000);
    try std.testing.expect(castling.r == 0b0000000010000000);

    // Remove black queenside castling rights
    castling = try castling.removeCastlingRights(.Black, .Queenside);
    try std.testing.expect(castling.k == 0b0000000000000000);
    try std.testing.expect(castling.r == 0b0000000000000000);
}

test "Chess960 castling rights" {
    std.debug.print("Testing Chess960 castling rights...\n", .{});
    var castling = CastlingRights{};

    // Update white castling rights (king on F, rooks on B and G)
    castling = try castling.updateCastlingRights(.White, .Kingside, 5, 6);
    castling = try castling.updateCastlingRights(.White, .Queenside, 5, 1);
    try std.testing.expect(castling.k == 0b0000010000000000);
    try std.testing.expect(castling.r == 0b0100001000000000);

    // Update black castling rights (king on F, rooks on B and G)
    castling = try castling.updateCastlingRights(.Black, .Kingside, 5, 6);
    castling = try castling.updateCastlingRights(.Black, .Queenside, 5, 1);
    try std.testing.expect(castling.k == 0b0000010000000100);
    try std.testing.expect(castling.r == 0b0100001001000010);

    // Remove white kingside castling rights
    castling = try castling.removeCastlingRights(.White, .Kingside);
    try std.testing.expect(castling.k == 0b0000010000000100);
    try std.testing.expect(castling.r == 0b0100000001000010);

    // Remove white queenside castling rights
    castling = try castling.removeCastlingRights(.White, .Queenside);
    try std.testing.expect(castling.k == 0b0000000000000100);
    try std.testing.expect(castling.r == 0b0000000001000010);

    // Remove black kingside castling rights
    castling = try castling.removeCastlingRights(.Black, .Kingside);
    try std.testing.expect(castling.k == 0b0000000000000100);
    try std.testing.expect(castling.r == 0b0000000001000000);

    // Remove black queenside castling rights
    castling = try castling.removeCastlingRights(.Black, .Queenside);
    try std.testing.expect(castling.k == 0b0000000000000000);
    try std.testing.expect(castling.r == 0b0000000000000000);
}