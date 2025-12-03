const std = @import("std");

pub inline fn isLetter(ch: u8) bool {
    return ('a' <= ch and ch <= 'z') or ('A' <= ch and ch <= 'Z');
}

pub inline fn isDigit(ch: u8) bool {
    return '0' <= ch and ch <= '9';
}

pub inline fn isAlphanumeric(ch: u8) bool {
    return isLetter(ch) or isDigit(ch);
}

pub inline fn isWhitespace(ch: u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\n' or ch == '\r';
}

pub inline fn isResult(s: []const u8) bool {
    return std.mem.eql(u8, s, "1-0") or
           std.mem.eql(u8, s, "0-1") or
           std.mem.eql(u8, s, "1/2-1/2") or
           std.mem.eql(u8, s, "*");
}

pub inline fn isPiece(ch: u8) bool {
    return ch == 'N' or ch == 'B' or ch == 'R' or ch == 'Q' or ch == 'K';
}

pub inline fn isFile(ch: u8) bool {
    return 'a' <= ch and ch <= 'h';
}

pub inline fn isRank(ch: u8) bool {
    return '1' <= ch and ch <= '8';
}