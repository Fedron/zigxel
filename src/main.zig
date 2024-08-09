const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const zm = @import("zmath");

const camera = @import("camera.zig");
const mesh = @import("mesh.zig");
const shader = @import("shader.zig");
const utils = @import("utils.zig");

const glfw_log = std.log.scoped(.glfw);
const gl_log = std.log.scoped(.gl);

fn logGLFWError(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    glfw_log.err("{}: {s}\n", .{ error_code, description });
}

var gl_procs: gl.ProcTable = undefined;

var world_camera = camera.Camera.create(zm.loadArr3(.{ 0.0, 0.0, 5.0 }));
var lastX: f64 = 0.0;
var lastY: f64 = 0.0;
var first_mouse = true;

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

const QuadFace = enum {
    front,
    back,
    left,
    right,
    top,
    bottom,

    fn asVertices(self: QuadFace) struct { vertices: [4]mesh.Vertex, indices: [6]u8 } {
        switch (self) {
            .front => return .{ .vertices = .{
                .{ .position = .{ -0.5, 0.5, -0.5 }, .color = .{ 1.0, 0.0, 0.0 } },
                .{ .position = .{ 0.5, 0.5, -0.5 }, .color = .{ 1.0, 0.0, 0.0 } },
                .{ .position = .{ 0.5, -0.5, -0.5 }, .color = .{ 1.0, 0.0, 0.0 } },
                .{ .position = .{ -0.5, -0.5, -0.5 }, .color = .{ 1.0, 0.0, 0.0 } },
            }, .indices = .{ 0, 1, 3, 1, 2, 3 } },
            .back => return .{ .vertices = .{
                .{ .position = .{ 0.5, 0.5, 0.5 }, .color = .{ 0.0, 1.0, 0.0 } },
                .{ .position = .{ -0.5, 0.5, 0.5 }, .color = .{ 0.0, 1.0, 0.0 } },
                .{ .position = .{ -0.5, -0.5, 0.5 }, .color = .{ 0.0, 1.0, 0.0 } },
                .{ .position = .{ 0.5, -0.5, 0.5 }, .color = .{ 0.0, 1.0, 0.0 } },
            }, .indices = .{ 0, 1, 3, 1, 2, 3 } },
            .left => return .{ .vertices = .{
                .{ .position = .{ -0.5, 0.5, -0.5 }, .color = .{ 0.0, 0.0, 1.0 } },
                .{ .position = .{ -0.5, 0.5, 0.5 }, .color = .{ 0.0, 0.0, 1.0 } },
                .{ .position = .{ -0.5, -0.5, 0.5 }, .color = .{ 0.0, 0.0, 1.0 } },
                .{ .position = .{ -0.5, -0.5, -0.5 }, .color = .{ 0.0, 0.0, 1.0 } },
            }, .indices = .{ 0, 1, 3, 1, 2, 3 } },
            .right => return .{ .vertices = .{
                .{ .position = .{ 0.5, 0.5, 0.5 }, .color = .{ 1.0, 0.0, 1.0 } },
                .{ .position = .{ 0.5, 0.5, -0.5 }, .color = .{ 1.0, 0.0, 1.0 } },
                .{ .position = .{ 0.5, -0.5, -0.5 }, .color = .{ 1.0, 0.0, 1.0 } },
                .{ .position = .{ 0.5, -0.5, 0.5 }, .color = .{ 1.0, 0.0, 1.0 } },
            }, .indices = .{ 0, 1, 3, 1, 2, 3 } },
            .top => return .{ .vertices = .{
                .{ .position = .{ -0.5, 0.5, -0.5 }, .color = .{ 0.0, 1.0, 1.0 } },
                .{ .position = .{ 0.5, 0.5, -0.5 }, .color = .{ 0.0, 1.0, 1.0 } },
                .{ .position = .{ 0.5, 0.5, 0.5 }, .color = .{ 0.0, 1.0, 1.0 } },
                .{ .position = .{ -0.5, 0.5, 0.5 }, .color = .{ 0.0, 1.0, 1.0 } },
            }, .indices = .{ 0, 1, 3, 1, 2, 3 } },
            .bottom => return .{ .vertices = .{
                .{ .position = .{ -0.5, -0.5, 0.5 }, .color = .{ 1.0, 1.0, 0.0 } },
                .{ .position = .{ 0.5, -0.5, 0.5 }, .color = .{ 1.0, 1.0, 0.0 } },
                .{ .position = .{ 0.5, -0.5, -0.5 }, .color = .{ 1.0, 1.0, 0.0 } },
                .{ .position = .{ -0.5, -0.5, -0.5 }, .color = .{ 1.0, 1.0, 0.0 } },
            }, .indices = .{ 0, 1, 3, 1, 2, 3 } },
        }
    }
};

pub fn main() !void {
    glfw.setErrorCallback(logGLFWError);

    if (!glfw.init(.{})) {
        glfw_log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        return error.GLFWInitFailed;
    }
    defer glfw.terminate();

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

    glfw.makeContextCurrent(window);
    defer glfw.makeContextCurrent(null);

    glfw.Window.setFramebufferSizeCallback(window, framebufferSizeCallback);
    glfw.Window.setInputMode(window, glfw.Window.InputMode.cursor, glfw.Window.InputModeCursor.disabled);
    glfw.Window.setCursorPosCallback(window, mouseCallback);
    glfw.Window.setScrollCallback(window, mouseScrollCallback);

    glfw.swapInterval(1);

    if (!gl_procs.init(glfw.getProcAddress)) {
        gl_log.err("failed to load OpenGL functions", .{});
        return error.GLInitFailed;
    }

    gl.makeProcTableCurrent(&gl_procs);
    defer gl.makeProcTableCurrent(null);

    gl.FrontFace(gl.CW);
    gl.Enable(gl.CULL_FACE);
    gl.CullFace(gl.BACK);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var arena_allocator_state = std.heap.ArenaAllocator.init(allocator);
    defer arena_allocator_state.deinit();
    const arena_allocator = arena_allocator_state.allocator();

    var program = try shader.Program.create(arena_allocator, "res/shader.vert.glsl", "res/shader.frag.glsl");
    defer program.destroy();

    const quadFace = QuadFace.left.asVertices();
    var quad = try mesh.Mesh.init(&program, &quadFace.vertices, &quadFace.indices);
    defer quad.deinit();

    main_loop: while (true) {
        glfw.pollEvents();

        if (window.shouldClose()) break :main_loop;

        {
            const current_frame: f32 = @floatCast(glfw.getTime());
            delta_time = current_frame - last_frame;
            last_frame = current_frame;

            processInput(window);

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

            quad.draw();
        }

        window.swapBuffers();
    }
}
