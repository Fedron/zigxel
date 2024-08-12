const std = @import("std");
const zm = @import("zmath");

pub const DEG_TO_RAD = std.math.pi / 180.0;

pub const WORLD_ORIGIN = zm.loadArr3(.{ 0.0, 0.0, 0.0 });
pub const WORLD_UP = zm.loadArr3(.{ 0.0, 1.0, 0.0 });
pub const WORLD_RIGHT = zm.loadArr3(.{ 1.0, 0.0, 0.0 });
pub const WORLD_FRONT = zm.loadArr3(.{ 0.0, 0.0, -1.0 });

pub const IVec3 = struct { x: i32, y: i32, z: i32 };

pub fn clamp(comptime T: type, value: T, min: T, max: T) T {
    if (value > max) return max;
    if (value < min) return min;
    return value;
}

pub fn coords_to_index(coords: IVec3, size: IVec3) usize {
    return @intCast(coords.x + coords.y * size.x + coords.z * size.x * size.y);
}

pub fn index_to_coords(index: usize, size: IVec3) IVec3 {
    var coords = IVec3{ .x = 0, .y = 0, .z = 0 };
    coords.x = @mod(@as(i32, @intCast(index)), size.x);
    coords.y = @mod(@divFloor(@as(i32, @intCast(index)), size.x), size.y);
    coords.z = @divFloor(@as(i32, @intCast(index)), (size.x * size.y));
    return coords;
}
