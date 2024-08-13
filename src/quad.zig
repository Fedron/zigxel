const IVec3 = @import("utils.zig").IVec3;
const Vertex = @import("mesh.zig").Vertex;

pub const QuadFace = enum {
    front,
    back,
    left,
    right,
    top,
    bottom,

    pub fn asMeshInfo(self: QuadFace, base_position: IVec3, base_index: u32) struct { vertices: [4]Vertex, indices: [6]u32 } {
        const indices: [6]u32 = .{ base_index, base_index + 1, base_index + 3, base_index + 1, base_index + 2, base_index + 3 };

        const x = @as(f32, @floatFromInt(base_position.x));
        const y = @as(f32, @floatFromInt(base_position.y));
        const z = @as(f32, @floatFromInt(base_position.z));
        switch (self) {
            .front => return .{ .vertices = .{
                .{ .position = .{ x - 0.5, y + 0.5, z + 0.5 }, .color = .{ 1.0, 0.0, 0.0 } },
                .{ .position = .{ x + 0.5, y + 0.5, z + 0.5 }, .color = .{ 1.0, 0.0, 0.0 } },
                .{ .position = .{ x + 0.5, y - 0.5, z + 0.5 }, .color = .{ 1.0, 0.0, 0.0 } },
                .{ .position = .{ x - 0.5, y - 0.5, z + 0.5 }, .color = .{ 1.0, 0.0, 0.0 } },
            }, .indices = indices },
            .back => return .{ .vertices = .{
                .{ .position = .{ x + 0.5, y + 0.5, z - 0.5 }, .color = .{ 0.0, 1.0, 0.0 } },
                .{ .position = .{ x - 0.5, y + 0.5, z - 0.5 }, .color = .{ 0.0, 1.0, 0.0 } },
                .{ .position = .{ x - 0.5, y - 0.5, z - 0.5 }, .color = .{ 0.0, 1.0, 0.0 } },
                .{ .position = .{ x + 0.5, y - 0.5, z - 0.5 }, .color = .{ 0.0, 1.0, 0.0 } },
            }, .indices = indices },
            .left => return .{ .vertices = .{
                .{ .position = .{ x - 0.5, y + 0.5, z - 0.5 }, .color = .{ 0.0, 0.0, 1.0 } },
                .{ .position = .{ x - 0.5, y + 0.5, z + 0.5 }, .color = .{ 0.0, 0.0, 1.0 } },
                .{ .position = .{ x - 0.5, y - 0.5, z + 0.5 }, .color = .{ 0.0, 0.0, 1.0 } },
                .{ .position = .{ x - 0.5, y - 0.5, z - 0.5 }, .color = .{ 0.0, 0.0, 1.0 } },
            }, .indices = indices },
            .right => return .{ .vertices = .{
                .{ .position = .{ x + 0.5, y + 0.5, z + 0.5 }, .color = .{ 1.0, 0.0, 1.0 } },
                .{ .position = .{ x + 0.5, y + 0.5, z - 0.5 }, .color = .{ 1.0, 0.0, 1.0 } },
                .{ .position = .{ x + 0.5, y - 0.5, z - 0.5 }, .color = .{ 1.0, 0.0, 1.0 } },
                .{ .position = .{ x + 0.5, y - 0.5, z + 0.5 }, .color = .{ 1.0, 0.0, 1.0 } },
            }, .indices = indices },
            .top => return .{ .vertices = .{
                .{ .position = .{ x - 0.5, y + 0.5, z - 0.5 }, .color = .{ 0.0, 1.0, 1.0 } },
                .{ .position = .{ x + 0.5, y + 0.5, z - 0.5 }, .color = .{ 0.0, 1.0, 1.0 } },
                .{ .position = .{ x + 0.5, y + 0.5, z + 0.5 }, .color = .{ 0.0, 1.0, 1.0 } },
                .{ .position = .{ x - 0.5, y + 0.5, z + 0.5 }, .color = .{ 0.0, 1.0, 1.0 } },
            }, .indices = indices },
            .bottom => return .{ .vertices = .{
                .{ .position = .{ x - 0.5, y - 0.5, z + 0.5 }, .color = .{ 1.0, 1.0, 0.0 } },
                .{ .position = .{ x + 0.5, y - 0.5, z + 0.5 }, .color = .{ 1.0, 1.0, 0.0 } },
                .{ .position = .{ x + 0.5, y - 0.5, z - 0.5 }, .color = .{ 1.0, 1.0, 0.0 } },
                .{ .position = .{ x - 0.5, y - 0.5, z - 0.5 }, .color = .{ 1.0, 1.0, 0.0 } },
            }, .indices = indices },
        }
    }
};
