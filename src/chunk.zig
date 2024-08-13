const std = @import("std");
const zm = @import("zmath");
const znoise = @import("znoise");

const mesh = @import("mesh.zig");
const QuadFace = @import("quad.zig").QuadFace;
const Shader = @import("shader.zig").Program;
const utils = @import("utils.zig");

pub const Voxel = enum { air, grass };

pub const CHUNK_SIZE = utils.IVec3{ .x = 16, .y = 16, .z = 16 };
const TOTAL_CHUNK_VOLUME = CHUNK_SIZE.x * CHUNK_SIZE.y * CHUNK_SIZE.z;

pub const Chunk = struct {
    world_position: utils.IVec3,
    voxels: [TOTAL_CHUNK_VOLUME]Voxel,

    pub fn init(world_position: utils.IVec3) Chunk {
        var chunk = Chunk{ .world_position = world_position, .voxels = [_]Voxel{Voxel.air} ** TOTAL_CHUNK_VOLUME };

        for (0..CHUNK_SIZE.x) |x| {
            for (0..CHUNK_SIZE.z) |z| {
                const gen = znoise.FnlGenerator{};
                const height = gen.noise3(@floatFromInt(x), 0.0, @floatFromInt(z));
                const scaled_height: usize = @intFromFloat(utils.remap(height, -1.0, 1.0, 0.0, CHUNK_SIZE.y));
                for (0..CHUNK_SIZE.y) |y| {
                    const voxel = v: {
                        if (y < scaled_height) {
                            break :v Voxel.grass;
                        }

                        break :v Voxel.air;
                    };
                    chunk.set_voxel(.{ .x = @intCast(x), .y = @intCast(y), .z = @intCast(z) }, voxel);
                }
            }
        }

        return chunk;
    }

    pub fn get_voxel(self: *Chunk, local_position: utils.IVec3) ?Voxel {
        if (local_position.x < 0 or local_position.x >= CHUNK_SIZE.x or local_position.y < 0 or local_position.y >= CHUNK_SIZE.y or local_position.z < 0 or local_position.z >= CHUNK_SIZE.z) {
            return null;
        }

        return self.voxels[utils.coords_to_index(local_position, CHUNK_SIZE)];
    }

    pub fn set_voxel(self: *Chunk, local_position: utils.IVec3, voxel: Voxel) void {
        self.voxels[
            utils.coords_to_index(local_position, CHUNK_SIZE)
        ] = voxel;
    }

    pub fn init_mesh(self: *Chunk, shader: *Shader, allocator: std.mem.Allocator) !mesh.Mesh {
        var vertices = std.ArrayList(mesh.Vertex).init(allocator);
        defer vertices.deinit();

        var indices = std.ArrayList(u32).init(allocator);
        defer indices.deinit();

        for (self.voxels, 0..) |voxel, i| {
            if (voxel == Voxel.air) {
                continue;
            }

            const coords = utils.index_to_coords(i, CHUNK_SIZE);
            const x = coords.x;
            const y = coords.y;
            const z = coords.z;

            if (self.get_voxel(.{ .x = x, .y = y + 1, .z = z }) == Voxel.air) {
                const face = QuadFace.top.asMeshInfo(coords, @intCast(vertices.items.len));
                try vertices.appendSlice(&face.vertices);
                try indices.appendSlice(&face.indices);
            }

            if (self.get_voxel(.{ .x = x, .y = y - 1, .z = z }) == Voxel.air) {
                const face = QuadFace.bottom.asMeshInfo(coords, @intCast(vertices.items.len));
                try vertices.appendSlice(&face.vertices);
                try indices.appendSlice(&face.indices);
            }

            if (self.get_voxel(.{ .x = x + 1, .y = y, .z = z }) == Voxel.air) {
                const face = QuadFace.right.asMeshInfo(coords, @intCast(vertices.items.len));
                try vertices.appendSlice(&face.vertices);
                try indices.appendSlice(&face.indices);
            }

            if (self.get_voxel(.{ .x = x - 1, .y = y, .z = z }) == Voxel.air) {
                const face = QuadFace.left.asMeshInfo(coords, @intCast(vertices.items.len));
                try vertices.appendSlice(&face.vertices);
                try indices.appendSlice(&face.indices);
            }

            if (self.get_voxel(.{ .x = x, .y = y, .z = z + 1 }) == Voxel.air) {
                const face = QuadFace.front.asMeshInfo(coords, @intCast(vertices.items.len));
                try vertices.appendSlice(&face.vertices);
                try indices.appendSlice(&face.indices);
            }

            if (self.get_voxel(.{ .x = x, .y = y, .z = z - 1 }) == Voxel.air) {
                const face = QuadFace.back.asMeshInfo(coords, @intCast(vertices.items.len));
                try vertices.appendSlice(&face.vertices);
                try indices.appendSlice(&face.indices);
            }
        }

        return mesh.Mesh.init(shader, vertices.items, indices.items);
    }
};
