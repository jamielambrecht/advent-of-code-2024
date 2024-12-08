//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");

const MAX_NUMBER = 100_000;

fn readNumbersIntoLists(list_1: *[1000]u64, list_2: *[1000]u64) !void {
    // Input file
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    // Input buffer
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var i: u16 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) | line| {
        var iter = std.mem.tokenizeAny(u8, line, " ");
        list_1[i] = try std.fmt.parseInt(u64, iter.next().?, 10);
        list_2[i] = try std.fmt.parseInt(u64, iter.next().?, 10);
        std.debug.print("{d}   {d}\n", .{list_1[i], list_2[i]});
        i = i + 1;
    }
}

fn sortLists(list_1: *[1000]u64, list_2: *[1000]u64) u64 {
    // Sorted number lists
    var sorted_lists: [2][1000]u64 = undefined;
    @memset(&sorted_lists[0], MAX_NUMBER);
    @memset(&sorted_lists[1], MAX_NUMBER);
    var sorted_list_1 = &sorted_lists[0];
    var sorted_list_2 = &sorted_lists[1];
    
    var i: u32 = 0;
    var total_difference: u64 = 0;

    while (i < 1000) {
        var j: u16 = 0;
        var list_1_lowest_j: u64 = undefined;
        var list_2_lowest_j: u64 = undefined;
        while (j < 1000) {
            if (list_1[j] < sorted_list_1[i]) {
                sorted_list_1[i] = list_1[j];
                list_1_lowest_j = j;
            }
            if (list_2[j] < sorted_list_2[i]) {
                sorted_list_2[i] = list_2[j];
                list_2_lowest_j = j;
            }
            j = j + 1;
        }
        list_1[list_1_lowest_j] = MAX_NUMBER;
        list_2[list_2_lowest_j] = MAX_NUMBER;
        total_difference += if (sorted_list_1[i] > sorted_list_2[i]) sorted_list_1[i] - sorted_list_2[i] else sorted_list_2[i] - sorted_list_1[i];
        std.debug.print("{d}   {d}   {d}\n", .{sorted_list_1[i], sorted_list_2[i], total_difference});
        i = i + 1;
    }
    @memcpy(list_1, sorted_list_1);
    @memcpy(list_2, sorted_list_2);
    return total_difference;
}

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("Getting input...\n", .{});
    // Number lists
    var lists: [2][1000]u64 = undefined;
    @memset(&lists[0], 0);
    @memset(&lists[1], 0);
    const list_1 = &lists[0];
    const list_2 = &lists[1];
    // Distances list
    var distances: [1000]u64 = undefined;
    @memset(&distances, 0);
    // Read numbers from input into lists
    try readNumbersIntoLists(list_1, list_2);
    std.debug.print("Finished getting input.\n", .{});
    // Find lowest numbers
    std.debug.print("Sorting lists...\n", .{});
    const total_distance = sortLists(list_1, list_2);
    std.debug.print("Finished sorting lists...\n", .{});
    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    bw.flush();
    try stdout.print("{d}", .{total_distance});
}

