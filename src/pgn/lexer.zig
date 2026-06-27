const std = @import("std");
const builtin = @import("builtin");

pub const Self = @This();

pub const Token = union(enum) {
    tagStart,                           // [
    tagEnd,                             // ]
    tagKey: []const u8,                 // e.g. "Date"
    tagValue: []const u8,               // e.g. "1997.05.03"
    moveNum: u16,                       // 1, 2, 3, etc.
    moveStart,                          // Start of a move
    moveEnd,                            // End of a move
    dot,                                // .
    ellipsis,
    piece: u8,                          // P, N, B, R, Q, K
    file: u8,                           // a-h
    square: []const u8,                 // e.g. "e4"
    capture,                            // x
    promotion: u8,                      // =Q, =R, =B, =N
    kingSideCastle,                     // O-O
    queenSideCastle,                    // O-O-O
    check,                              // +
    checkmate,                          // #
    nag: []const u8,                    // e.g. $1, $2, $3, ?!, !!, etc.
    commentStart,                       // {
    commentEnd,                         // }
    comment: []const u8,                // Text
    result: []const u8,                 // 1-0, 0-1, 1/2-1/2, *
    variationStart,                     // (
    variationEnd,                       // )
    variation: []const u8,              // e.g. (1. e4 e5 2. Nf3 Nc6)
    commandStart,                       // [%
    commandEnd,                         // ]
    commandName: []const u8,            // e.g. clk, eval
    commandParam: []const u8,           // Text
    eof,
    @"error": LexerError,

    pub fn format(self: @This(), writer: *std.io.Writer) !void {
        switch (self) {
            .tagStart => try writer.print("TagStart", .{}),
            .tagEnd => try writer.print("TagEnd", .{}),
            .tagKey => |s| try writer.print("TagKey({s})", .{s}),
            .tagValue => |s| try writer.print("TagValue({s})", .{s}),
            .moveNum => |d| try writer.print("MoveNum({d})", .{d}),
            .moveStart => try writer.print("MoveStart", .{}),
            .moveEnd => try writer.print("MoveEnd", .{}),
            .dot => try writer.print("Dot", .{}),
            .ellipsis => try writer.print("Ellipsis", .{}),
            .piece => |c| try writer.print("Piece({c})", .{c}),
            .file => |c| try writer.print("File({c})", .{c}),
            .square => |s| try writer.print("Square({s})", .{s}),
            .capture => try writer.print("Capture", .{}),
            .promotion => |c| try writer.print("Promotion({c})", .{c}),
            .kingSideCastle => try writer.print("KingSideCastle", .{}),
            .queenSideCastle => try writer.print("QueenSideCastle", .{}),
            .check => try writer.print("Check", .{}),
            .checkmate => try writer.print("Checkmate", .{}),
            .nag => |s| try writer.print("NAG({s})", .{s}),
            .commentStart => try writer.print("CommentStart", .{}),
            .commentEnd => try writer.print("CommentEnd", .{}),
            .comment => |s| try writer.print("Comment({s})", .{s}),
            .result => |s| try writer.print("Result({s})", .{s}),
            .variationStart => try writer.print("VariationStart", .{}),
            .variationEnd => try writer.print("VariationEnd", .{}),
            .variation => |s| try writer.print("Variation({s})", .{s}),
            .commandStart => try writer.print("CommandStart", .{}),
            .commandEnd => try writer.print("CommandEnd", .{}),
            .commandName => |s| try writer.print("CommandName({s})", .{s}),
            .commandParam => |s| try writer.print("CommandParam({s})", .{s}),
            .eof => try writer.print("EOF", .{}),
            .@"error" => |err| try writer.print("Error({})", .{err}),
        }
    }
};

pub const LexerError = error {
    UnexpectedEOF,
    UnexpectedCharacter,
    ParseError,
    Unknown,
};

pub const Scanner = struct {
    buf: []const u8,
    pos: usize = 0,
    state: State = .start,
    lastError: ?LexerError = null,

    const State = enum(u8) {
        start = 0,
        tag_key,
        tag_value,
        move_or_result,
        move_num,
        move_start,
        piece_or_square,
        square_or_file,
        move_end,
        punctuation,
        comment_start,
        comment_text,
        comment_end,
        command_start,
        command_name,
        command_param,
        command_end,
        variation_start,
        variation_end,
        result,
        eof,
        @"error",
    };

    /// Returns the next `Token` from input PGN.
    pub fn next(self: *@This()) !Token {
        if (self.state != .@"error" and self.pos >= self.buf.len) {
            self.state = .eof;
        }
        try switch (self.state) {
            .start => {
                self.skipWhitespace();
                if (self.peek(0)) |c| {
                    if (c == '[') {
                        self.pos += 1; // consume '['
                        self.state = .tag_key;
                        return .{ .tagStart = {} };
                    } else {
                        self.state = .move_or_result;
                    }
                } else {
                    self.state = .eof;
                }
                return self.next();
            },
            .tag_key => {
                const key = self.readUntilWhitespace();
                if (key.len == 0) {
                    self.setError(LexerError.UnexpectedEOF);
                    return self.next();
                }
                self.state = .tag_value;
                return .{ .tagKey = key };
            },
            .tag_value => {
                self.skipWhitespace();
                if (self.peek(0) == '"') {
                    self.pos += 1; // consume opening quote
                    const value = self.readUntilAny("\"");
                    if (self.peek(0) == '"') {
                        self.pos += 1; // consume closing quote
                        self.skipWhitespace();
                        if (self.peek(0) == ']') {
                            self.pos += 1; // consume ']'
                        } else {
                            self.setError(LexerError.UnexpectedCharacter);
                            return self.next();
                        }
                    } else {
                        self.setError(LexerError.UnexpectedEOF);
                        return self.next();
                    }
                    self.state = .start;
                    return .{ .tagValue = value };
                }
                self.setError(LexerError.UnexpectedCharacter);
                return self.next();
            },
            .move_or_result => {
                if (self.peek(0)) |c| {
                    switch (c) {
                        '*' => {
                            self.state = .result;
                        },
                        '0' => {
                            if (self.peek(1)) |n| {
                                if (n == '-') {
                                    self.state = .result;
                                } else {
                                    self.setError(LexerError.UnexpectedCharacter);
                                }
                            } else {
                                self.setError(LexerError.UnexpectedEOF);
                            }
                        },
                        '1' => {
                            if (self.peek(1)) |n| {
                                if (n == '-' or n == '/') {
                                    self.state = .result;
                                } else if (std.ascii.isDigit(n) or n == '.') {
                                    self.state = .move_num;
                                } else {
                                    self.setError(LexerError.UnexpectedCharacter);
                                }
                            } else {
                                self.setError(LexerError.UnexpectedEOF);
                            }
                        },
                        else => {
                            if (std.ascii.isDigit(c)) {
                                self.state = .move_num;
                            } else if (std.ascii.isAlphabetic(c)) {
                                self.state = .move_start;
                            } else {
                                self.setError(LexerError.UnexpectedCharacter);
                            }
                        },
                    }
                } else {
                    self.setError(LexerError.UnexpectedEOF);
                }
                return self.next();
            },
            .move_num => {
                const integer = self.readInteger();
                if (integer.len == 0) {
                    self.setError(LexerError.UnexpectedEOF);
                    return self.next();
                }
                const moveNum = std.fmt.parseInt(u16, integer, 10) catch {
                    self.setError(LexerError.ParseError);
                    return self.next();
                };
                if (self.peek(0)) |c| {
                    if (c == '.') {
                        self.state = .punctuation;
                    } else {
                        self.setError(LexerError.UnexpectedCharacter);
                    }
                }
                return .{ .moveNum = moveNum };
            },
            .move_start => {
                // Do we have at least 2 characters for a move?
                if (self.pos + 1 >= self.buf.len) {
                    self.setError(LexerError.UnexpectedEOF);
                } else {
                    self.state = .piece_or_square;
                }
                return .{ .moveStart = {} };
            },
            .piece_or_square => {
                if (self.peek(0)) |c| {
                    switch (c) {
                        'K', 'Q', 'R', 'B', 'N' => {
                            self.pos += 1; // consume piece
                            self.state = .square_or_file;
                            return .{ .piece = c };
                        },
                        'a'...'h' => {
                            self.state = .square_or_file;
                            return self.next();
                        },
                        'x' => {
                            self.pos += 1; // consume 'x'
                            self.state = .square_or_file;
                            return .{ .capture = {} };
                        },
                        'O' => {
                            const m = self.readUntilWhitespace();
                            if (m.len == 3 and std.mem.eql(u8, m, "O-O")) {
                                self.state = .move_end;
                                return .{ .queenSideCastle = {} };
                            } else if (m.len == 5 and std.mem.eql(u8, m, "O-O-O")) {
                                self.state = .move_end;
                                return .{ .kingSideCastle = {} };
                            }
                            self.setError(LexerError.UnexpectedCharacter);
                            return self.next();
                        },
                        else => {
                            self.setError(LexerError.UnexpectedCharacter);
                            return self.next();
                        },
                    }
                }
                self.setError(LexerError.UnexpectedEOF);
                return self.next();
            },
            .square_or_file => {
                if (self.peek(0)) |c| {
                    if (std.ascii.isWhitespace(c)) {
                        self.state = .move_end;
                        return self.next();
                    }
                    switch (c) {
                        'a'...'h' => {
                            if (self.peek(1)) |n| {
                                switch (n) {
                                    '1'...'8' => {
                                        const square = self.buf[self.pos..self.pos + 2];
                                        self.pos += 2; // consume square
                                        return .{ .square = square };
                                    },
                                    else => {
                                        const file = self.buf[self.pos];
                                        self.pos += 1; // consume file
                                        return .{ .file = file };
                                    }
                                }
                            }
                            self.setError(LexerError.UnexpectedEOF);
                            return self.next();
                        },
                        'x' => {
                            self.pos += 1; // consume 'x'
                            return .{ .capture = {} };
                        },
                        '+', '#' => {
                            self.pos += 1; // consume '+' or '#'
                            if (c == '+') {
                                return .{ .check = {} };
                            } else {
                                return .{ .checkmate = {} };
                            }
                        },
                        '?', '!', '$' => {
                            const nag = self.readUntilWhitespace();
                            return .{ .nag = nag };
                        },
                        ')' => {
                            self.pos += 1; // consume ')'
                            self.state = .variation_end;
                            return self.next();
                        },
                        else => {
                            self.setError(LexerError.UnexpectedCharacter);
                            return self.next();
                        }
                    }
                }
                self.setError(LexerError.UnexpectedEOF);
                return self.next();
            },
            .move_end => {
                self.skipWhitespace();
                if (self.peek(0)) |c| {
                    switch (c) {
                        '{' => {
                            self.pos += 1; // consume '{'
                            self.state = .comment_start;
                            return self.next();
                        },
                        '(' => {
                            self.pos += 1; // consume '('
                            self.state = .variation_start;
                            return self.next();
                        },
                        ')' => {
                            self.pos += 1; // consume ')'
                            self.state = .variation_end;
                            return .{ .moveEnd = {} };
                        },
                        else => {
                            // Handled below
                        }
                    }
                }
                self.state = .move_or_result;
                return .{ .moveEnd = {} };
            },
            .punctuation => {
                const p = self.readAll('.');
                self.skipWhitespace();
                self.state = .move_start;
                if (p.len == 1) {
                    return .{ .dot = {} };
                } else if (p.len == 3) {
                    return .{ .ellipsis = {} };
                }
                self.setError(LexerError.UnexpectedCharacter);
                return self.next();
            },
            .comment_start => {
                self.skipWhitespace();
                // TODO: Peek whether it is text or command
                self.state = .comment_text;
                return .{ .commentStart = {} };
            },
            .comment_text => {
                const comment = self.readUntilAny("}");
                self.state = .comment_end;
                return .{ .comment = std.mem.trimEnd(u8, comment, &std.ascii.whitespace) };
            },
            .comment_end => {
                if (self.peek(0) == '}') {
                    self.pos += 1; // consume '}'
                    self.state = .move_end;
                    return .{ .commentEnd = {} };
                }
                self.setError(LexerError.UnexpectedCharacter);
                return self.next();
            },
            .command_start => return error.NotImplemented,
            .command_name => return error.NotImplemented,
            .command_param => return error.NotImplemented,
            .command_end => return error.NotImplemented,
            .variation_start => {
                self.skipWhitespace();
                if (self.peek(0)) |c| {
                    if (std.ascii.isDigit(c)) {
                        self.state = .move_num;
                    } else if (std.ascii.isAlphabetic(c)) {
                        self.state = .move_start;
                    } else {
                        self.setError(LexerError.UnexpectedCharacter);
                        return self.next();
                    }
                }
                return .{ .variationStart = {} };
            },
            .variation_end => {
                self.state = .move_end;
                return .{ .variationEnd = {} };
            },
            .result => {
                const r = self.readUntilWhitespace();
                self.state = .start;
                return .{ .result = r };
            },
            .eof => return .{ .eof = {} },
            .@"error" => 
                return if (self.lastError) |err|
                    err
                else
                    LexerError.Unknown // Reaching here is a bug
        };

        return LexerError.Unknown; // Reaching here is a bug
    }

    /// Skips whitespace characters in the input buffer, advancing the position.
    inline fn skipWhitespace(self: *@This()) void {
        while (self.pos < self.buf.len and std.ascii.isWhitespace(self.buf[self.pos])) {
            self.pos += 1;
        }
    }

    fn peek(self: *@This(), offset: usize) ?u8 {
        const pos = self.pos + offset;
        if (pos < self.buf.len) {
            return self.buf[pos];
        }
        return null;
    }

    /// Reads characters until any of the specified delimiters is found, and returns the substring.
    /// The position is advanced to the delimiter, or end of input, but the delimiter itself is not consumed.
    fn readUntilAny(self: *@This(), any: []const u8) []const u8 {
        const start = self.pos;
        if (std.mem.indexOfAny(u8, self.buf[self.pos..], any)) |i| {
            self.pos += i;
            return self.buf[start..self.pos];
        }
        self.pos = self.buf.len;
        return self.buf[start..];
    }

    fn readUntilWhitespace(self: *@This()) []const u8 {
        return self.readUntilAny(&std.ascii.whitespace);
    }

    fn readInteger(self: *@This()) []const u8 {
        const start = self.pos;
        while (self.pos < self.buf.len and std.ascii.isDigit(self.buf[self.pos])) {
            self.pos += 1;
        }
        return self.buf[start..self.pos];
    }

    /// Reads characters while they match the specified character, and returns the substring.
    fn readAll(self: *@This(), c: u8) []const u8 {
        const start = self.pos;
        while (self.pos < self.buf.len and self.buf[self.pos] == c) {
            self.pos += 1;
        }
        return self.buf[start..self.pos];
    }

    inline fn setError(self: *@This(), err: LexerError) void {
        self.lastError = err;
        self.state = .@"error";
    }
};

/// Returns an iterator that produces `Token`s from input PGN.
pub fn scanner(pgn: []const u8) Scanner {
    return Scanner{ .buf = pgn };
}

test scanner {
    if (builtin.os.tag == .windows) {
        // Set console output code page to UTF-8 on Windows to properly display Unicode characters
        _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);
    }
    const pgn = @embedFile("0001.pgn");
    var s = Self.scanner(pgn);
    std.debug.print("Tokens:\n", .{});
    var t: Token = undefined;
    while (true) {
        t = try s.next();
        std.debug.print(" {f}\n", .{t});
        if (t == .@"error" or t == .eof) break;
    }
}