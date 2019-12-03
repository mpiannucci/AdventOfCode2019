const std = @import("std");

pub fn main() anyerror!void {
    const allocator = &std.heap.ArenaAllocator.init(std.heap.direct_allocator).allocator;

    const raw_int_code_data = try std.io.readFileAlloc(allocator, "input.txt");
    var parsed_int_code_data_it = std.mem.separate(raw_int_code_data, ",");
    var int_count: usize = 0;
    while (parsed_int_code_data_it.next()) |parsed_int_code| {
        int_count += 1;
    }

    var original_int_code_data = try allocator.alloc(usize, int_count);
    defer allocator.free(original_int_code_data);

    parsed_int_code_data_it = std.mem.separate(raw_int_code_data, ",");
    var iter: usize = 0;
    while (parsed_int_code_data_it.next()) |raw_int_code| : (iter += 1) {
        original_int_code_data[iter] = try std.fmt.parseInt(usize, std.fmt.trim(raw_int_code), 10);
    }

    var first: usize = 0;
    var second: usize = 0;
    while (first <= 99) : (first += 1) outer: {
        second = 0;
        while (second <= 99) : (second += 1) {
            var int_code_data = try allocator.alloc(usize, int_count);
            defer allocator.free(int_code_data);
            std.mem.copy(usize, int_code_data, original_int_code_data);

            int_code_data[1] = first;
            int_code_data[2] = second;

            const result = runIntCodeComputer(int_code_data);
            if (result == 19690720) {
                break;
            }
        }

        if (second < 100) {
            break;
        }
    }

    std.debug.warn("Values to find 19690720: {}\n", 100 * first + second);
}

pub fn runIntCodeComputer(computer: []usize) usize {
    var i: usize = 0;
    while (i < computer.len) : (i += 4) {
        const opCode = computer[i];
        switch (opCode) {
            1 => computer[computer[i + 3]] = computer[computer[i + 1]] + computer[computer[i + 2]],
            2 => computer[computer[i + 3]] = computer[computer[i + 1]] * computer[computer[i + 2]],
            99 => break,
            else => unreachable,
        }
    }

    return computer[0];
}
