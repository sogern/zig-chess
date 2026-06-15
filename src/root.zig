const std = @import("std");

pub const bb = @import("bitboard.zig");
pub const bitboard = bb.bitboard;

test {
    @import("std").testing.refAllDeclsRecursive(@This());
}