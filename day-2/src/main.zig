//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");

const CollatingSequence = enum {
    INCREASING,
    DECREASING
};

fn isSafe(report: []u32) bool {
    if (report[0] == report[1]) return false;
    const collating_sequence = switch (report[0] < report[1]) {
        true => CollatingSequence.INCREASING,
        false => CollatingSequence.DECREASING
    };
    var previous_level: i64 = @as(i64, report[0]);
    var i: usize = 1;
    while (i < report.len) {
        const current_level = @as(i64, report[i]);
        switch (collating_sequence) {
            CollatingSequence.INCREASING => {
                if (current_level <= previous_level) { // not increasing
                    return false;
                } else if (current_level - previous_level > 3) { // increasing by too much
                    return false;
                }
            },
            CollatingSequence.DECREASING => {
                if (previous_level <= current_level) { // not decreasing
                    return false;
                } else if (previous_level - current_level > 3) { // decreasing by too much
                    return false;
                }
            }
        }
        previous_level = current_level;
        i = i + 1;
    }
    return true;
}

pub fn main() !void {
    var total_safe: u64 = 0;

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var buffer: [16]u32 = undefined;
        @memset(&buffer, 0);
        var iter = std.mem.tokenizeAny(u8, line, " ");
        var len: usize = 0;
        while (iter.next()) |level| {
            const level_value = try std.fmt.parseInt(u32, level, 10);
            buffer[len] = level_value;
            len = len + 1;
        }
        if (isSafe(buffer[0..len])) {
            total_safe = total_safe + 1;
        }
    }
    try stdout.print("{d}", .{total_safe});
    try bw.flush(); // Don't forget to flush!
}

test "simple test" {
    var report = [_]u32{1, 2, 3, 4, 5};
    try std.testing.expectEqual(true, isSafe(&report));
    var report2 = [_]u32{1, 2, 3, 4, 7, 6};
    try std.testing.expectEqual(false, isSafe(&report2));
    var report3 = [_]u32{1, 2, 3, 4, 5, 8};
    try std.testing.expectEqual(true, isSafe(&report3));
    var report4 = [_]u32{1, 2, 3, 4, 5, 9};
    try std.testing.expectEqual(false, isSafe(&report4));
}
