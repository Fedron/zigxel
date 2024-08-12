const std = @import("std");
const zm = @import("zmath");

pub const DEG_TO_RAD = std.math.pi / 180.0;

pub const WORLD_ORIGIN = zm.loadArr3(.{ 0.0, 0.0, 0.0 });
pub const WORLD_UP = zm.loadArr3(.{ 0.0, 1.0, 0.0 });
pub const WORLD_RIGHT = zm.loadArr3(.{ 1.0, 0.0, 0.0 });
pub const WORLD_FRONT = zm.loadArr3(.{ 0.0, 0.0, -1.0 });

pub fn clamp(comptime T: type, value: T, min: T, max: T) T {
    if (value > max) return max;
    if (value < min) return min;
    return value;
}

pub fn coords_to_index(coords: zm.F32x4, size: zm.F32x4) usize {
    return @intFromFloat(coords[0] + coords[1] * size[0] + coords[2] * size[0] * size[1]);
}

pub fn index_to_coords(index: usize, size: zm.F32x4) zm.F32x4 {
    var coords = zm.f32x4s(0);
    coords[0] = @mod(@as(f32, @floatFromInt(index)), size[0]);
    coords[1] = @mod((@as(f32, @floatFromInt(index)) / size[0]), size[1]);
    coords[2] = @as(f32, @floatFromInt(index)) / (size[1] * size[1]);
    return coords;
}
