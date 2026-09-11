const std = @import("std");
const mem = std.mem;
const Io = std.Io;
const File = Io.File;
const process = std.process;
const fmt = std.fmt;

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

fn formatNumber(comptime notation: enum { Bin, Dec, Hex }, comptime number: comptime_int) []const u8 {
    return fmt.comptimePrint(
        switch (notation) {
            .Bin => "{b}",
            .Dec => "{d}",
            .Hex => "{x}",
        },
        .{number},
    );
}
