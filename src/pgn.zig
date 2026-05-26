const std = @import("std");
const Game = @import("game.zig").Game;
const Token = @import("lexer.zig").Token;
const Position = @import("position.zig").Position;
const Move = @import("move.zig").Move;
const MoveTag = @import("move.zig").MoveTag;
const PieceType = @import("piece.zig").PieceType;
const Square = @import("square.zig").Square;
const pieceTypeFromChar = @import("piece.zig").pieceTypeFromChar;
const KingSideCastle = @import("move.zig").KingSideCastle;
const QueenSideCastle = @import("move.zig").QueenSideCastle;
const Check = @import("move.zig").Check;
const decodeFEN = @import("fen.zig").decodeFEN;
const startFEN = @import("fen.zig").startFEN;

pub const PGN = struct {

};

const ParsedComment = struct { []const u8, usize };

const ParsedCommands = std.StringHashMapUnmanaged([]const u8);

pub const PGNParsingError = error{
    UnexpectedTokenInComment,
    UnexpectedTokenInCommand,
    UnterminatedCommand,
    UnterminatedVariation,
};

const Parser = struct {
    alloc: std.mem.Allocator,
    game: *Game = undefined,
    currentMove: *Move = undefined,
    tokens: []const Token = undefined,
    pos: usize = 0,

    pub fn newParser(alloc: std.mem.Allocator, tokens: []const Token) *Parser {
        const position = decodeFEN(startFEN) catch unreachable;

        const rootMove = &Move{
            .position = &position,
        };
        return &Parser{
            .alloc = alloc,
            .tokens = tokens,
            .game = Game.newGame(alloc, &position, rootMove, rootMove),
            .currentMove = rootMove,
        };
    }

    fn currentToken(self: *Parser) Token {
        if (self.pos >= self.tokens.len) {
            return Token{
                .@"type" = .EOF,
            };
        }
        return self.tokens[self.pos];
    }

    fn advance(self: *Parser) void {
        self.pos += 1;
    }

    /// parse processes all tokens and returns a Game.
    /// This includes parsing header information (tags) and moves,
    /// variations, comments, and the game result.
    /// 
    /// Returns an error if the PGN is malformed or contains illegal moves.
    /// 
    /// Example:
    /// 
    /// var game = parser.parse() catch |err| {
    ///     return err;
    /// };
    pub fn parse(self: *Parser) !*Game {
        // Parse header section
        self.parseHeader() catch |err| {
            return err;
        };

        // Check if the game has a starting position
        if (self.game.tagPairs.contains("FEN")) {
            const position = decodeFEN(startFEN) catch |err| {
                return err;
            };
            self.game.rootMove.position = &position;
            self.game.pos = &position;
        }

        // Parse moves section
        self.parseMoveText() catch |err| {
            return err;
        };

        if (self.game.outcome == .UnknownOutcome) {
            self.game.outcome = .NoOutcome;
        }
        self.game.currentMove = self.currentMove;

        return self.game;
    }

    fn parseHeader(self: *Parser) !void {
        while (self.currentToken().@"type" == .TagStart) {
            self.parseTagPair() catch |err| {
                return err;
            };
        }
    }

    fn parseTagPair(self: *Parser) !void {
        // Expect TagStart token
        if (self.currentToken().@"type" != .TagStart) {
            return error.ExpectedTagStart;
        }
        self.advance();
        
        // Get key
        if (self.currentToken().@"type" != .TagKey) {
            return error.ExpectedTagKey;
        }
        const key = self.currentToken().value;
        self.advance();

        // Get value
        if (self.currentToken().@"type" != .TagValue) {
            return error.ExpectedTagValue;
        }
        const value = self.currentToken().value;
        self.advance();

        // Expect TagEnd token
        if (self.currentToken().@"type" != .TagEnd) {
            return error.ExpectedTagEnd;
        }
        self.advance();

        // Store tag pair
        self.game.tagPairs.put(self.alloc, key, value) catch |err| {
            return err;
        };
    }

    fn parseMoveText(self: *Parser) !void {
        var moveNumber: u32 = 0;
        var ply: i32 = 1;
        while (self.pos < self.tokens.len) {
            const token = self.currentToken();
            
            switch (token.@"type") {
                .MoveNumber => {
                    moveNumber = std.fmt.parseInt(u32, token.value, 10) catch |err| {
                        return err;
                    };
                    ply = @as(i32, (moveNumber - 1) * 2 + 1);
                    self.advance();
                    if (self.currentToken().@"type" == .Dot) {
                        self.advance();
                    }
                },

                .Ellipsis => {
                    self.advance();
                    ply += 1;
                },

                .Piece, .Square, .File, .KingSideCastle, .QueenSideCastle => {
                    const move = self.parseMove() catch |err| {
                        return err;
                    };
                    if (moveNumber > 0) {
                        move.number = moveNumber;
                    }
                    self.addMove(move);
                    ply += 1;

                    // Collect all NAGs and comments that follow the move
                    while (true) {
                        const tok = self.currentToken();
                        switch (tok.@"type") {
                            .NAG => {
                                // TODO: Convert NAG value to u16 mask
                                // self.currentMove.nag = tok.value;
                                self.advance();
                            },
                            .CommentStart => {
                                // const comment, const commands = self.parseComment() catch |err| {
                                //     return err;
                                // };
                                // TODO: Move.commands, Move.comment
                                // if (self.currentMove) {
                                // }
                            },
                            else => break,
                        }
                    }
                },

                .CommentStart => {
                    // const comment, const commands = self.parseComment() catch |err| {
                    //     return err;
                    // };
                    // // TODO: Move.commands, Move.comment
                    // if (self.currentMove) {
                    // }
                },

                .VariationStart => {
                    self.parseVariation(moveNumber, ply) catch |err| {
                        return err;
                    };
                },

                .Result => {
                    self.parseResult();
                    return;
                },

                else => {
                    self.advance();
                }
            }
        }
    }

    /// parseMove processes tokens until it has a complete move,
    /// and then validates against legal moves.
    fn parseMove(self: *Parser) !*Move {
        var move = Move{};

        // Handle castling first as it is a special case
        if (self.currentToken().@"type" == .KingSideCastle) {
            move.addTag(KingSideCastle);
            const validMoves = self.game.pos.getValidMoves();
            for (validMoves) |m| {
                if (m.hasTag(KingSideCastle)) {
                    move.s1 = m.s1;
                    move.s2 = m.s2;
                    move.position = self.game.pos; // TODO: copy?
                    if (m.hasTag(Check)) {
                        move.addTag(Check);
                    }
                    self.advance();
                    return &move;
                }
            }
            return error.IllegalKingsideCastle;
        }

        if (self.currentToken().@"type" == .QueenSideCastle) {
            move.addTag(QueenSideCastle);
            const validMoves = self.game.pos.getValidMoves();
            for (validMoves) |m| {
                if (m.hasTag(QueenSideCastle)) {
                    move.s1 = m.s1;
                    move.s2 = m.s2;
                    move.position = self.game.pos; // TODO: copy?
                    if (m.hasTag(Check)) {
                        move.addTag(Check);
                    }
                    self.advance();
                    return &move;
                }
            }
            return error.IllegalQueensideCastle;
        }

        // Parse regular move
        var moveData: struct {
            piece: []const u8 = undefined,
            originFile: u8 = 0,
            originRank: u8 = 0,
            destSquare: []const u8 = undefined,
            isCapture: bool = false,
            promotion: PieceType = .None,
        } = .{};

        // First token could be piece, file (for pawn moves), or square
        switch (self.currentToken().@"type") {
            .Piece => {
                moveData.piece = self.currentToken().value;
                self.advance();

                // Check for disambiguation
                if (self.currentToken().@"type" == .File) {
                    moveData.originFile = self.currentToken().value;
                    self.advance();
                } else if (self.currentToken().@"type" == .Rank) {
                    moveData.originRank = self.currentToken().value;
                    self.advance();
                } else if (self.currentToken().@"type" == .DisambiguationSquare) {
                    // Full square disambiguation (e.g. "Qe8f7" -> piece: Q, origin: e8, dest: f7)
                    const originSquare = self.currentToken().value;
                    if (originSquare.len == 2) {
                        moveData.originFile = originSquare[0];
                        moveData.originRank = originSquare[1];
                    }
                    self.advance();
                }
            },

            .File => {
                moveData.originFile = self.currentToken().value;
                self.advance();
            },

            else => {}, // Do nothing
        }

        // Handle capture
        if (self.currentToken().@"type" == .Capture) {
            moveData.isCapture = true;
            self.advance();
        }

        // Get destination square
        if (self.currentToken().@"type" != .Square) {
            return error.ExpectedDestinationSquare;
        }
        moveData.destSquare = self.currentToken().value;
        self.advance();

        // Handle promotion
        if (self.currentToken().@"type" == .Promotion) {
            self.advance();
            if (self.currentToken().@"type" != .PromotionPiece) {
                return error.ExpectedPromotionPiece;
            }
            const promotionPiece = pieceTypeFromChar(self.currentToken().value[0]);
            moveData.promotion = promotionPiece;
            self.advance();
        }

        // Get target square
        const targetSquare = Square.fromString(moveData.destSquare);
        if (targetSquare == .None) {
            return error.InvalidDestinationSquare;
        }

        // Find matching legal move


        return &move;
    }

    fn parseComment(_: *Parser) !ParsedComment {
        // self.advance(); // consume CommentStart

        // var comment: []const u8 = undefined;
        // var commands = std.StringHashMapUnmanaged([]const u8){};

        // while (self.currentToken().@"type" != .CommentEnd and self.pos < self.tokens.len) {
        //     switch (self.currentToken().@"type") {
        //         .CommandStart => {
        //             const parsedCommands = self.parseCommand() catch |err| {
        //                 return err;
        //             };
        //         },
        //         .CommentText => {
        //         },
        //         else => {
        //             return PGNParsingError.UnexpectedTokenInComment;
        //         },
        //     }
        // }

        // return ParsedComment{
        //     .comment = comment,
        //     .commands = commands,
        // };
    }

    fn parseCommand(self: *Parser) !ParsedCommands {
        var commands = std.StringHashMapUnmanaged([]const u8){};
        var key : []const u8 = "";

        self.advance(); // consume CommandStart

        while (self.currentToken().@"type" != .CommandEnd and self.pos < self.tokens.len) {
            switch (self.currentToken().@"type") {
                .CommandName => {
                    // First token in a command is the key
                    key = self.currentToken().value;
                },
                .CommandParam => {
                    // Second token is the value for the current key
                    if (key.len > 0) {
                        commands.put(self.alloc, key, self.currentToken().value) catch |err| {
                            return err;
                        };
                        key = ""; // reset key for next command
                    }
                },
                else => {
                    return PGNParsingError.UnexpectedTokenInCommand;
                },
            }
            self.advance();
        }

        if (self.pos >= self.tokens.len) {
            return PGNParsingError.UnterminatedCommand;
        }

        return ParsedCommands{
            .commands = commands,
        };
    }

    fn parseVariation(self: *Parser, parentMoveNumber: u32, parentPly: i32) !void {
        self.advance(); // consume VariationStart

        // Save current state
        const parentMove = self.currentMove;
        const oldPos = self.game.pos;

        // For variations at game start, we attach to root
        var variationParent = self.game.rootMove;

        // Find the move this variation should branch from
        if (parentMove != self.game.rootMove and parentMove.parent != null) {   
            variationParent = parentMove.parent;         
            if (variationParent.parent != null and variationParent.parent.position != null) {
                const copiedPos = variationParent.parent.position.copy();
                self.game.pos = &copiedPos;
                const newPos = self.game.pos.update(variationParent) catch |err| {
                    return err;
                };
                self.game.pos = &newPos;
            } else {
                const copiedPos = self.game.rootMove.position.copy();
                self.game.pos = &copiedPos;
            }
        } else {
            const copiedPos = self.game.rootMove.position.copy();
            self.game.pos = &copiedPos;
        }

        self.currentMove = variationParent;

        var moveNumber = parentMoveNumber;
        var ply = parentPly;
        var isBlackMove = false;

        while (self.currentToken().@"type" != .VariationEnd and self.pos < self.tokens.len) {
            switch (self.currentToken().@"type") {
                .MoveNumber => {
                    const num = std.fmt.parseInt(u32, self.currentToken().value, 10) catch {
                    };
                },
                .Ellipsis => {
                },
                .VariationStart => {
                },
                .Piece, .Square, .File, .KingSideCastle, .QueenSideCastle => {
                },
                else => {
                    self.advance();
                }
            }
        }

        if (self.pos >= self.tokens.len) {
            return PGNParsingError.UnterminatedVariation;
        }

        self.advance(); // consume VariationEnd

        // Restore previous state
        self.game.pos = oldPos;
        self.currentMove = parentMove;
        self.game.currentMove = self.currentMove;
    }

    fn parseResult(self: *Parser) void {
        const map = std.StaticStringMap(u8, .{
            .@"1-0" = 1,
            .@"0-1" = 2,
            .@"1/2-1/2" = 3,
        });

        switch (map.get(self.currentToken().value) orelse 0) {
            1 => self.game.outcome = .WhiteWon,
            2 => self.game.outcome = .BlackWon,
            3 => self.game.outcome = .Draw,
            else => self.game.outcome = .NoOutcome,
        }

        self.advance();
    }

    fn addMove(self: *Parser, move: *Move) !void {
        // For the first move in the game
        if (self.currentMove == self.game.rootMove) {
            move.parent = self.game.rootMove;
            try self.game.rootMove.addChild(self.alloc, move);
        } else {
            // Normal move in the main line
            move.parent = self.currentMove;
            try self.currentMove.addChild(self.alloc, move);
        }

        // Update position
        const newPos = try self.game.pos.update(move);
        self.game.pos = &newPos;
        self.game.evaluatePositionStatus();

        move.position = &(self.game.pos.copy());
        self.currentMove = move;
    }
};
