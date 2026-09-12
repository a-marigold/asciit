const std = @import("std");
const mem = std.mem;
const math = std.math;
const Io = std.Io;
const File = Io.File;
const process = std.process;
const fmt = std.fmt;

/// Sorted in order of code points.
const ASCII_CHARS = [_][]const u8{ "NUL", "SOH", "STX", "ETX", "EOT", "ENQ", "ACK", "BEL", "BS", "HT", "LF", "VT", "FF", "CR", "SO", "SI", "DLE", "DC1", "DC2", "DC3", "DC4", "NAK", "SYN", "ETB", "CAN", "EM", "SUB", "ESC", "FS", "GS", "RS", "US", "SP", "!", "\"", "#", "$", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "?", "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", "\\", "]", "^", "_", "'", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "{", "|", "}", "~", "DEL" };

// const BORDERS = struct {
//     const HOR_LINE = "─";
//     const VERT_LINE = "│";

//     const TOP_LEFT = "┌";
//     const TOP_MID = "┬";
//     const TOP_RIGHT = "┐";

//     const MID_LEFT = "├";
//     const MID_MID = "┼";
//     const MID_RIGHT = "┤";

//     const BOT_LEFT = "└";
//     const BOT_MID = "┴";
//     const BOT_RIGHT = "┘";
// };

const BORDERS = struct {
    const HOR_LINE = "-";
    const VERT_LINE = "|";

    const TOP_LEFT = "+";
    const TOP_MID = "+";
    const TOP_RIGHT = "+";

    const MID_LEFT = "+";
    const MID_MID = "+";
    const MID_RIGHT = "+";

    const BOT_LEFT = "+";
    const BOT_MID = "+";
    const BOT_RIGHT = "+";
};

const ASCII_TABLE_TEXT = block: {
    @setEvalBranchQuota(math.maxInt(u32));

    const partsLen = 4;

    const partLen = ASCII_CHARS.len / partsLen;

    const parts = partsBlock: {
        var parts: [partsLen]*const [partLen][]const u8 = undefined;

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
            const isLastPart = partIndex == partsLen - 1;

            headTop = headTop ++ BORDERS.TOP_LEFT;
            headContent = headContent ++ BORDERS.VERT_LINE;
            headBot = headBot ++ BORDERS.MID_LEFT;

            for (colHeaders, 0..) |colText, colIndex| {
                const isLastCol = colIndex == colHeaders.len - 1;

                headTop = headTop ++ repeat(colText.len + colPadding.len * 2, BORDERS.HOR_LINE);
                headContent = headContent ++ colPadding ++ colText ++ colPadding ++ BORDERS.VERT_LINE;
                headBot = headBot ++ repeat(colText.len + colPadding.len * 2, BORDERS.HOR_LINE);

                if (isLastCol) {
                    headTop = headTop ++ BORDERS.TOP_RIGHT;
                    headBot = headBot ++ BORDERS.MID_RIGHT;
                } else {
                    headTop = headTop ++ BORDERS.TOP_MID;
                    headBot = headBot ++ BORDERS.MID_MID;
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

            rowContent = rowContent ++ BORDERS.VERT_LINE;
            rowBot = rowBot ++ if (isLastRow) BORDERS.BOT_LEFT else BORDERS.MID_LEFT;

            const colValues: [colHeaders.len][]const u8 = .{
                char,
                formatNum(.Dec, charCodePoint),
                padStart(8, formatNum(.Bin, charCodePoint), '0'),
                formatNum(.Hex, charCodePoint),
            };

            for (colHeaders, colValues, 0..) |header, value, index| {
                const isLastCol = index == colHeaders.len - 1;

                const colBotRightBorder =
                    if (isLastCol and isLastRow)
                        BORDERS.BOT_RIGHT
                    else if (isLastCol)
                        BORDERS.MID_RIGHT
                    else if (isLastRow)
                        BORDERS.BOT_MID
                    else
                        BORDERS.MID_MID;

                rowContent = rowContent ++ colPadding ++ padEnd(
                    header.len,
                    value,
                    ' ',
                ) ++ colPadding ++ BORDERS.VERT_LINE;
                rowBot = rowBot ++ repeat(header.len + colPadding.len * 2, BORDERS.HOR_LINE) ++ colBotRightBorder;
            }

            const partGap =
                if (isLastPart) "\n" else partsRightGap;

            rowContent = rowContent ++ partGap;
            rowBot = rowBot ++ partGap;
        }

        text = text ++ rowContent ++ rowBot;
    }

    break :block text;
};

pub fn main() !void {
    // `undefined` as allocator is safe 'cause no `Io` function requiring allocator is used
    var threaded: Io.Threaded = .init(undefined, .{});
    const io = threaded.io();

    const stdoutWriter = block: {
        var stdout = File.stdout().writerStreaming(io, &.{});
        break :block &stdout.interface;
    };

    return writeUnbuffered(stdoutWriter, ASCII_TABLE_TEXT);
}

inline fn writeUnbuffered(writer: *Io.Writer, data: []const u8) !void {
    _ = try writer.vtable.drain(writer, &.{data}, 1);
}

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
