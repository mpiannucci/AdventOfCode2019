const std = @import("std");

pub fn main() anyerror!void {
    const rawFuelData = try std.io.readFileAlloc(std.debug.global_allocator, "input.txt");
    var lines = std.mem.separate(rawFuelData, "\n");

    var totalFuel: i64 = 0;
    while (lines.next()) |line| {
        var module = std.fmt.parseInt(i64, std.fmt.trim(line), 10) catch 0;

        while (module > 0) {
            module = requiredFuel(module);
            if (module < 0) {
                break;
            }

            totalFuel += module;
        }
    }

    std.debug.warn("Total Fuel Required: {}\r\n", totalFuel);
}

pub fn requiredFuel(sink: i64) i64 {
    return @divFloor(sink, 3) - 2;
}
