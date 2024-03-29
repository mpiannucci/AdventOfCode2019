const std = @import("std");

const MAX_INT = 9223372036854775807;

const PathInstruction = struct {
    command: u8,
    distance: u32,

    pub fn fromString(raw: []const u8) PathInstruction {
        return PathInstruction{
            .command = raw[0],
            .distance = std.fmt.parseInt(u32, raw[1..], 10) catch unreachable,
        };
    }
};

pub fn Point(comptime T: type) type {
    return struct {
        const Self = @This();

        x: T,
        y: T,

        pub fn init(x: T, y: T) Self {
            return Self{
                .x = x,
                .y = y,
            };
        }

        pub fn manhattanDistance(self: Self, other: Self) i64 {
            const x_distance = std.math.absInt(@intCast(i64, self.x) - @intCast(i64, other.x)) catch unreachable;
            const y_distance = std.math.absInt(@intCast(i64, self.y) - @intCast(i64, other.y)) catch unreachable;
            return x_distance + y_distance;
        }
    };
}

const Extents = struct {
    min: Point(i64),
    max: Point(i64),

    pub fn init() Extents {
        return Extents{
            .min = Point(i64){
                .x = MAX_INT,
                .y = MAX_INT,
            },
            .max = Point(i64){
                .x = -MAX_INT,
                .y = -MAX_INT,
            },
        };
    }

    pub fn width(self: Extents) i64 {
        return self.max.x - self.min.x;
    }

    pub fn height(self: Extents) i64 {
        return self.max.y - self.min.y;
    }

    pub fn grow(self: *Extents, p: Point(i64)) void {
        if (p.x < self.min.x) {
            self.min.x = p.x;
        }
        if (p.y < self.min.y) {
            self.min.y = p.y;
        }
        if (p.x > self.max.x) {
            self.max.x = p.x;
        }
        if (p.y > self.max.y) {
            self.max.y = p.y;
        }
    }

    pub fn growFromPath(self: *Extents, path: std.ArrayList(PathInstruction)) void {
        // Start at the origin
        var location = Point(i64).init(0, 0);
        self.grow(location);

        for (path.toSliceConst()) |instruction| {
            const distance: i64 = @intCast(i64, instruction.distance);

            switch (instruction.command) {
                'L' => location.x -= distance,
                'R' => location.x += distance,
                'U' => location.y -= distance,
                'D' => location.y += distance,
                else => unreachable,
            }

            self.grow(location);
        }
    }
};

pub fn mapPath(map: []u8, map_origin: Point(usize), map_width: usize, map_height: usize, instructions: std.ArrayList(PathInstruction), fill: u8) void {
    var location = map_origin;
    const map_size = map_width * map_height;

    for (instructions.toSliceConst()) |instruction, iter| {
        const distance = instruction.distance;

        var i: usize = 0;
        while (i < distance) : (i += 1) {
            switch (instruction.command) {
                'L' => location.x -= 1,
                'R' => location.x += 1,
                'U' => location.y -= 1,
                'D' => location.y += 1,
                else => unreachable,
            }
            const coord = location.y * map_width + location.x;

            if (coord > map_size) {
                std.debug.warn("OOB at Iteration: {} + {}\n", iter, i);
                std.debug.warn("Location: {}\n", location);
                std.debug.warn("Instruction: {}\n", instruction);
                return;
            } else {
                if (map[coord] == 0) {
                    map[coord] = fill;
                } else if (map[coord] == fill) {
                    continue;
                } else {
                    map[coord] = 'x';
                }
            }
        }
    }
}

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.direct_allocator);
    defer arena.deinit();

    var allocator = &arena.allocator;

    // We can pars ethe instructions using our custom PathInstruction struct
    const input_path_data = try std.io.readFileAlloc(allocator, "input.txt");
    var raw_wire_path_data_it = std.mem.separate(input_path_data, "\n");
    var first_wire_path = std.ArrayList(PathInstruction).init(allocator);
    var second_wire_path = std.ArrayList(PathInstruction).init(allocator);
    var wire_index: usize = 0;
    while (raw_wire_path_data_it.next()) |raw_wire_path| : (wire_index += 1) {
        var wire_path_instruction_it = std.mem.separate(raw_wire_path, ",");
        while (wire_path_instruction_it.next()) |wire_path_instruction| {
            const instruction = PathInstruction.fromString(std.fmt.trim(wire_path_instruction));
            if (wire_index == 0) {
                try first_wire_path.append(instruction);
            } else {
                try second_wire_path.append(instruction);
            }
        }
    }

    // Before we can create a map of the problem space we have to
    // find the size of the problem space so we can allocate it.
    var map_extents = Extents.init();
    map_extents.growFromPath(first_wire_path);
    map_extents.growFromPath(second_wire_path);

    // Now that we know the size of the grid we can allocate it
    const map_width = @intCast(usize, map_extents.width());
    const map_height = @intCast(usize, map_extents.height());
    var map = try allocator.alloc(u8, map_width * map_height + 100);
    const map_origin = Point(usize).init(@intCast(usize, try std.math.absInt(map_extents.min.x)), @intCast(usize, try std.math.absInt(map_extents.min.y)));

    std.debug.warn("Extents: {}\n", map_extents);
    std.debug.warn("Width: {}\n", map_width);
    std.debug.warn("Height: {}\n", map_height);
    std.debug.warn("Origin: {}\n", map_origin);

    std.debug.warn("--------------------------------------------------\n");

    // Fill with zeros
    var row: usize = 0;
    while (row < map_height) : (row += 1) {
        var col: usize = 0;
        while (col < map_width) : (col += 1) {
            map[row * map_width + col] = 0;
        }
    }

    // Map the wires!!!
    mapPath(map, map_origin, map_width, map_height, first_wire_path, 1);
    mapPath(map, map_origin, map_width, map_height, second_wire_path, 2);

    // Find the overlaps!!
    var intersections = std.ArrayList(Point(usize)).init(allocator);
    row = 0;
    while (row < map_height) : (row += 1) {
        var col: usize = 0;
        while (col < map_width) : (col += 1) {
            if (map[row * map_width + col] == 'x') {
                try intersections.append(Point(usize).init(col, row));
            }
        }
    }

    // We can now search for the closest intersection
    var min_distance: i64 = MAX_INT;
    var min_index: usize = 0;
    for (intersections.toSliceConst()) |intersection, index| {
        const distance = intersection.manhattanDistance(map_origin);
        if (distance < min_distance) {
            min_distance = distance;
            min_index = index;
        }
    }

    // Print it out
    std.debug.warn("Closest intersection distance is {}", min_distance);
}
