const std = @import("std");

pub const bb = @import("bitboard.zig");
pub const file = @import("file.zig");
pub const piece = @import("piece.zig");
pub const square = @import("square.zig");
pub const rank = @import("rank.zig");

test {
    @import("std").testing.refAllDecls(@This());
}