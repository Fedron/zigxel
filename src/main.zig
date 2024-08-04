const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const zm = @import("zmath");

const camera = @import("camera.zig");
const shader = @import("shader.zig");
const utils = @import("utils.zig");

const glfw_log = std.log.scoped(.glfw);
const gl_log = std.log.scoped(.gl);

fn logGLFWError(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    glfw_log.err("{}: {s}\n", .{ error_code, description });
}

/// Procedure table that will hold loaded OpenGL functions.
var gl_procs: gl.ProcTable = undefined;

var world_camera = camera.Camera.create(zm.loadArr3(.{ 0.0, 0.0, 5.0 }));
var lastX: f64 = 0.0;
var lastY: f64 = 0.0;
var first_mouse = true;

const Vertex = struct {
    position: [3]f32,
    color: [3]f32,
};

const quad_mesh = struct {
    // zig fmt: off
    const vertices = [4]Vertex{
        .{ .position = .{ -0.5, 0.5, 0.0 }, .color = .{ 1.0, 0.0, 0.0 } },
        .{ .position = .{ 0.5, 0.5, 0.0 }, .color = .{ 0.0, 1.0, 0.0 } },
        .{ .position = .{ 0.5, -0.5, 0.0 }, .color = .{ 0.0, 0.0, 1.0 } },
        .{ .position = .{ -0.5, -0.5, 0.0 }, .color = .{ 1.0, 0.0, 1.0 } },
    };
    // zig fmt: on

    const indices = [6]u8{ 0, 1, 3, 1, 2, 3 };
};

var delta_time: f32 = 0.0;
var last_frame: f32 = 0.0;

fn processInput(window: glfw.Window) void {
    if (glfw.Window.getKey(window, glfw.Key.escape) == glfw.Action.press) {
        _ = glfw.Window.setShouldClose(window, true);
    }

    if (glfw.Window.getKey(window, glfw.Key.w) == glfw.Action.press) {
        world_camera.processKeyboard(.forward, delta_time);
    }
    if (glfw.Window.getKey(window, glfw.Key.s) == glfw.Action.press) {
        world_camera.processKeyboard(.backward, delta_time);
    }
    if (glfw.Window.getKey(window, glfw.Key.a) == glfw.Action.press) {
        world_camera.processKeyboard(.left, delta_time);
    }
    if (glfw.Window.getKey(window, glfw.Key.d) == glfw.Action.press) {
        world_camera.processKeyboard(.right, delta_time);
    }
}

fn mouseCallback(window: glfw.Window, xpos: f64, ypos: f64) void {
    _ = window;

    if (first_mouse) {
        lastX = xpos;
        lastY = ypos;
        first_mouse = false;
    }

    const x_offset = xpos - lastX;
    const y_offset = ypos - lastY;

    lastX = xpos;
    lastY = ypos;

    world_camera.processMouseMovement(@floatCast(x_offset), @floatCast(y_offset), true);
}

fn mouseScrollCallback(window: glfw.Window, xoffset: f64, yoffset: f64) void {
    _ = window;
    _ = xoffset;

    world_camera.processMouseScroll(@floatCast(yoffset));
}

fn framebufferSizeCallback(window: glfw.Window, width: u32, height: u32) void {
    _ = window;
    gl.Viewport(0, 0, @intCast(width), @intCast(height));
}

pub fn main() !void {
    glfw.setErrorCallback(logGLFWError);

    if (!glfw.init(.{})) {
        glfw_log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        return error.GLFWInitFailed;
    }
    defer glfw.terminate();

    // Create our window, specifying that we want to use OpenGL.
    const window: glfw.Window = glfw.Window.create(1280, 720, "zigxel", null, null, .{
        .context_version_major = gl.info.version_major,
        .context_version_minor = gl.info.version_minor,
        .opengl_profile = .opengl_core_profile,
        .opengl_forward_compat = true,
    }) orelse {
        glfw_log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        return error.CreateWindowFailed;
    };
    defer window.destroy();

    // Make the window's OpenGL context current.
    glfw.makeContextCurrent(window);
    defer glfw.makeContextCurrent(null);

    glfw.Window.setFramebufferSizeCallback(window, framebufferSizeCallback);
    glfw.Window.setInputMode(window, glfw.Window.InputMode.cursor, glfw.Window.InputModeCursor.disabled);
    glfw.Window.setCursorPosCallback(window, mouseCallback);
    glfw.Window.setScrollCallback(window, mouseScrollCallback);

    // Enable VSync to avoid drawing more often than necessary.
    glfw.swapInterval(1);

    // Initialize the OpenGL procedure table.
    if (!gl_procs.init(glfw.getProcAddress)) {
        gl_log.err("failed to load OpenGL functions", .{});
        return error.GLInitFailed;
    }

    // Make the OpenGL procedure table current.
    gl.makeProcTableCurrent(&gl_procs);
    defer gl.makeProcTableCurrent(null);

    // The window and OpenGL are now both fully initialized.

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var arena_allocator_state = std.heap.ArenaAllocator.init(allocator);
    defer arena_allocator_state.deinit();
    const arena_allocator = arena_allocator_state.allocator();

    var program = try shader.Program.create(arena_allocator, "res/shader.vert.glsl", "res/shader.frag.glsl");
    defer program.destroy();

    // Vertex Array Object (VAO), remembers instructions for how vertex data is laid out in memory.
    // Using VAOs is strictly required in modern OpenGL.
    var vao: c_uint = undefined;
    gl.GenVertexArrays(1, (&vao)[0..1]);
    defer gl.DeleteVertexArrays(1, (&vao)[0..1]);

    // Vertex Buffer Object (VBO), holds vertex data.
    var vbo: c_uint = undefined;
    gl.GenBuffers(1, (&vbo)[0..1]);
    defer gl.DeleteBuffers(1, (&vbo)[0..1]);

    // Index Buffer Object (IBO), maps indices to vertices (to enable reusing vertices).
    var ibo: c_uint = undefined;
    gl.GenBuffers(1, (&ibo)[0..1]);
    defer gl.DeleteBuffers(1, (&ibo)[0..1]);

    {
        // Make our VAO the current global VAO, but unbind it when we're done so we don't end up
        // inadvertently modifying it later.
        gl.BindVertexArray(vao);
        defer gl.BindVertexArray(0);

        {
            // Make our VBO the current global VBO and unbind it when we're done.
            gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
            defer gl.BindBuffer(gl.ARRAY_BUFFER, 0);

            // Upload vertex data to the VBO.
            gl.BufferData(
                gl.ARRAY_BUFFER,
                @sizeOf(@TypeOf(quad_mesh.vertices)),
                &quad_mesh.vertices,
                gl.STATIC_DRAW,
            );

            try program.enable_vertex_attrib_pointers(Vertex);
        }

        // Instruct the VAO to use our IBO, then upload index data to the IBO.
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ibo);
        gl.BufferData(
            gl.ELEMENT_ARRAY_BUFFER,
            @sizeOf(@TypeOf(quad_mesh.indices)),
            &quad_mesh.indices,
            gl.STATIC_DRAW,
        );
    }

    main_loop: while (true) {
        glfw.pollEvents();

        // Exit the main loop if the user is trying to close the window.
        if (window.shouldClose()) break :main_loop;

        {
            const current_frame: f32 = @floatCast(glfw.getTime());
            delta_time = current_frame - last_frame;
            last_frame = current_frame;

            processInput(window);

            // Clear the screen to white.
            gl.ClearColor(0.2, 0.2, 0.2, 1.0);
            gl.Clear(gl.COLOR_BUFFER_BIT);

            gl.UseProgram(program.id);
            defer gl.UseProgram(0);

            const projection_matrix = proj: {
                const window_size = window.getSize();
                const aspect = @as(f32, @floatFromInt(window_size.width)) / @as(f32, @floatFromInt(window_size.height));
                break :proj zm.perspectiveFovRhGl(world_camera.zoom * utils.DEG_TO_RAD, aspect, 0.1, 1000.0);
            };
            try program.setMat4f("projection", projection_matrix);

            const view_matrix = world_camera.getViewMatrix();
            try program.setMat4f("view", view_matrix);

            const model_matrix = zm.identity();
            try program.setMat4f("model", model_matrix);

            gl.BindVertexArray(vao);
            defer gl.BindVertexArray(0);

            // Draw the hexagon!
            gl.DrawElements(gl.TRIANGLES, quad_mesh.indices.len, gl.UNSIGNED_BYTE, 0);
        }

        window.swapBuffers();
    }
}
