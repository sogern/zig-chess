const std = @import("std");
const Position = @import("position.zig").Position;
const Move = @import("move.zig").Move;
const decodeFEN = @import("fen.zig").decodeFEN;

/// An Outcome is the result of a game.
pub const Outcome = enum(u8) {
    UnknownOutcome,
    WhiteWon,
    BlackWon,
    Draw,
    NoOutcome,

    pub fn toString(self: @This()) []const u8 {
        return switch (self) {
            .UnknownOutcome => "",
            .WhiteWon => "1-0",
            .BlackWon => "0-1",
            .Draw => "1/2-1/2",
            .NoOutcome => "*",
        };
    }
};

/// TagPairs represent a collection of PGN tag pairs.
pub const TagPairs = std.StringHashMapUnmanaged([]const u8);

/// A Method is what generated the outcome.
pub const Method = enum(u8) {
    Checkmate,
    Resignation,
    DrawOffer,
    Stalemate,
    ThreefoldRepetition,
    FivefoldRepetition,
    FiftyMoveRule,
    SeventyFiveMoveRule,
    InsufficientMaterial,
    NoMethod,
};

/// A Game represents a single chess game.
pub const Game = struct {
    pos: *Position,
    outcome: Outcome,
    tagPairs: TagPairs = TagPairs.init(std.heap.page_allocator),
    rootMove: ?*Move = null,
    currentMove: ?*Move = null,
    method: Method = .NoMethod,
    ignoreFivefoldRepetitionDraw: bool = false,
    ignoreSeventyFiveMoveRuleDraw: bool = false,
    ignoreInsufficientMaterialDraw: bool = false,
};
