const std = @import("std");
const gl = @import("gl");
const zm = @import("zmath");

const gl_log = std.log.scoped(.gl);

pub const Program = struct {
    id: c_uint,
    uniforms: std.StringHashMap(c_int),

    pub fn create(allocator: std.mem.Allocator, vs_path: []const u8, fs_path: []const u8) !Program {
        const vertex_shader = try create_shader(allocator, gl.VERTEX_SHADER, vs_path);
        defer gl.DeleteShader(vertex_shader);

        const fragment_shader = try create_shader(allocator, gl.FRAGMENT_SHADER, fs_path);
        defer gl.DeleteShader(fragment_shader);

        const program = gl.CreateProgram();
        if (program == 0) return error.CreateProgramFailed;
        errdefer gl.DeleteProgram(program);

        gl.AttachShader(program, vertex_shader);
        gl.AttachShader(program, fragment_shader);
        gl.LinkProgram(program);

        var success: c_int = undefined;
        var info_log_buf: [512:0]u8 = undefined;
        gl.GetProgramiv(program, gl.LINK_STATUS, &success);
        if (success == gl.FALSE) {
            gl.GetProgramInfoLog(program, info_log_buf.len, null, &info_log_buf);
            gl_log.err("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
            return error.LinkProgramFailed;
        }

        const uniforms = std.StringHashMap(c_int).init(allocator);
        return Program{ .id = program, .uniforms = uniforms };
    }

    pub fn destroy(self: *Program) void {
        gl.DeleteProgram(self.id);
        self.uniforms.deinit();
    }

    pub fn enable_vertex_attrib_pointers(self: *Program, comptime T: type) !void {
        const type_info = @typeInfo(T);

        if (type_info != .Struct) {
            return error.UnexpectedType;
        }

        inline for (type_info.Struct.fields) |field| {
            const field_type = @typeInfo(field.type);
            if (field_type != .Array) {
                return error.UnexpectedFieldType;
            }

            const gl_equiv = switch (field_type.Array.child) {
                i32 => gl.INT,
                u32 => gl.UNSIGNED_INT,
                f64 => gl.DOUBLE,
                else => gl.FLOAT,
            };

            const attrib: c_uint = @intCast(gl.GetAttribLocation(self.id, field.name));
            gl.EnableVertexAttribArray(attrib);
            gl.VertexAttribPointer(attrib, field_type.Array.len, gl_equiv, gl.FALSE, @sizeOf(T), @offsetOf(T, field.name));
        }
    }

    fn create_shader(allocator: std.mem.Allocator, shader_type: comptime_int, file_path: []const u8) !c_uint {
        const shader = gl.CreateShader(shader_type);
        if (shader == 0) return error.CreateShaderFailed;

        const exe_dir_path = try std.fs.selfExeDirPathAlloc(allocator);
        const absolute_path = try std.fs.path.join(allocator, &.{ exe_dir_path, file_path });

        const file = try std.fs.openFileAbsolute(absolute_path, .{});
        const code = try file.readToEndAllocOptions(allocator, 10 * 1024, null, @alignOf(u8), 0);

        const source = @as([]const u8, code);
        gl.ShaderSource(shader, 1, (&source.ptr)[0..1], (&@as(c_int, @intCast(source.len)))[0..1]);
        gl.CompileShader(shader);

        var success: c_int = undefined;
        var info_log_buf: [512:0]u8 = undefined;
        gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success);
        if (success == gl.FALSE) {
            gl.GetShaderInfoLog(shader, info_log_buf.len, null, &info_log_buf);
            gl_log.err("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
            return error.CompileShaderFailed;
        }

        return shader;
    }

    pub fn setMat4f(self: *Program, name: []const u8, value: zm.Mat) !void {
        const location = try self.getUniformLocation(name);
        var value_arr: [16]f32 = undefined;
        zm.storeMat(&value_arr, value);
        gl.UniformMatrix4fv(location, 1, gl.FALSE, &value_arr);
    }

    fn getUniformLocation(self: *Program, name: []const u8) !c_int {
        const uniform_location = self.uniforms.get(name);
        if (uniform_location) |location| {
            return location;
        }

        const location = gl.GetUniformLocation(self.id, @as([*:0]const u8, @ptrCast(name)));
        try self.uniforms.put(name, location);

        return location;
    }
};
