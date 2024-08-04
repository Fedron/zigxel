const zm = @import("zmath");

const utils = @import("utils.zig");

pub const MovementDirection = enum { forward, backward, left, right };

const MOVEMENT_SPEED = 2.5;
const MOUSE_SENSITIVITY = 0.1;

pub const Camera = struct {
    position: zm.F32x4,
    front: zm.F32x4,
    up: zm.F32x4,
    right: zm.F32x4,

    yaw: f32,
    pitch: f32,
    zoom: f32,

    pub fn create(position: ?zm.F32x4) Camera {
        const pos = position orelse utils.WORLD_ORIGIN;
        return Camera{ .position = pos, .front = utils.WORLD_FRONT, .up = utils.WORLD_UP, .right = utils.WORLD_RIGHT, .yaw = -90.0, .pitch = 0.0, .zoom = 45.0 };
    }

    pub fn getViewMatrix(self: *Camera) zm.Mat {
        return zm.lookAtRh(self.position, self.position + self.front, self.up);
    }

    pub fn processKeyboard(self: *Camera, direction: MovementDirection, dt: f32) void {
        const velocity = zm.f32x4s(MOVEMENT_SPEED * dt);
        switch (direction) {
            .forward => self.position += self.front * velocity,
            .backward => self.position -= self.front * velocity,
            .left => self.position -= self.right * velocity,
            .right => self.position += self.right * velocity,
        }
    }

    pub fn processMouseMovement(self: *Camera, x_offset: f32, y_offset: f32, constrain_pitch: bool) void {
        const xoffset = x_offset * MOUSE_SENSITIVITY;
        const yoffset = y_offset * MOUSE_SENSITIVITY;

        self.yaw += xoffset;
        self.pitch -= yoffset;

        if (constrain_pitch) {
            if (self.pitch > 89.0)
                self.pitch = 89.0;
            if (self.pitch < -89.0)
                self.pitch = -89.0;
        }

        self.updateCameraVectors();
    }

    pub fn processMouseScroll(self: *Camera, y_offset: f32) void {
        self.zoom -= y_offset;
        if (self.zoom < 1.0)
            self.zoom = 1.0;
        if (self.zoom > 45.0)
            self.zoom = 45.0;
    }

    pub fn updateCameraVectors(self: *Camera) void {
        self.front[0] = @cos(self.yaw * utils.DEG_TO_RAD) * @cos(self.pitch * utils.DEG_TO_RAD);
        self.front[1] = @sin(self.pitch * utils.DEG_TO_RAD);
        self.front[2] = @sin(self.yaw * utils.DEG_TO_RAD) * @cos(self.pitch * utils.DEG_TO_RAD);

        self.right = zm.normalize3(zm.cross3(self.front, utils.WORLD_UP));
        self.up = zm.normalize3(zm.cross3(self.right, self.front));
    }
};
