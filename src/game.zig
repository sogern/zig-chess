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