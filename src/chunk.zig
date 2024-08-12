const std = @import("std");
const zm = @import("zmath");

const mesh = @import("mesh.zig");
const QuadFace = @import("quad.zig").QuadFace;
const Shader = @import("shader.zig").Program;
const utils = @import("utils.zig");

pub const Voxel = enum { air, grass };

pub const CHUNK_SIZE = zm.f32x4s(16);
const TOTAL_CHUNK_VOLUME = CHUNK_SIZE[0] * CHUNK_SIZE[1] * CHUNK_SIZE[2];

pub const Chunk = struct {
    world_x: i32,
    world_y: i32,
    voxels: [TOTAL_CHUNK_VOLUME]Voxel,

    pub fn init(x: i32, y: i32) Chunk {
        return Chunk{ .world_x = x, .world_y = y, .voxels = [_]Voxel{Voxel.air} ** TOTAL_CHUNK_VOLUME };
    }

    pub fn get_voxel(self: *Chunk, local_x: i32, local_y: i32, local_z: i32) ?Voxel {
        if (local_x < 0 or local_x >= CHUNK_SIZE[0] or local_y < 0 or local_y >= CHUNK_SIZE[1] or local_z < 0 or local_z >= CHUNK_SIZE[1]) {
            return null;
        }

        return self.voxels[utils.coords_to_index(zm.f32x4(@floatFromInt(local_x), @floatFromInt(local_y), @floatFromInt(local_z), 0.0), CHUNK_SIZE)];
    }

    pub fn set_voxel(self: *Chunk, local_x: i32, local_y: i32, local_z: i32, voxel: Voxel) void {
        self.voxels[
            utils.coords_to_index(zm.f32x4(@floatFromInt(local_x), @floatFromInt(local_y), @floatFromInt(local_z), 0.0), CHUNK_SIZE)
        ] = voxel;
    }

    pub fn init_mesh(self: *Chunk, shader: *Shader, allocator: std.mem.Allocator) !mesh.Mesh {
        var vertices = std.ArrayList(mesh.Vertex).init(allocator);
        defer vertices.deinit();

        var indices = std.ArrayList(u8).init(allocator);
        defer indices.deinit();

        for (self.voxels, 0..) |voxel, i| {
            if (voxel == Voxel.air) {
                continue;
            }

            const coords = utils.index_to_coords(i, CHUNK_SIZE);
            const x: i32 = @intFromFloat(coords[0]);
            const y: i32 = @intFromFloat(coords[1]);
            const z: i32 = @intFromFloat(coords[2]);

            // TODO: consider if voxel is null?
            if (self.get_voxel(x, y + 1, z) == Voxel.air) {
                const face = QuadFace.top.asMeshInfo(@intCast(vertices.items.len));
                try vertices.appendSlice(&face.vertices);
                try indices.appendSlice(&face.indices);
            }

            if (self.get_voxel(x, y - 1, z) == Voxel.air) {
                const face = QuadFace.bottom.asMeshInfo(@intCast(vertices.items.len));
                try vertices.appendSlice(&face.vertices);
                try indices.appendSlice(&face.indices);
            }

            if (self.get_voxel(x + 1, y, z) == Voxel.air) {
                const face = QuadFace.right.asMeshInfo(@intCast(vertices.items.len));
                try vertices.appendSlice(&face.vertices);
                try indices.appendSlice(&face.indices);
            }

            if (self.get_voxel(x - 1, y, z) == Voxel.air) {
                const face = QuadFace.left.asMeshInfo(@intCast(vertices.items.len));
                try vertices.appendSlice(&face.vertices);
                try indices.appendSlice(&face.indices);
            }

            if (self.get_voxel(x, y, z + 1) == Voxel.air) {
                const face = QuadFace.front.asMeshInfo(@intCast(vertices.items.len));
                try vertices.appendSlice(&face.vertices);
                try indices.appendSlice(&face.indices);
            }

            if (self.get_voxel(x, y, z - 1) == Voxel.air) {
                const face = QuadFace.back.asMeshInfo(@intCast(vertices.items.len));
                try vertices.appendSlice(&face.vertices);
                try indices.appendSlice(&face.indices);
            }
        }

        return mesh.Mesh.init(shader, vertices.items, indices.items);
    }
};
