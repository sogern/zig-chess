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
/// The reason for converting KQ kq, AH ah etc. from FEN to this format is
/// to maintain a bitmask we can use in the board struct to easily resolve the legal castling moves.
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
    pub fn updateCastlingRights(self: *CastlingRights, colour: Colour, side: CastlingSide, kingFile: i8, rookFile: i8) !void {
        if (colour == Colour.None or !validFile(kingFile) or !validFile(rookFile) or !validSide(side, kingFile, rookFile)) {
            return CastlingError.InvalidCastlingRights;
        }
        var k: u16 = @as(u16, 1) << @intCast(7 - kingFile);
        var r: u16 = @as(u16, 1) << @intCast(7 - rookFile);
        if (colour == Colour.White) {
            r = r | (self.r >> 8);
            k = k << 8;
            r = r << 8;
            // Include any existing castling rights for white
            k |= self.k & 0x00FF;
            r |= self.r & 0x00FF;
        } else {
            r = r | (self.r & 0x00FF);
            // Include any existing castling rights for black
            k |= self.k & 0xFF00;
            r |= self.r & 0xFF00;
        }
        self.k = k;
        self.r = r;
    }

    pub fn removeCastlingRights(self: *CastlingRights, colour: Colour, _: CastlingSide) void {
        if (colour == Colour.White) {
            self.k &= 0x00FF;
            self.r &= 0x00FF;
        } else if (colour == Colour.Black) {
            self.k &= 0xFF00;
            self.r &= 0xFF00;
        }
    }
};

test "Castling rights" {
    std.debug.print("Testing castling rights...\n", .{});
    var castling = CastlingRights{};

    // Update white castling rights (king on E, rooks on A and H)
    try castling.updateCastlingRights(Colour.White, CastlingSide.Kingside, 4 ,7);
    // std.debug.print("White castling rights updated: k={b}, r={b}\n", .{castling.k, castling.r});
    try std.testing.expect(castling.k == 0b0000100000000000);
    try std.testing.expect(castling.r == 0b0000000100000000);
    try castling.updateCastlingRights(Colour.White, CastlingSide.Queenside, 4, 0);
    // std.debug.print("White castling rights updated: k={b}, r={b}\n", .{castling.k, castling.r});
    try std.testing.expect(castling.k == 0b0000100000000000);
    try std.testing.expect(castling.r == 0b1000000100000000);

    // Update castling rights for black (king on E, rooks on A and H)
    // This should not affect white's rights
    try castling.updateCastlingRights(Colour.Black, CastlingSide.Kingside, 4, 7);
    // std.debug.print("Black castling rights set: k={b}, r={b}\n", .{castling.k, castling.r});
    try std.testing.expect(castling.k == 0b0000100000001000);
    try std.testing.expect(castling.r == 0b1000000100000001);
    try castling.updateCastlingRights(Colour.Black, CastlingSide.Queenside, 4, 0);
    // std.debug.print("Black castling rights set: k={b}, r={b}\n", .{castling.k, castling.r});
    try std.testing.expect(castling.k == 0b0000100000001000);
    try std.testing.expect(castling.r == 0b1000000110000001);
}