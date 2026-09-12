const std = @import("std");
const mem = std.mem;
const Io = std.Io;
const File = Io.File;
const process = std.process;
const fmt = std.fmt;

/// Sorted in order of code points.
const ASCII_CHARS = [_][]const u8{ "NUL", "SOH", "STX", "ETX", "EOT", "ENQ", "ACK", "BEL", "BS", "HT", "LF", "VT", "FF", "CR", "SO", "SI", "DLE", "DC1", "DC2", "DC3", "DC4", "NAK", "SYN", "ETB", "CAN", "EM", "SUB", "ESC", "FS", "GS", "RS", "US", "SP", "!", "\"", "#", "$", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "?", "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", "\\", "]", "^", "_", "'", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "{", "|", "}", "~", "DEL" };

const ASCII_TABLE_TEXT = block: {
    @setEvalBranchQuota(10000000);

    const partsLen = 4;

    const partLen = ASCII_CHARS.len / partsLen;

    const parts = partsBlock: {
        var parts: [partsLen][]const []const u8 = undefined;

        var remaining: []const []const u8 = ASCII_CHARS[0..];
        for (&parts) |*part| {
            part.* = remaining[0..partLen];
            remaining = remaining[partLen..];
        }

        break :partsBlock parts;
    };

    var text: []const u8 = "";

    const partsRightGap = repeat(6, " ");

    const colPadding = repeat(1, " ");

    const colHeaders = .{ "Char", "DEC", "BIN     ", "HEX" };

    const head = headBlock: {
        var headTop: []const u8 = "";
        var headContent: []const u8 = "";
        var headBot: []const u8 = "";

        for (0..parts.len) |partIndex| {
            const isLastPart = partIndex == parts.len - 1;

            headTop = headTop ++ "┌";
            headContent = headContent ++ "│";
            headBot = headBot ++ "├";

            for (colHeaders, 0..) |colText, colIndex| {
                const isLastCol = colIndex == colHeaders.len - 1;

                headTop = headTop ++ repeat(colText.len + colPadding.len * 2, "─");
                headContent = headContent ++ colPadding ++ colText ++ colPadding ++ "│";
                headBot = headBot ++ repeat(colText.len + colPadding.len * 2, "─");

                if (isLastCol) {
                    headTop = headTop ++ "┐";
                    headBot = headBot ++ "┤";
                } else {
                    headTop = headTop ++ "┬";
                    headBot = headBot ++ "┼";
                }
            }

            if (isLastPart) {
                headTop = headTop ++ "\n";
                headContent = headContent ++ "\n";
                headBot = headBot ++ "\n";

                break :headBlock headTop ++ headContent ++ headBot;
            } else {
                headTop = headTop ++ partsRightGap;
                headContent = headContent ++ partsRightGap;
                headBot = headBot ++ partsRightGap;
            }
        }
    };

    text = text ++ head;

    var charsCount = 0;

    while (charsCount < ASCII_CHARS.len) : (charsCount += partsLen) {
        var rowContent: []const u8 = "";
        var rowBot: []const u8 = "";

        for (0..parts.len) |partIndex| {
            const partCharsStart = partIndex * partLen;
            const charPartIndex = charsCount / partsLen;

            const isLastPart = partIndex == partsLen - 1;
            const isLastRow = charPartIndex == partLen - 1;

            const charCodePoint = partCharsStart + charPartIndex;
            const char = ASCII_CHARS[charCodePoint];

            rowContent = rowContent ++ "│";
            rowBot = rowBot ++ if (isLastRow) "└" else "├";

            const rowBotBorderCorner = if (isLastRow) "┴" else "┼";

            const colValues: [colHeaders.len][]const u8 = .{
                char,
                formatNum(.Dec, charCodePoint),
                padStart(8, formatNum(.Bin, charCodePoint), '0'),
                formatNum(.Hex, charCodePoint),
            };

            for (colHeaders, colValues, 0..) |header, value, index| {
                const isLastCol = index == colHeaders.len - 1;

                const colBotBorderCorner = if (isLastCol) "┘" else rowBotBorderCorner;

                rowContent = rowContent ++ colPadding ++ padEnd(header.len, value, ' ') ++ " │";
                rowBot = rowBot ++ repeat(header.len + colPadding.len * 2, "─") ++ colBotBorderCorner;
            }

            const partsGapStr =
                if (isLastPart) "\n" else partsRightGap;

            rowContent = rowContent ++ partsGapStr;
            rowBot = rowBot ++ partsGapStr;
        }

        text = text ++ rowContent ++ rowBot;
    }

    break :block text;
};

fn repeat(comptime count: usize, comptime str: []const u8) []const u8 {
    var result: []const u8 = str;
    for (1..count) |_| result = result ++ str;

    return result;
}

fn padStart(comptime newLen: usize, comptime str: []const u8, comptime char: u8) []const u8 {
    return @as([newLen - str.len]u8, @splat(char)) ++ str;
}
fn padEnd(comptime newLen: usize, comptime str: []const u8, comptime char: u8) []const u8 {
    return str ++ @as([newLen - str.len]u8, @splat(char));
}

fn formatNum(comptime notation: enum { Bin, Dec, Hex }, comptime num: comptime_int) []const u8 {
    return fmt.comptimePrint(
        switch (notation) {
            .Bin => "{b}",
            .Dec => "{d}",
            .Hex => "{x}",
        },
        .{num},
    );
}
