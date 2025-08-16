const std = @import("std");

/// A bitboard is a 64-bit integer representing the state of a chessboard.
/// Each bit corresponds to a square on the board, indexed from 0 to 63,
/// starting from the most significant bit (A1) to the least significant bit (H8).
pub const bitboard = u64;
