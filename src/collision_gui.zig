const rl = @import("raylib");
const std = @import("std");
const tr = @import("trees.zig");

const Wall = enum {
    none,
    top,
    left,
    bottom,
    right,
};

const CollisionMode = enum {
    color,
    destroy,
};

const Ball = struct {
    pos: rl.Vector2,
    dpos: rl.Vector2,
    radius: f32,
    colliding: bool = false,

    pub fn update(self: *Ball, dt: f32, screen_width: i32, screen_height: i32) void {
        const w_f: f32 = @floatFromInt(screen_width);
        const h_f: f32 = @floatFromInt(screen_height);

        self.pos.x += self.dpos.x * dt;
        self.pos.y += self.dpos.y * dt;

        if (self.pos.x - self.radius < 0) {
            self.pos.x = self.radius;
            self.dpos.x = @abs(self.dpos.x);
        } else if (self.pos.x + self.radius > w_f) {
            self.pos.x = w_f - self.radius;
            self.dpos.x = -@abs(self.dpos.x);
        }

        if (self.pos.y - self.radius < 0) {
            self.pos.y = self.radius;
            self.dpos.y = @abs(self.dpos.y);
        } else if (self.pos.y + self.radius > h_f) {
            self.pos.y = h_f - self.radius;
            self.dpos.y = -@abs(self.dpos.y);
        }
    }

    pub fn tryUpdate(self: *Ball, dt: f32) rl.Vector2 {
        return rl.Vector2{ .x = self.pos.x + self.dpos.x * dt, .y = self.pos.y + self.dpos.y * dt };
    }

    pub fn onWall(self: Ball, screen_width: i32, screen_height: i32) Wall {
        if (self.pos.x - self.radius <= 0) {
            return .left;
        } else if (self.pos.y - self.radius <= 0) {
            return .top;
        } else if (self.pos.x + self.radius >= @as(f32, @floatFromInt(screen_width))) {
            return .right;
        } else if (self.pos.y + self.radius >= @as(f32, @floatFromInt(screen_height))) {
            return .bottom;
        }
        return .none;
    }
};

pub fn randomVelocity(rand: std.Random, magnitude: f32) rl.Vector2 {
    const angle = rand.float(f32) * std.math.tau;
    return rl.Vector2{ .x = @cos(angle) * magnitude, .y = @sin(angle) * magnitude };
}

pub fn randomPos(rand: std.Random, screen_width: i32, screen_height: i32) rl.Vector2 {
    return rl.Vector2{ .x = rand.float(f32) * @as(f32, @floatFromInt(screen_width)), .y = rand.float(f32) * @as(f32, @floatFromInt(screen_height)) };
}

pub fn main(init: std.process.Init) !void {
    var src: std.Random.IoSource = .{ .io = init.io };
    const rand = src.interface();

    const screen_width: i32 = 1600;
    const screen_height: i32 = 1200;
    rl.initWindow(screen_width, screen_height, "Collision GUI");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var balls: std.ArrayList(Ball) = .empty;
    defer balls.deinit(init.gpa);
    var colliding: std.ArrayList(tr.Point2D) = .empty;
    defer colliding.deinit(init.gpa);
    var mode: CollisionMode = .color;
    while (!rl.windowShouldClose()) {
        const mouse_pos = rl.getMousePosition();
        //const point_mous_pos = tr.Point2D.fromRaylib(mouse_pos);

        if (rl.isMouseButtonPressed(.left)) {
            try balls.append(init.gpa, Ball{ .pos = mouse_pos, .dpos = randomVelocity(rand, 500), .radius = 20 });
        }
        if (rl.isKeyPressed(.c)) mode = .color;
        if (rl.isKeyPressed(.d)) mode = .destroy;
        if (rl.isKeyPressed(.r)) {
            for (0..10) |_| {
                try balls.append(init.gpa, Ball{ .pos = randomPos(rand, screen_width, screen_height), .dpos = randomVelocity(rand, 500), .radius = 20 });
            }
        }

        var tree = tr.PointQuadTree.init(tr.Point2D{ .x = 0, .y = 0 }, tr.Point2D{ .x = screen_width, .y = screen_height });
        defer tree.deinit(init.gpa);
        for (balls.items) |*ball| {
            ball.update(rl.getFrameTime(), screen_width, screen_height);
            try tree.split(init.gpa, tr.Point2D.fromRaylib(ball.pos));
        }
        for (balls.items, 0..) |*ball, i| {
            colliding.clearRetainingCapacity();
            try tree.findInCircle(init.gpa, &colliding, tr.Point2D.fromRaylib(ball.pos), @as(i32, @intFromFloat(ball.radius)));
            if (colliding.items.len > 1) { // list always contains self
                ball.colliding = true;
                if (mode == .destroy)
                    _ = balls.swapRemove(i);
            } else {
                ball.colliding = false;
            }
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.light_gray);

        tr.drawTreeRecursiveNoBalls(tree);

        for (balls.items) |ball| {
            const color: rl.Color = if (ball.colliding and mode == .color) .red else .black;
            rl.drawCircleV(ball.pos, ball.radius, color);
        }

        rl.drawFPS(10, 10);
    }
}
