//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");

const CollatingSequence = enum {
    INCREASING,
    DECREASING,
};

fn safelyIncreasing(former_level: i64, latter_level: i64) bool {
    if (latter_level <= former_level) { // not increasing
        return false;
    } else if (latter_level - former_level > 3) { // increasing by too much
        return false;
    }
    return true;
}

fn safelyDecreasing(former_level: i64, latter_level: i64) bool {
    if (former_level <= latter_level) { // not decreasing
        return false;
    } else if (former_level - latter_level > 3) { // decreasing by too much
        return false;
    }
    return true;
}

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
                if (!safelyIncreasing(current_level, previous_level)) {
                    return false;
                }
            },
            CollatingSequence.DECREASING => {
                if (!safelyDecreasing(current_level, previous_level)) {
                    return false;
                }
            }
        }
        previous_level = current_level;
        i = i + 1;
    }
    return true;
}

fn isSafeWithDampening(report: []u32) bool {
    var i: usize = 0;
    var unsafe_count: u2 = 0;
    const MAX_UNSAFE = 1;
    // var collating_sequence: CollatingSequence = if (report[0] > report[report.len - 1]) CollatingSequence.DECREASING else CollatingSequence.INCREASING ;
    const safe_delta: *const fn(i64, i64) bool = if (report[0] < report[report.len - 1]) safelyIncreasing else safelyDecreasing; 
    while (i < report.len - 2) {
        const first: i64 = @as(i64, report[i]);
        const second: i64 = @as(i64, report[i+1]);
        const third: i64 = @as(i64, report[i+2]);
        const can_skip_middle = safe_delta(first, third);
        if (safe_delta(first, second)) {
            // upcoming pair unsafe
            if (!safe_delta(second, third)) {
                // try to drop middle element in window by skipping
                if (can_skip_middle) {
                    if (unsafe_count < MAX_UNSAFE) {
                        unsafe_count += 1;
                        i += 1;
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }
            }
        } else {
            // See if we can drop first element in window
            if (safe_delta(second, third)) {
                if (unsafe_count < MAX_UNSAFE) {
                    unsafe_count += 1;
                } else {
                    return false;
                }                
            } else if (can_skip_middle) {
                if (unsafe_count < MAX_UNSAFE) {
                    unsafe_count += 1;
                    i += 1;
                } else {
                    return false;
                }                
            } else {
                return false;
            }
        }
        i += 1;
    }
    return true;
}

pub fn main() !void {
    var total_safe: u64 = 0;
    var total_safe_with_dampening: u64 = 0;

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
        if (len <= 0) {
            continue;
        }
        if (isSafe(buffer[0..len])) {
            total_safe = total_safe + 1;
        }
        if (isSafeWithDampening(buffer[0..len])) {
            total_safe_with_dampening = total_safe_with_dampening + 1;
        }
    }
    try stdout.print("Total safe: {d}\n", .{total_safe});
    try stdout.print("Total safe with dampening: {d}\n", .{total_safe_with_dampening});
    try bw.flush(); // Don't forget to flush!
}

test "part 1 test" {
    var report = [_]u32{1, 2, 3, 4, 5};
    try std.testing.expectEqual(true, isSafe(&report));
    var report2 = [_]u32{1, 2, 3, 4, 7, 6};
    try std.testing.expectEqual(false, isSafe(&report2));
    var report3 = [_]u32{1, 2, 3, 4, 5, 8};
    try std.testing.expectEqual(true, isSafe(&report3));
    var report4 = [_]u32{1, 2, 3, 4, 5, 9};
    try std.testing.expectEqual(false, isSafe(&report4));
}

test "part 2 test" {
    var report1 = [_]u32{7, 6, 4, 2, 1}; // Safe without removing any level.
    var report2 = [_]u32{1, 2, 7, 8, 9}; // Unsafe regardless of which level is removed.
    var report3 = [_]u32{9, 7, 6, 2, 1}; // Unsafe regardless of which level is removed.
    var report4 = [_]u32{1, 3, 2, 4, 5}; // Safe by removing the second level, 3.
    var report5 = [_]u32{8, 6, 4, 4, 1}; // Safe by removing the third level, 4.
    var report6 = [_]u32{1, 3, 6, 7, 9}; // Safe without removing any level.
    try std.testing.expectEqual(true, isSafeWithDampening(&report1));
    try std.testing.expectEqual(false, isSafeWithDampening(&report2));
    try std.testing.expectEqual(false, isSafeWithDampening(&report3));
    try std.testing.expectEqual(true, isSafeWithDampening(&report4));
    try std.testing.expectEqual(true, isSafeWithDampening(&report5));
    try std.testing.expectEqual(true, isSafeWithDampening(&report6));

}
