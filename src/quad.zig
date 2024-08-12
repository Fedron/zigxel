const Vertex = @import("mesh.zig").Vertex;

pub const QuadFace = enum {
    front,
    back,
    left,
    right,
    top,
    bottom,

    pub fn asMeshInfo(self: QuadFace, base_index: u8) struct { vertices: [4]Vertex, indices: [6]u8 } {
        const indices: [6]u8 = .{ base_index, base_index + 1, base_index + 3, base_index + 1, base_index + 2, base_index + 3 };
        switch (self) {
            .front => return .{ .vertices = .{
                .{ .position = .{ -0.5, 0.5, 0.5 }, .color = .{ 1.0, 0.0, 0.0 } },
                .{ .position = .{ 0.5, 0.5, 0.5 }, .color = .{ 1.0, 0.0, 0.0 } },
                .{ .position = .{ 0.5, -0.5, 0.5 }, .color = .{ 1.0, 0.0, 0.0 } },
                .{ .position = .{ -0.5, -0.5, 0.5 }, .color = .{ 1.0, 0.0, 0.0 } },
            }, .indices = indices },
            .back => return .{ .vertices = .{
                .{ .position = .{ 0.5, 0.5, -0.5 }, .color = .{ 0.0, 1.0, 0.0 } },
                .{ .position = .{ -0.5, 0.5, -0.5 }, .color = .{ 0.0, 1.0, 0.0 } },
                .{ .position = .{ -0.5, -0.5, -0.5 }, .color = .{ 0.0, 1.0, 0.0 } },
                .{ .position = .{ 0.5, -0.5, -0.5 }, .color = .{ 0.0, 1.0, 0.0 } },
            }, .indices = indices },
            .left => return .{ .vertices = .{
                .{ .position = .{ -0.5, 0.5, -0.5 }, .color = .{ 0.0, 0.0, 1.0 } },
                .{ .position = .{ -0.5, 0.5, 0.5 }, .color = .{ 0.0, 0.0, 1.0 } },
                .{ .position = .{ -0.5, -0.5, 0.5 }, .color = .{ 0.0, 0.0, 1.0 } },
                .{ .position = .{ -0.5, -0.5, -0.5 }, .color = .{ 0.0, 0.0, 1.0 } },
            }, .indices = indices },
            .right => return .{ .vertices = .{
                .{ .position = .{ 0.5, 0.5, 0.5 }, .color = .{ 1.0, 0.0, 1.0 } },
                .{ .position = .{ 0.5, 0.5, -0.5 }, .color = .{ 1.0, 0.0, 1.0 } },
                .{ .position = .{ 0.5, -0.5, -0.5 }, .color = .{ 1.0, 0.0, 1.0 } },
                .{ .position = .{ 0.5, -0.5, 0.5 }, .color = .{ 1.0, 0.0, 1.0 } },
            }, .indices = indices },
            .top => return .{ .vertices = .{
                .{ .position = .{ -0.5, 0.5, -0.5 }, .color = .{ 0.0, 1.0, 1.0 } },
                .{ .position = .{ 0.5, 0.5, -0.5 }, .color = .{ 0.0, 1.0, 1.0 } },
                .{ .position = .{ 0.5, 0.5, 0.5 }, .color = .{ 0.0, 1.0, 1.0 } },
                .{ .position = .{ -0.5, 0.5, 0.5 }, .color = .{ 0.0, 1.0, 1.0 } },
            }, .indices = indices },
            .bottom => return .{ .vertices = .{
                .{ .position = .{ -0.5, -0.5, 0.5 }, .color = .{ 1.0, 1.0, 0.0 } },
                .{ .position = .{ 0.5, -0.5, 0.5 }, .color = .{ 1.0, 1.0, 0.0 } },
                .{ .position = .{ 0.5, -0.5, -0.5 }, .color = .{ 1.0, 1.0, 0.0 } },
                .{ .position = .{ -0.5, -0.5, -0.5 }, .color = .{ 1.0, 1.0, 0.0 } },
            }, .indices = indices },
        }
    }
};
