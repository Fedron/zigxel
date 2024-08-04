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
