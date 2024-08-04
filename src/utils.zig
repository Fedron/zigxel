const std = @import("std");

pub const DEG_TO_RAD = std.math.pi / 180.0;

pub fn clamp(comptime T: type, value: T, min: T, max: T) T {
    if (value > max) return max;
    if (value < min) return min;
    return value;
}
