const gl = @import("gl");
const Shader = @import("shader.zig").Program;

pub const Vertex = struct {
    position: [3]f32,
    color: [3]f32,
};

pub const Mesh = struct {
    vao: c_uint,
    vbo: c_uint,
    ebo: c_uint,
    num_indices: c_int,

    pub fn init(shader: *Shader, vertices: []const Vertex, indices: []const u32) !Mesh {
        var vao: c_uint = undefined;
        gl.GenVertexArrays(1, (&vao)[0..1]);

        var vbo: c_uint = undefined;
        gl.GenBuffers(1, (&vbo)[0..1]);

        var ebo: c_uint = undefined;
        gl.GenBuffers(1, (&ebo)[0..1]);

        gl.BindVertexArray(vao);
        defer gl.BindVertexArray(0);

        gl.BindBuffer(gl.ARRAY_BUFFER, vao);
        defer gl.BindBuffer(gl.ARRAY_BUFFER, 0);

        gl.BufferData(
            gl.ARRAY_BUFFER,
            @as(isize, @intCast(@sizeOf(Vertex) * vertices.len)),
            vertices.ptr,
            gl.STATIC_DRAW,
        );

        try shader.enable_vertex_attrib_pointers(Vertex);

        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
        gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, @as(isize, @intCast(@sizeOf(u32) * indices.len)), indices.ptr, gl.STATIC_DRAW);

        return Mesh{ .vao = vao, .vbo = vbo, .ebo = ebo, .num_indices = @intCast(indices.len) };
    }

    pub fn deinit(self: *Mesh) void {
        gl.DeleteBuffers(1, (&self.ebo)[0..1]);
        gl.DeleteBuffers(1, (&self.vbo)[0..1]);
        gl.DeleteVertexArrays(1, (&self.vao)[0..1]);
    }

    pub fn draw(self: *Mesh) void {
        gl.BindVertexArray(self.vao);
        defer gl.BindVertexArray(0);

        gl.DrawElements(gl.TRIANGLES, self.num_indices, gl.UNSIGNED_INT, 0);
    }
};
