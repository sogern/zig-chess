const std = @import("std");

pub const chess960 = @import("chess960.zig");

test {
    @import("std").testing.refAllDeclsRecursive(@This());
}