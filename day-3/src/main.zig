//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");

const State = enum {
    DEFAULT,
    BEGIN_MUL,
    MUL,
    END_MUL,
    PARAM1,
    PARAM2,
    CALL_MUL,
    RESET
};

pub fn upd() void {

}


pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{.thread_safe=true}){};
    const allocator = gpa.allocator();
    // defer gpa.deinit() == .leak {
    //     std.log.err("Memory leak", .{})
    // };
    defer _ = gpa.deinit();

    const file = std.fs.cwd().openFile("./input.txt", .{}) catch |err| {
        std.log.err("Failed to open file: {s}", .{@errorName(err)});
        return;
    };
    defer file.close();

    var state = State.DEFAULT;

    if (file.reader().readUntilDelimiterOrEofAlloc(allocator, undefined, std.math.maxInt(usize)) catch |err| {
        std.log.err("Failed to read line: {s}", .{@errorName(err)});
        return;
    }) |text| {
        defer allocator.free(text);
        var i: u64 = 0;
        var p1: [3]u4 = .{0, 0, 0};
        var p1_val: u64 = 0;
        var p2: [3]u4 = .{0, 0, 0};
        var p2_val: u64 = 0;
        var j: usize = 0;
        var total: u64 = 0;
        while (i < text.len) {
            // states: 
            // expecting mul
            // expecting (
            // expecting [0-9]{1,3}[,]
            const ch = text[i];
            switch (state) {
                State.DEFAULT => {
                    if (ch == 'm') {
                       state = State.BEGIN_MUL;
                    } else {
                        state = State.DEFAULT;
                    }
                },
                State.BEGIN_MUL => {
                    if (ch == 'u') {
                        state = State.MUL;
                    } else {
                        state = State.RESET;
                    }
                },
                State.MUL => {
                    if (ch == 'l') {
                        state = State.END_MUL;
                    } else {
                        state = State.RESET;
                    }
                },
                State.END_MUL => {
                    if (ch == '(') {
                        state = State.PARAM1;
                        j = 0;
                    } else {
                        state = State.RESET;
                    }
                },
                State.PARAM1 => {
                    if (j < 3 and (ch >= 48 and ch <= 57)) {
                        p1[j] = @as(u4, @intCast(ch - 48));
                        j += 1;
                    } else if (ch == ',' and j > 0 and j <= 3) {
                        var k: usize = 0;
                        while (k < j) {
                            p1_val += @as(u64, @intCast(p1[k])) * std.math.pow(u64, 10, j-k-1);
                            k += 1;
                        }
                        j = 0;
                        state = State.PARAM2;
                    } else {
                        state = State.RESET;
                    }
                },
                State.PARAM2 => {
                    if (j < 3 and (ch >= 48 and ch <= 57)) {
                        p2[j] = @as(u4, @intCast(ch - 48));
                        j += 1;
                    } else if (ch == ')' and j > 0 and j <= 3) {
                        var k: usize = 0;
                        while (k < j) {
                            p2_val +=  @as(u64, @intCast(p2[k])) * std.math.pow(u64, 10, j-k-1);
                            k += 1;
                        }
                        j = 0;
                        state = State.CALL_MUL;
                    } else {
                        state = State.RESET;
                    }
                },
                State.CALL_MUL => {
                    total += p1_val * p2_val;
                    try stdout.print("{d} * {d} = {d}.\n", .{p1_val, p2_val, p1_val * p2_val});
                    i -= 1;
                    state = State.RESET;
                },
                State.RESET => {
                    p1 = .{0, 0, 0};
                    p1_val = 0;
                    p2 = .{0, 0, 0};
                    p2_val = 0;
                    j = 0;
                    i -= 1;
                    state = State.DEFAULT;
                }
            }
            i += 1;
        }
        try stdout.print("TOTAL: {d}.\n", .{total});
    }
    try bw.flush(); // Don't forget to flush!
}