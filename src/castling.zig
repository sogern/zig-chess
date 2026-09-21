const std = @import("std");
const Colour = @import("piece.zig").Colour;
const Square = @import("square.zig").Square;
const File = @import("file.zig").File;
const Rank = @import("rank.zig").Rank;

const Self = @This();

pub const CastlingError = error {
    InvalidCastlingRights,
};

pub const CastlingSide = enum(u8) {
    Queenside,
    Kingside,
    None,
};

/// Holds the rook squares for castling rights, in order:
/// White kingside, white queenside, black kingside, black queenside.
pub const Rights = [4]Square;

rights: Rights = .{ .H1, .A1, .H8, .A8 }, // KQkq in standard FEN notation
kingFile: File = .E,                      // King on E in standard chess
standard: bool = true,                    // Standard chess castling rights (KQkq) or X-FEN castling rights (e.g., HAha)

pub fn fromString(str: []const u8, kingFile: File) !Self {
    if (str.len > 4) return CastlingError.InvalidCastlingRights;
    var r: Self = .{
        .rights= .{ .None, .None, .None, .None },
        .kingFile = kingFile,
        .standard = true
    };
    for (str) |c| {
        switch (c) {
            'K' => r.rights[0] = .H1,
            'Q' => r.rights[1] = .A1,
            'k' => r.rights[2] = .H8,
            'q' => r.rights[3] = .A8,
            // X-FEN notation
            'A'...'H' => {
                const index = @as(usize, c - 'A');
                if (c > kingFile.char() - 32) {
                    r.rights[0] = Square.fromIndex(index);
                } else if (c < kingFile.char() - 32) {
                    r.rights[1] = Square.fromIndex(index);
                } else {
                    return CastlingError.InvalidCastlingRights;
                }
                r.standard = false;
            },
            'a'...'h' => {
                const index = @as(usize, c - 'a') + 56; // rank 8 squares are 56-63
                if (c > kingFile.char()) {
                    r.rights[2] = Square.fromIndex(index);
                } else if (c < kingFile.char()) {
                    r.rights[3] = Square.fromIndex(index);
                } else {
                    return CastlingError.InvalidCastlingRights;
                }
                r.standard = false;
            },
            '-' => {},
            else => return CastlingError.InvalidCastlingRights,
        }
    }
    return r;
}

test fromString {
    var r = try Self.fromString("KQkq", .E);
    try std.testing.expectEqual(.H1, r.rights[0]);
    try std.testing.expectEqual(.A1, r.rights[1]);
    try std.testing.expectEqual(.H8, r.rights[2]);
    try std.testing.expectEqual(.A8, r.rights[3]);
    try std.testing.expectEqual(.E, r.kingFile);

    r = try Self.fromString("HAha", .E);
    try std.testing.expectEqual(.H1, r.rights[0]);
    try std.testing.expectEqual(.A1, r.rights[1]);
    try std.testing.expectEqual(.H8, r.rights[2]);
    try std.testing.expectEqual(.A8, r.rights[3]);
    try std.testing.expectEqual(.E, r.kingFile);
}

/// Returns (X-)FEN string representation of castling rights.
/// Caller owns the returned string.
pub fn string(self: Self, alloc: std.mem.Allocator) ![]u8 {
    var buf: [4]u8 = undefined;
    var i: usize = 0;
    for (self.rights, 0..) |s, j| {
        if (s == .None) continue;
        const c = s.string()[0];
        if (self.standard) {
            const r: u8 = blk: switch (c) {
                'h' => break :blk 'k',
                'a' => break :blk 'q',
                else => return CastlingError.InvalidCastlingRights,
            };
            if (j < 2) {
                buf[i] = r - 32; // uppercase for white
            } else {
                buf[i] = r; // lowercase for black
            }
        } else {
            // X-FEN notation
            if (j < 2) {
                buf[i] = c - 32; // uppercase for white
            } else {
                buf[i] = c; // lowercase for black
            }
        }
        i += 1;
    }
    if (i == 0) {
        buf[0] = '-';
        i = 1;
    }
    const out = try alloc.alloc(u8, i);
    @memcpy(out, buf[0..i]);
    return out;
}

test string {
    var alloc = std.testing.allocator;
    var r = try Self.fromString("KQkq", .E);
    const s = try r.string(alloc);
    defer alloc.free(s);
    try std.testing.expectEqualStrings("KQkq", s);

    r = try Self.fromString("HAha", .E);
    const s2 = try r.string(alloc);
    defer alloc.free(s2);
    try std.testing.expectEqualStrings("HAha", s2);

    r = try Self.fromString("-", .E);
    const s3 = try r.string(alloc);
    defer alloc.free(s3);
    try std.testing.expectEqualStrings("-", s3);
}

pub fn canCastle(self: Self, colour: Colour, side: CastlingSide) bool {
    if (colour == .White) {
        if (side == .Kingside and (self.rights[0] != .None)) return true;
        if (side == .Queenside and (self.rights[1] != .None)) return true;
    } else if (colour == .Black) {
        if (side == .Kingside and (self.rights[2] != .None)) return true;
        if (side == .Queenside and (self.rights[3] != .None)) return true;
    }
    return false;
}

test canCastle {
    var cr: Self = .{};
    try std.testing.expect(cr.canCastle(.White, .Kingside));
    try std.testing.expect(cr.canCastle(.White, .Queenside));
    try std.testing.expect(cr.canCastle(.Black, .Kingside));
    try std.testing.expect(cr.canCastle(.Black, .Queenside));

    cr = .{ .rights = .{ .H1, .None, .H8, .None } };
    try std.testing.expect(!cr.canCastle(.White, .Queenside));

    cr = .{ .rights = .{ .H1, .A1, .H8, .None } };
    try std.testing.expect(!cr.canCastle(.Black, .Queenside));

    cr = .{ .rights = .{ .None, .A1, .None, .None } };
    try std.testing.expect(!cr.canCastle(.White, .Kingside));
    try std.testing.expect(!cr.canCastle(.Black, .Kingside));
}

pub fn castlingRookSquare(self: Self, colour: Colour, side: CastlingSide) Square {
    if (colour == .White) {
        if (side == .Kingside) return self.rights[0];
        if (side == .Queenside) return self.rights[1];
    } else if (colour == .Black) {
        if (side == .Kingside) return self.rights[2];
        if (side == .Queenside) return self.rights[3];
    }
    return .None;
}

test castlingRookSquare {
    var cr: Self = .{};
    try std.testing.expectEqual(.H1, cr.castlingRookSquare(.White, .Kingside));
    try std.testing.expectEqual(.A1, cr.castlingRookSquare(.White, .Queenside));
    try std.testing.expectEqual(.H8, cr.castlingRookSquare(.Black, .Kingside));
    try std.testing.expectEqual(.A8, cr.castlingRookSquare(.Black, .Queenside));

    cr = .{ .rights = .{ .H1, .None, .H8, .None } };
    try std.testing.expectEqual(.None, cr.castlingRookSquare(.White, .Queenside));

    cr = .{ .rights = .{ .H1, .A1, .H8, .None } };
    try std.testing.expectEqual(.None, cr.castlingRookSquare(.Black, .Queenside));

    cr = .{ .rights = .{ .None, .A1, .None, .None } };
    try std.testing.expectEqual(.None, cr.castlingRookSquare(.White, .Kingside));
    try std.testing.expectEqual(.None, cr.castlingRookSquare(.Black, .Kingside));
}

pub fn removeCastlingRight(self: *Self, colour: Colour, side: CastlingSide) void {
    if (colour == .White) {
        if (side == .Kingside) self.rights[0] = .None;
        if (side == .Queenside) self.rights[1] = .None;
    } else if (colour == .Black) {
        if (side == .Kingside) self.rights[2] = .None;
        if (side == .Queenside) self.rights[3] = .None;
    }
}

pub fn removeAllCastlingRights(self: *Self, colour: Colour) void {
    if (colour == .White) {
        self.rights[0] = .None;
        self.rights[1] = .None;
    } else if (colour == .Black) {
        self.rights[2] = .None;
        self.rights[3] = .None;
    }
}