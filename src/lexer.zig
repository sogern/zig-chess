const std = @import("std");
const utils = @import("utils.zig");

const TokenType = enum(u8) {
    EOF = 0,
    Undefined,
    TagStart,               // [
    TagEnd,                 // ]
    TagKey,                 // e.g. "Date"
    TagValue,               // e.g. "1997.05.03"
    MoveNumber,             // 1, 2, 3, etc.
    Dot,                    // .
    Ellipsis,               // ...
    Piece,                  // N, B, R, Q, K
    Square,                 // e4, e5, etc.
    CommentStart,           // {
    CommentEnd,             // }
    CommentText,
    Result,                 // 1-0, 0-1, 1/2-1/2, *
    Capture,                // 'x' in moves
    File,                   // a-h in moves when used as disambiguation
    Rank,                   // 1-8 in moves when used as disambiguation
    KingSideCastle,         // O-O
    QueenSideCastle,        // O-O-O
    Promotion,              // '=' in moves
    PromotionPiece,         // N, B, R, Q
    Check,                  // '+' in moves
    Checkmate,              // '#' in moves
    NAG,                    // Numeric Annotation Glyph, e.g. $1, $2
    VariationStart,         // (
    VariationEnd,           // )
    CommandStart,           // [%
    CommandName,            // e.g. clk, eval
    CommandParam,
    CommandEnd,             // ]
    DisambiguationSquare,   // Full square disambiguation, e.g. e8 in Qe8f7

    pub fn toString(self: TokenType) []const u8 {
        return switch (self) {
            .EOF => "EOF",
            .Undefined => "Undefined",
            .TagStart => "TagStart",
            .TagEnd => "TagEnd",
            .TagKey => "TagKey",
            .TagValue => "TagValue",
            .MoveNumber => "MoveNumber",
            .Dot => "Dot",
            .Ellipsis => "Ellipsis",
            .Piece => "Piece",
            .Square => "Square",
            .CommentStart => "CommentStart",
            .CommentEnd => "CommentEnd",
            .CommentText => "CommentText",
            .Result => "Result",
            .Capture => "Capture",
            .File => "File",
            .Rank => "Rank",
            .KingSideCastle => "KingSideCastle",
            .QueenSideCastle => "QueenSideCastle",
            .Promotion => "Promotion",
            .PromotionPiece => "PromotionPiece",
            .Check => "Check",
            .Checkmate => "Checkmate",
            .NAG => "NAG",
            .VariationStart => "VariationStart",
            .VariationEnd => "VariationEnd",
            .CommandStart => "CommandStart",
            .CommandName => "CommandName",
            .CommandParam => "CommandParam",
            .CommandEnd => "CommandEnd",
            .DisambiguationSquare => "DisambiguationSquare",
        };
    }
};

pub const LexerError = error {
    LexerUnexpectedEOF,
    LexerInvalidCommand,
    LexerInvalidResult,
    LexerInvalidRank,
    LexerInvalidPiece,
    LexerInvalidSquare,
    LexerNotCastling,
};

pub const Token = struct {
    @"error": ?LexerError = null,
    value: []const u8 = "",
    @"type": TokenType,
};

pub const Lexer = struct {
    alloc: std.mem.Allocator,
    input: []const u8,
    pos: usize = 0,
    readPos: usize = 0,
    ch: u8 = 0,
    inTag: bool = false,
    inComment: bool = false,
    inCommand: bool = false,
    inCommandParam: bool = false,

    fn readCommandName(self: *Lexer) Token {
        const pos = self.pos;
        while (utils.isAlphanumeric(self.ch)) {
            self.readChar();
        }
        self.inCommandParam = true;
        return Token{
            .@"type" = .CommandName,
            .value = self.input[pos..self.pos],
        };
    }

    fn readCommandParam(self: *Lexer) Token {
        self.skipWhitespace();

        if (self.ch == 0) {
            return Token{
                .@"type" = .EOF,
            };
        }

        var pos = self.pos;
        if (self.ch == '"') {
            self.readChar(); // consume opening quote
            pos = self.pos;
            while (self.ch != 0 and self.ch != '"') {
                self.readChar();
            }
            if (self.ch == 0) {
                return Token{
                    .@"error" = error.LexerUnexpectedEOF,
                    .@"type" = .EOF,
                };
            }
            const value = self.input[pos..self.pos];
            self.readChar(); // consume closing quote
            return Token{
                .@"type" = .CommandParam,
                .value = value,
            };
        }

        // Read until ',' or ']' for non-quoted parameters
        // Allow ':' and other characters within the parameter
        while (self.ch != 0 and self.ch != ',' and self.ch != ']' and self.ch != '}') {
            self.readChar();
        }

        if (self.ch == '}' and self.inCommand) {
            return Token{
                .@"error" = error.LexerInvalidCommand,
                .@"type" = .EOF,
            };
        }

        self.inCommandParam = self.ch == ',';
        return Token{
            .@"type" = .CommandParam,
            .value = self.input[pos..self.pos],
        };
    }

    fn readNAG(self: *Lexer) Token {
        var buf = std.ArrayList(u8).initCapacity(self.alloc, 4) catch unreachable;
        // Handle cases where NAG starts with '!' or '?'
        // According to PGN spec that shouldn't happen, but lichess does it.
        if (self.ch == '!' or self.ch == '?') {
            buf.append(self.alloc, self.ch) catch unreachable;
            self.readChar();

            // Check if the next character is also '!' or '?'
            if (self.ch == '!' or self.ch == '?') {
                buf.append(self.alloc, self.ch) catch unreachable;
                self.readChar();
            }

            return Token{
                .@"type" = .NAG,
                .value = buf.toOwnedSlice(self.alloc) catch unreachable,
            };
        }

        buf.append(self.alloc, '$') catch unreachable;
        self.readChar(); // consume '$'
        const pos = self.pos;

        while (utils.isDigit(self.ch)) {
            self.readChar();
        }

        buf.appendSlice(self.alloc, self.input[pos..self.pos]) catch unreachable;

        return Token{
            .@"type" = .NAG,
            .value = buf.toOwnedSlice(self.alloc) catch unreachable,
        };
    }

    fn readResult(self: *Lexer) Token {
        const pos = self.pos;
        while (self.ch != 0 and !utils.isWhitespace(self.ch)) {
            self.readChar();
        }
        const result = self.input[pos..self.pos];
        if (utils.isResult(result)) {
            return Token{
                .@"type" = .Result,
                .value = result,
            };
        }
        return Token{
            .@"error" = error.LexerInvalidResult,
            .@"type" = .Result,
            .value = result,
        };
    }

    fn readRank(self: *Lexer) Token {
        const rank: []const u8 = &[_]u8{self.ch};
        if (!utils.isRank(self.ch)) {
            self.readChar();
            return Token{
                .@"error" = error.LexerInvalidRank,
                .@"type" = .Undefined,
                .value = rank,
            };
        }
        self.readChar();
        return Token{
            .@"type" = .Rank,
            .value = rank,
        };
    }

    fn readComment(self: *Lexer) Token {
        const pos = self.pos;

        // Look for command start
        while (self.ch != 0 and self.ch != '}') {
            if (self.ch == '[' and self.peekChar() == '%') {
                if (pos != self.pos) {
                    // Return accumulated comment text before the command
                    return Token{
                        .@"type" = .CommentText,
                        .value = self.input[pos..self.pos],
                    };
                }
                // Start command
                self.readChar(); // consume '['
                self.readChar(); // consume '%'
                self.inCommand = true;
                
                if (self.ch ==  0) {
                    return Token{
                        .@"error" = error.LexerUnexpectedEOF,
                        .@"type" = .EOF,
                    };
                }
                return Token{
                    .@"type" = .CommandStart,
                };
            }
            self.readChar();
        }

        // Check for unterminated comment
        if (self.ch == 0) {
            self.readChar();
            return Token{
                .@"error" = error.LexerUnexpectedEOF,
                .@"type" = .EOF,
            };
        }

        if (pos != self.pos) {
            return Token{
                .@"type" = .CommentText,
                .value = self.input[pos..self.pos],
            };
        }

        return Token{
            .@"type" = .CommentEnd,
            .value = "}",
        };
    }

    fn readPieceMove(self: *Lexer) Token {
        const piece = self.ch;
        if (!utils.isPiece(self.ch)) {
            self.readChar();
            return Token{
                .@"error" = error.LexerInvalidPiece,
                .@"type" = .Piece,
                .value = &[_]u8{piece},
            };
        }
        self.readChar();

        // Return just the piece - the square or capture will be read in subsequent tokens
        return Token{
            .@"type" = .Piece,
            .value = &[_]u8{piece},
        };
    }

    fn readMove(self: *Lexer) Token {
        const disambiguationLength = 3;
        const disambiguationSquareLength = 4;

        const pos = self.pos;

        if (self.ch == 0) {
            return Token{
                .@"type" = .EOF,
            };
        }

        // Pawn move?
        if (utils.isFile(self.ch)) {
            const file = self.ch;
            self.readChar();

            // Check for capture
            if (self.ch == 'x') {
                return Token{
                    .@"type" = .File,
                    .value = &[_]u8{file},
                };
            }
        }

        while (utils.isFile(self.ch) or utils.isDigit(self.ch)) {
            self.readChar();
            if (self.ch == 0) {
                break;
            }
        }

        const length = self.pos - pos;

        // Handle full square disambiguation (e.g., "e8f7" -> "e8" then "f7")
        if (length == disambiguationSquareLength and
            utils.isFile(self.input[pos]) and
            utils.isDigit(self.input[pos + 1]) and
            utils.isFile(self.input[pos + 2]) and
            utils.isDigit(self.input[pos + 3])) {
            // Reset to return just the first quare
            self.pos = pos + 2;
            self.readPos = pos + 3;
            self.ch = self.input[self.pos]; // Set current char to the start of the second square
            return Token{
                .@"type" = .DisambiguationSquare,
                .value = self.input[pos..pos + 2],
            };
        }

        // If we read 3 characters, first one is disambiguation
        if (length == disambiguationLength) {
            self.readPos = pos + 1;
            self.readChar();
            // Return just the first character as disambiguation
            return Token{
                .@"type" = .File,
                .value = self.input[pos..pos + 1],
            };
        }

        // Validate the square (e.g., "e4")
        if (length < 2 or
            !utils.isFile(self.input[pos]) or
            pos + 1 >= self.input.len or
            !utils.isDigit(self.input[pos + 1])) {
            self.readChar();
            return Token{
                .@"error" = error.LexerInvalidSquare,
                .@"type" = .Square,
            };
        }

        return Token{
            .@"type" = .Square,
            .value = self.input[pos..self.pos],
        };
    }

    fn readPromotionPiece(self: *Lexer) Token {
        const piece = self.ch;
        if (!utils.isPiece(self.ch)) {
            self.readChar();
            return Token{
                .@"error" = error.LexerInvalidPiece,
                .@"type" = .PromotionPiece,
                .value = &[_]u8{piece},
            };
        }
        self.readChar();
        return Token{
            .@"type" = .PromotionPiece,
            .value = &[_]u8{piece},
        };
    }

    fn readChar(self: *Lexer) void {
        if (self.readPos >= self.input.len) {
            self.ch = 0;
        } else {
            self.ch = self.input[self.readPos];
        }
        self.pos = self.readPos;
        self.readPos += 1;
    }

    fn peekChar(self: *Lexer) u8 {
        if (self.readPos >= self.input.len) {
            return 0;
        } else {
            return self.input[self.readPos];
        }
    }

    fn skipWhitespace(self: *Lexer) void {
        while (self.readPos < self.input.len and
               (self.ch == ' ' or
                self.ch == '\n' or
                self.ch == '\r' or
                self.ch == '\t')) {
            self.readChar();
        }
    }

    fn readTagKey(self: *Lexer) Token {
        const pos = self.pos;
        while (utils.isAlphanumeric(self.ch)) {
            self.readChar();
        }
        return Token{
            .@"type" = .TagKey,
            .value = self.input[pos..self.pos],
        };
    }

    fn readTagValue(self: *Lexer) Token {
        self.readChar(); // skip opening quote
        const pos = self.pos;
        while (self.ch != 0 and self.ch != '"') {
            self.readChar();
        }
        const value = self.input[pos..self.pos];
        self.readChar(); // skip closing quote
        return Token{
            .@"type" = .TagValue,
            .value = value,
        };
    }

    fn readNumber(self: *Lexer) Token {
        const pos = self.pos;
        while (self.ch != 0 and utils.isDigit(self.ch)) {
            self.readChar();
        }
        return Token{
            .@"type" = .MoveNumber,
            .value = self.input[pos..self.pos],
        };
    }

    fn readCastling(self: *Lexer) !Token {
        const pos = self.pos;

        // First character should be uppercase 'O'
        if (self.ch != 'O') {
            return error.LexerNotCastling;
        }

        // Check if we have enough characters for at least kingside castling (O-O)
        if (self.readPos + 2 >= self.input.len) {
            return error.LexerUnexpectedEOF;
        }

        // Check for "O-O" pattern
        if (self.peekChar() != '-') {
            return error.LexerNotCastling;
        }
        self.readChar(); // consume 'O'
        self.readChar(); // consume '-'

        if (self.ch != 'O') {
            // Reset if pattern doesn't match
            self.pos = pos;
            self.readPos = pos + 1;
            self.ch = self.input[pos];
            return error.LexerNotCastling;            
        }
        self.readChar(); // consume 'O'

        // Look ahead to see if this is queenside castling (O-O-O)
        if (self.ch == '-' and self.peekChar() == 'O') {
            self.readChar(); // consume '-'
            self.readChar(); // consume 'O'
            return Token{
                .@"type" = .QueenSideCastle,
            };
        }
        return Token{
            .@"type" = .KingSideCastle,
        };
    }

    /// nextToken reads the next token from input.
    /// Returns EOF token when input is exhausted.
    /// Returns an illegal (error != null) token for invalid input.
    /// 
    /// The function handles standard PGN notation including:
    /// - Move notation (e4, Nf3, O-O, etc.)
    /// - Comments ({this is a comment} or ; comment)
    /// - Tags ([Event "World Championship"])
    /// - Move numbers and variations
    /// - Annotations ($1, !!, ?!, etc.)
    /// 
    /// Example:
    /// 
    /// const lexer = newLexer("1. e4 {Strong move}");
    /// var token = lexer.nextToken(); // MoveNumber token with value "1"
    /// token = lexer.nextToken(); // Dot token with value "."
    /// token = lexer.nextToken(); // Square token with value "e4"
    /// token = lexer.nextToken(); // Comment token with value "Strong move"
    /// token = lexer.nextToken(); // EOF token
    pub fn nextToken(self: *Lexer) Token {
        std.debug.print("Lexer nextToken at pos {d}, char '{c}'\n", .{self.pos, self.ch});
        self.skipWhitespace();

        if (self.inCommand) {
            switch (self.ch) {
                ']' => {
                    self.inCommand = false;
                    self.readChar();
                    return Token{
                        .@"type" = .CommandEnd,
                    };
                },
                ',' => {
                    self.readChar();
                    return self.readCommandParam();
                },
                else => {
                    // check if the previous token was command start
                    if (self.inCommandParam) {
                        return self.readCommandParam();
                    }
                    return self.readCommandName();
                }
            }
        }

        if (self.inComment) {
            if (self.ch == '}') {
                self.inComment = false;
                self.readChar();
                return Token{
                    .@"type" = .CommentEnd,
                    .value = "}",
                };
            }
            return self.readComment();
        }

        if (self.inTag and utils.isLetter(self.ch)) {
            return self.readTagKey();
        }

        switch (self.ch) {
            '(' => {
                self.readChar();
                return Token{
                    .@"type" = .VariationStart,
                };
            },
            ')' => {
                self.readChar();
                return Token{
                    .@"type" = .VariationEnd,
                };
            },
            '[' => {
                self.inTag = true;
                self.readChar();
                return Token{
                    .@"type" = .TagStart,
                    .value = "[",
                };
            },
            ']' => {
                self.inTag = false;
                self.readChar();
                return Token{
                    .@"type" = .TagEnd,
                    .value = "]",
                };
            },
            '"' => {
                return self.readTagValue();
            },
            '{' => {
                self.readChar();
                self.inComment = true;
                return Token{
                    .@"type" = .CommentStart,
                    .value = "{",
                };
            },
            '}' => {
                self.readChar();
                return Token{
                    .@"type" = .CommentEnd,
                    .value = "}",
                };
            },
            '.' => {
                if (self.peekChar() == '.' and self.readPos + 1 < self.input.len and self.input[self.readPos + 1] == '.') {
                    self.readChar();
                    self.readChar();
                    self.readChar();
                    return Token{
                        .@"type" = .Ellipsis,
                        .value = "...",
                    };
                }
                self.readChar();
                return Token{
                    .@"type" = .Dot,
                    .value = ".",
                };
            },
            'x' => {
                self.readChar();
                return Token{
                    .@"type" = .Capture,
                };
            },
            '*', '-' => {
                return self.readResult();
            },
            '$', '!', '?' => {
                return self.readNAG();
            },
            'O' => {
                // Check for castling
                const castling = self.readCastling() catch {
                    // If not castling, treat as regular move
                    return self.readPieceMove();
                };
                return castling;
            },
            '=' => {
                self.readChar();
                return Token{
                    .@"type" = .Promotion,
                };
            },
            '+' => {
                self.readChar();
                return Token{
                    .@"type" = .Check,
                };
            },
            '#' => {
                self.readChar();
                return Token{
                    .@"type" = .Checkmate,
                };
            },
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
                if (self.inTag) {
                    return self.readTagValue();
                }

                // Look at previous characters to determine context
                if (self.pos > 0 and utils.isUpper(self.input[self.pos - 1])) {
                    // If preceded by a piece, it's a rank disambiguation
                    return self.readRank();
                }

                // Look ahead to see if this number is followed by a dot or hyphen
                const pos = self.pos;
                while (self.ch != 0 and utils.isDigit(self.ch)) {
                    self.readChar();
                }

                switch(self.ch) {
                    '.' => {
                        return Token{
                            .@"type" = .MoveNumber,
                            .value = self.input[pos..self.pos],
                        };
                    },
                    '-' => {
                        self.pos = pos;
                        self.readPos = pos + 1;
                        self.ch = self.input[pos];
                        return self.readResult();
                    },
                    else => {
                        // Reset position and try again as a regular number
                        self.pos = pos;
                        self.readPos = pos + 1;
                        self.ch = self.input[pos];
                        return self.readNumber();
                    }
                }
            },
            0 => {
                return Token{
                    .@"type" = .EOF,
                };
            },
            else => {
                if (utils.isLetter(self.ch)) {
                    if (utils.isUpper(self.ch)) {
                        // If it follows a piece token, it's a promotion piece
                        if (self.pos > 0 and self.input[self.pos - 1] == '=') {
                            return self.readPromotionPiece();
                        }
                        return self.readPieceMove();
                    }
                }
                return self.readMove();
            }
        }

        const tok = Token{
            .@"type" = .Undefined,
            .value = &[_]u8{self.ch},
        };
        self.readChar();
        return tok;
    }
};

pub fn newLexer(alloc: std.mem.Allocator, input: []const u8) Lexer {
    var l = Lexer{
        .alloc = alloc,
        .input = input,
    };
    l.readChar();
    return l;
}

test "Test Lexer" {
    const input = @embedFile("lexer/0001.pgn");

    var lexer = newLexer(std.testing.allocator, input);
    
    const testCase = struct {
        @"type": TokenType,
        value: []const u8,
    };

    const expectedTokens = [_]testCase{
        .{.@"type" = .TagStart, .value = "["},
		.{.@"type" = .TagKey, .value = "Event"},
		.{.@"type" = .TagValue, .value = "Example"},
		.{.@"type" = .TagEnd, .value = "]"},
		.{.@"type" = .TagStart, .value = "["},
		.{.@"type" = .TagKey, .value = "Site"},
		.{.@"type" = .TagValue, .value = "Internet"},
		.{.@"type" = .TagEnd, .value = "]"},
		.{.@"type" = .TagStart, .value = "["},
		.{.@"type" = .TagKey, .value = "Date"},
		.{.@"type" = .TagValue, .value = "2023.12.06"},
		.{.@"type" = .TagEnd, .value = "]"},
		.{.@"type" = .TagStart, .value = "["},
		.{.@"type" = .TagKey, .value = "Round"},
		.{.@"type" = .TagValue, .value = "1"},
		.{.@"type" = .TagEnd, .value = "]"},
		.{.@"type" = .TagStart, .value = "["},
		.{.@"type" = .TagKey, .value = "White"},
		.{.@"type" = .TagValue, .value = "Player1"},
		.{.@"type" = .TagEnd, .value = "]"},
		.{.@"type" = .TagStart, .value = "["},
		.{.@"type" = .TagKey, .value = "Black"},
		.{.@"type" = .TagValue, .value = "Player2"},
		.{.@"type" = .TagEnd, .value = "]"},
		.{.@"type" = .TagStart, .value = "["},
		.{.@"type" = .TagKey, .value = "Result"},
		.{.@"type" = .TagValue, .value = "1-0"},
		.{.@"type" = .TagEnd, .value = "]"},
		.{.@"type" = .MoveNumber, .value = "1"},
		.{.@"type" = .Dot, .value = "."},
		.{.@"type" = .Square, .value = "e4"},
		.{.@"type" = .Square, .value = "e5"},
		.{.@"type" = .MoveNumber, .value = "2"},
		.{.@"type" = .Dot, .value = "."},
		.{.@"type" = .Piece, .value = "N"},
		.{.@"type" = .Square, .value = "f3"},
		.{.@"type" = .Piece, .value = "N"},
		.{.@"type" = .Square, .value = "c6"},
		.{.@"type" = .MoveNumber, .value = "3"},
		.{.@"type" = .Dot, .value = "."},
		.{.@"type" = .Piece, .value = "B"},
		.{.@"type" = .Square, .value = "b5"},
		.{.@"type" = .CommentStart, .value = "{"},
		.{.@"type" = .CommentText, .value = "This is the Ruy Lopez."},
		.{.@"type" = .CommentEnd, .value = "}"},
		.{.@"type" = .MoveNumber, .value = "3"},
		.{.@"type" = .Ellipsis, .value = "..."},
		.{.@"type" = .Square, .value = "a6"},
		.{.@"type" = .Result, .value = "1-0"},
    };

    for (expectedTokens, 0..) |expected, i| {
        std.debug.print("Testing {d}: ({s} {s})\n", .{i, expected.@"type".toString(), expected.value});
        const token = lexer.nextToken();
        try std.testing.expect(token.@"type" == expected.@"type");
        try std.testing.expectEqualStrings(expected.value, token.value);
    }

    // Expect EOF at the end
    const token = lexer.nextToken();
    try std.testing.expect(token.@"type" == .EOF);
}