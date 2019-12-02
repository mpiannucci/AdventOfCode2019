const std = @import("std");

pub fn main() anyerror!void { 
    const rawFuelData = try std.io.readFileAlloc(std.debug.global_allocator, "input.txt");
    var lines = std.mem.separate(rawFuelData, "\n");
    
    var totalFuel: i64 = 0;
    while (lines.next()) |line| {
        const rawModuleFuel = std.fmt.parseInt(i64, std.fmt.trim(line), 10) catch 0;
        totalFuel += @divFloor(rawModuleFuel, 3) - 2;
    }

    std.debug.warn("Total Fuel Required: {}\r\n", totalFuel);
}