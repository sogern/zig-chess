const std = @import("std");

pub const chess960 = @import("chess960.zig");

test "All chess960 positions" {
    for (0..960) |i| {
        const position = chess960.positionFromId(i);
        std.debug.print("Chess960 Position ID {}: {s}\n", .{ i, position });
    }
}