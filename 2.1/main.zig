const std = @import("std");

pub fn main() anyerror!void {
    const rawIntCodeData = try std.io.readFileAlloc(std.debug.global_allocator, "input.txt");
    var parsedRawIntCodeData = std.mem.separate(rawIntCodeData, ",");

    var intCodeData = std.ArrayList(i64).init(std.debug.global_allocator);
    while (parsedRawIntCodeData.next()) |rawIntCode| {
        const code = std.fmt.parseInt(i64, std.fmt.trim(rawIntCode), 10) catch 0;
        intCodeData.append(code) catch unreachable;
    }

    // Replace position 1 with 12 and position 2 with the value 2
    intCodeData.set(1, 12);
    intCodeData.set(2, 2);

    var i: usize = 0;
    while (i < intCodeData.count()) : (i += 4) {
        if (intCodeData.at(i) == 99) {
            break;
        }

        const opCode = intCodeData.at(i);
        const firstIndex = @intCast(usize, intCodeData.at(i + 1));
        const secondIndex = @intCast(usize, intCodeData.at(i + 2));
        const resultIndex = @intCast(usize, intCodeData.at(i + 3));

        const firstValue = intCodeData.at(firstIndex);
        const secondValue = intCodeData.at(secondIndex);

        const resultValue = switch (opCode) {
            1 => firstValue + secondValue,
            2 => firstValue * secondValue,
            else => unreachable,
        };
        intCodeData.set(resultIndex, resultValue);
    }

    std.debug.warn("Value at position 0: {}", intCodeData.at(0));
}
