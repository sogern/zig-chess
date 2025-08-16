const std = @import("std");

/// Generates a Chess960 position based on the given ID.
/// The ID is expected to be in the range [0, 959].
/// The function returns an array of 8 characters representing the starting position of the officer pieces.
///
/// The algorithm places the pieces as follows:
/// 1) Bishops are placed on opposite-colored squares, based on the ID modulo 4 and truncated division by 4
/// 2) Queen is then placed on an empty square, based on the ID modulo 6 and truncated division by 6
/// 3) King, rooks and knights are placed on the remaining empty squares,
///    based on the ID truncated division by 96 to select one of the 10 predefined arrangements
///
pub fn positionFromId(_id: usize) [8]u8 {
    var id = _id;
    if (id >= 960) id = 959; // Cap id to valid range

    // Predefined King-Rook-Knight arrangements
    // Ensures rooks on either side of the king
    const krn = [10][5]u8{
        [_]u8{ 'n', 'n', 'r', 'k', 'r' },
        [_]u8{ 'n', 'r', 'n', 'k', 'r' },
        [_]u8{ 'n', 'r', 'k', 'n', 'r' },
        [_]u8{ 'n', 'r', 'k', 'r', 'n' },
        [_]u8{ 'r', 'n', 'n', 'k', 'r' },
        [_]u8{ 'r', 'n', 'k', 'n', 'r' },
        [_]u8{ 'r', 'n', 'k', 'r', 'n' },
        [_]u8{ 'r', 'k', 'n', 'n', 'r' },
        [_]u8{ 'r', 'k', 'n', 'r', 'n' },
        [_]u8{ 'r', 'k', 'r', 'n', 'n' },
    };

    var output: [8]u8 = undefined;
    for (&output) |*pos| {
        pos.* = ' ';
    }

    // Place bishops on opposite-coloured squares
    // Step 1: select white square (odd index) bishop
    const step1Mod = id % 4; // increments every ID and repeats every 4th, yielding values 0 to 3
    const step1Trunc = id / 4; // increments every 4th ID, yielding values 0 to 239
    const whiteBishopPos = [4]u8{ 1, 3, 5, 7 };
    output[whiteBishopPos[step1Mod]] = 'b';

    // Step 2: select black square (even index) bishop
    const step2Mod = step1Trunc % 4; // increments every 4th ID and repeats every 16th, yelding values 0 to 3
    const step2Trunc = step1Trunc / 4; // increments every 16th ID, yelding values 0 to 59
    const blackBishopPos = [4]u8{ 0, 2, 4, 6 };
    output[blackBishopPos[step2Mod]] = 'b';

    // Step 3: place the queen
    const step3Mod = step2Trunc % 6; // increments every 16th ID and repeats every 96th, yielding values 0 to 5
    const step3Trunc = step2Trunc / 6; // increments every 96th ID, yielding values 0 to 9 used to select krn array index
    var emptyCounter: usize = 0;
    for (&output) |*pos| {
        if (pos.* == ' ') {
            if (emptyCounter == step3Mod) {
                pos.* = 'q';
                break;
            }
            emptyCounter += 1;
        }
    }

    // Step 4: place the remaining 5 pieces; King, Rooks and Knights (KRN)
    const step4 = krn[step3Trunc];
    // for (step4) |p| {
    //     for (&output) |*pos| {
    //         if (pos.* == ' ') {
    //             pos.* = p;
    //             break;
    //         }
    //     }
    // }
    var step4Index: usize = 0;
    for (&output) |*pos| {
        if (pos.* == ' ') {
            pos.* = step4[step4Index];
            step4Index += 1;
        }
    }

    // std.debug.print("Chess960 position for ID {}: {s} [{d}, {d}, {d}, {d}, {d}, {d}]\n", .{ _id, output, step1Mod, step1Trunc, step2Mod, step2Trunc, step3Mod, step3Trunc });

    return output;
}

test "chess960 unique positions" {
    // Check that all positions are unique
    std.debug.print("Validating all chess960 positions are unique...\n", .{});
    var seen = std.AutoArrayHashMap([8]u8, bool).init(std.testing.allocator);
    defer seen.deinit();

    for (0..960) |i| {
        const position = positionFromId(i);
        try seen.put(position, true);
    }
    try std.testing.expectEqual(960, seen.count());
}

test "chess960 valid positions" {
    // Check that all positions are valid
    std.debug.print("Validating chess960 positions...\n", .{});
    for (0..960) |i| {
        const position = positionFromId(i);
        var white_sq_bishop: usize = 0;
        var black_sq_bishop: usize = 0;
        var queen: usize = 0;
        var king: usize = 0;
        var queenside_rook: usize = 0;
        var kingside_rook: usize = 0;
        var knights: usize = 0;

        for (position, 0..) |p, f| {
            switch (p) {
                'b' => if (f % 2 == 0) {
                    black_sq_bishop += 1;
                } else {
                    white_sq_bishop += 1;
                },
                'q' => queen += 1,
                'k' => {
                    king += 1;
                },
                'r' => if (king > 0) {
                    kingside_rook += 1;
                } else {
                    queenside_rook += 1;
                },
                'n' => knights += 1,
                else => {},
            }
        }

        try std.testing.expectEqual(1, white_sq_bishop);
        try std.testing.expectEqual(1, black_sq_bishop);
        try std.testing.expectEqual(1, queen);
        try std.testing.expectEqual(1, king);
        try std.testing.expectEqual(1, queenside_rook);
        try std.testing.expectEqual(1, kingside_rook);
        try std.testing.expectEqual(2, knights);
    }
}
