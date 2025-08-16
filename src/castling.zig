const std = @import("std");
const Colour = @import("piece.zig").Colour;

pub const CastlingError = error {
    InvalidCastlingRights,
};

/// CastlingRights are two 16-bit integers representing the castling rights.
/// MSB bits represent white's rights, LSB bits represent black's rights.
/// Each colour's 8 bits correspond to a file on the board from MSB (A) to LSB (H).
pub const CastlingRights = packed struct {
    // The rooks' files
    r: u16,
    // The kings' files
    k: u16,

    pub fn init() CastlingRights {
        return .{ .r = 0, .k = 0 };
    }

    inline fn validFile(f: i8) bool {
        return f >= 0 and f <= 7;
    }

    /// Sets castling rights for given colour.
    /// The rookFiles are expected to be ordered left (index 1) and right (index 2) of the king.
    /// The rooks must be on either side of the king.
    pub fn setCastlingRights(self: *CastlingRights, colour: Colour, kingFile: i8, rookFiles: [2]i8) !void {
        if (colour == Colour.None or !validFile(kingFile) or !validFile(rookFiles[0]) or !validFile(rookFiles[1]) or rookFiles[0] >= kingFile or rookFiles[1] <= kingFile) {
            return CastlingError.InvalidCastlingRights;
        }
        var k: u16 = 0;
        k |= @as(u16, 1) << @intCast(7 - kingFile);
        // std.debug.print("k set for {c} at file {d}: {b}\n", .{colour.toChar(), kingFile, k});
        var r: u16 = 0;
        r |= @as(u16, 1) << @intCast(7 - rookFiles[0]);
        r |= @as(u16, 1) << @intCast(7 - rookFiles[1]);
        // std.debug.print("r set for {c} at files {d} and {d}: {b}\n", .{colour.toChar(), rookFiles[0], rookFiles[1], r});
        if (colour == Colour.White) {
            k = k << 8;
            r = r << 8;
            // Ensure castling rights for black are not affected
            k |= self.k & 0x00FF;
            r |= self.r & 0x00FF;
        } else {
            // Ensure castling rights for white are not affected
            k |= self.k & 0xFF00;
            r |= self.r & 0xFF00;
        }
        self.k = k;
        self.r = r;
    }
};

test "Castling rights" {
    std.debug.print("Testing castling rights...\n", .{});
    var castling = CastlingRights.init();

    // Set castling rights for white (king on E, rooks on A and H)
    try castling.setCastlingRights(Colour.White, 4, .{0, 7});
    // std.debug.print("White castling rights set: k={b}, r={b}\n", .{castling.k, castling.r});
    try std.testing.expect(castling.k == 0b0000100000000000);
    try std.testing.expect(castling.r == 0b1000000100000000);

    // Set castling rights for black (king on E, rooks on A and H)
    // This should not affect white's rights
    try castling.setCastlingRights(Colour.Black, 4, .{0, 7});
    // std.debug.print("Black castling rights set: k={b}, r={b}\n", .{castling.k, castling.r});
    try std.testing.expect(castling.k == 0b0000100000001000);
    try std.testing.expect(castling.r == 0b1000000110000001);
}