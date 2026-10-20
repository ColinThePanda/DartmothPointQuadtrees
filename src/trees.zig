const rl = @import("raylib");
const std = @import("std");

pub const Point2D = struct {
    x: i32,
    y: i32,

    pub fn fromRaylib(p: rl.Vector2) Point2D {
        return Point2D{ .x = @as(i32, @intFromFloat(p.x)), .y = @as(i32, @intFromFloat(p.y)) };
    }

    pub fn eq(self: Point2D, p: Point2D) bool {
        return self.x == p.x and self.y == p.y;
    }
};

pub fn circleIntersectsRect(center: Point2D, r: i32, top_left: Point2D, bottom_right: Point2D) bool {
    const closest_x: i32 = @min(@max(center.x, top_left.x), bottom_right.x);
    const closest_y: i32 = @min(@max(center.y, top_left.y), bottom_right.y);

    const dist_x = center.x - closest_x;
    const dist_y = center.y - closest_y;

    const distance_squared = (dist_x * dist_x) + (dist_y * dist_y);

    return (distance_squared <= (r * r));
}

pub fn pointInCircle(p: Point2D, center: Point2D, r: i32) bool {
    const dx = p.x - center.x;
    const dy = p.y - center.y;
    return dx * dx + dy * dy <= r * r;
}

pub const PointQuadTree = struct {
    top_left: Point2D,
    bottom_right: Point2D,
    c1: ?*PointQuadTree, // ?*PointQuadTree = pointer to PointQuadTree or null
    c2: ?*PointQuadTree,
    c3: ?*PointQuadTree,
    c4: ?*PointQuadTree,
    depth: i32,

    pub fn init(top_left: Point2D, bottom_right: Point2D) PointQuadTree {
        return PointQuadTree{
            .top_left = top_left,
            .bottom_right = bottom_right,
            .c1 = null,
            .c2 = null,
            .c3 = null,
            .c4 = null,
            .depth = 0,
        };
    }

    pub fn initDepth(top_left: Point2D, bottom_right: Point2D, depth: i32) PointQuadTree {
        return PointQuadTree{
            .top_left = top_left,
            .bottom_right = bottom_right,
            .c1 = null,
            .c2 = null,
            .c3 = null,
            .c4 = null,
            .depth = depth,
        };
    }

    pub fn deinit(self: *PointQuadTree, allocator: std.mem.Allocator) void {
        if (self.c1) |c1| {
            c1.deinit(allocator);
            allocator.destroy(c1);
        }
        if (self.c2) |c2| {
            c2.deinit(allocator);
            allocator.destroy(c2);
        }
        if (self.c3) |c3| {
            c3.deinit(allocator);
            allocator.destroy(c3);
        }
        if (self.c4) |c4| {
            c4.deinit(allocator);
            allocator.destroy(c4);
        }
        self.c1 = null;
        self.c2 = null;
        self.c3 = null;
        self.c4 = null;
    }

    pub fn hasSplit(self: PointQuadTree) bool {
        return self.c1 != null and self.c2 != null and self.c3 != null and self.c4 != null;
    }

    fn newChild(allocator: std.mem.Allocator, top_left: Point2D, bottom_right: Point2D, depth: i32) !*PointQuadTree {
        const node = try allocator.create(PointQuadTree);
        node.* = .initDepth(top_left, bottom_right, depth);
        return node;
    }

    pub fn split(self: *PointQuadTree, allocator: std.mem.Allocator, p: Point2D) !void {
        if (!self.pointIn(p)) return error.PointOutOfBounds;

        var node = self.getQuadrantRecursive(p);

        const d = node.depth + 1;
        const c1 = try newChild(allocator, .{ .x = p.x, .y = node.top_left.y }, .{ .x = node.bottom_right.x, .y = p.y }, d);
        errdefer allocator.destroy(c1);
        const c2 = try newChild(allocator, node.top_left, p, d);
        errdefer allocator.destroy(c2);
        const c3 = try newChild(allocator, .{ .x = node.top_left.x, .y = p.y }, .{ .x = p.x, .y = node.bottom_right.y }, d);
        errdefer allocator.destroy(c3);
        const c4 = try newChild(allocator, p, node.bottom_right, d);

        node.c1 = c1;
        node.c2 = c2;
        node.c3 = c3;
        node.c4 = c4;
    }

    pub fn pointIn(self: PointQuadTree, point: Point2D) bool {
        return point.x >= self.top_left.x and point.x <= self.bottom_right.x and point.y >= self.top_left.y and point.y <= self.bottom_right.y;
    }

    pub fn getQuadrant(self: PointQuadTree, point: Point2D) ?*PointQuadTree {
        if (self.c1) |c1| {
            if (c1.pointIn(point)) {
                return c1;
            }
        }
        if (self.c2) |c2| {
            if (c2.pointIn(point)) {
                return c2;
            }
        }
        if (self.c3) |c3| {
            if (c3.pointIn(point)) {
                return c3;
            }
        }
        if (self.c4) |c4| {
            if (c4.pointIn(point)) {
                return c4;
            }
        }
        return null;
    }

    pub fn getQuadrantRecursive(self: *PointQuadTree, point: Point2D) *PointQuadTree {
        var quadrant = self;
        while (true) {
            const new_quadrant = quadrant.getQuadrant(point);
            if (new_quadrant == null) {
                return quadrant;
            }
            quadrant = new_quadrant.?;
        }
    }

    pub fn splitPoint(self: PointQuadTree) ?Point2D {
        const c2 = self.c2 orelse return null;
        return c2.bottom_right;
    }

    pub fn size(self: PointQuadTree) usize {
        if (!self.hasSplit()) return 0;
        return 1 + self.c1.?.size() + self.c2.?.size() + self.c3.?.size() + self.c4.?.size();
    }

    pub fn allPoints(self: PointQuadTree, allocator: std.mem.Allocator, list: *std.ArrayList(Point2D)) !void {
        const p = self.splitPoint() orelse return;
        try list.append(allocator, p);
        for ([_]?*PointQuadTree{ self.c1, self.c2, self.c3, self.c4 }) |c| {
            try c.?.allPoints(allocator, list);
        }
    }

    pub fn findInCircle(self: PointQuadTree, allocator: std.mem.Allocator, list: *std.ArrayList(Point2D), center: Point2D, r: i32) !void {
        if (!circleIntersectsRect(center, r, self.top_left, self.bottom_right)) return;
        const p = self.splitPoint() orelse return;
        if (pointInCircle(p, center, r)) try list.append(allocator, p);
        for ([_]?*PointQuadTree{ self.c1, self.c2, self.c3, self.c4 }) |c| {
            try c.?.findInCircle(allocator, list, center, r);
        }
    }
};

pub fn getTreeColor(depth: i32) rl.Color {
    const idx = @mod(depth, 6);
    return switch (idx) {
        0 => rl.Color.red,
        1 => rl.Color.orange,
        2 => rl.Color.yellow,
        3 => rl.Color.green,
        4 => rl.Color.blue,
        5 => rl.Color.purple,
        else => unreachable,
    };
}

pub fn drawTree(tree: PointQuadTree) void {
    if (!tree.hasSplit()) return;
    const split_point = tree.splitPoint().?;
    const radius: f32 = 5;
    const color = getTreeColor(tree.depth);
    rl.drawLine(tree.top_left.x, split_point.y, tree.bottom_right.x, split_point.y, color);
    rl.drawLine(split_point.x, tree.top_left.y, split_point.x, tree.bottom_right.y, color);
    rl.drawCircle(split_point.x, split_point.y, radius, color);
}

pub fn drawTreeHighlighted(tree: PointQuadTree, highlighted: std.ArrayList(Point2D)) void {
    if (!tree.hasSplit()) return;
    const split_point = tree.splitPoint().?;
    var radius: f32 = 5;
    for (highlighted.items) |highlight| {
        if (highlight.eq(split_point))
            radius = 25;
    }
    const color = getTreeColor(tree.depth);
    rl.drawLine(tree.top_left.x, split_point.y, tree.bottom_right.x, split_point.y, color);
    rl.drawLine(split_point.x, tree.top_left.y, split_point.x, tree.bottom_right.y, color);
    rl.drawCircle(split_point.x, split_point.y, radius, color);
}

pub fn drawTreeNoBalls(tree: PointQuadTree) void {
    if (!tree.hasSplit()) return;
    const split_point = tree.splitPoint().?;
    const color = getTreeColor(tree.depth);
    rl.drawLine(tree.top_left.x, split_point.y, tree.bottom_right.x, split_point.y, color);
    rl.drawLine(split_point.x, tree.top_left.y, split_point.x, tree.bottom_right.y, color);
}

pub fn drawTreeRecursive(tree: PointQuadTree, highlighted: std.ArrayList(Point2D)) void {
    drawTree(tree, highlighted);
    if (tree.hasSplit()) {
        drawTreeRecursive(tree.c1.?.*, highlighted);
        drawTreeRecursive(tree.c2.?.*, highlighted);
        drawTreeRecursive(tree.c3.?.*, highlighted);
        drawTreeRecursive(tree.c4.?.*, highlighted);
    }
}

pub fn drawTreeRecursiveHighlighted(tree: PointQuadTree, highlighted: std.ArrayList(Point2D)) void {
    drawTreeHighlighted(tree, highlighted);
    if (tree.hasSplit()) {
        drawTreeRecursiveHighlighted(tree.c1.?.*, highlighted);
        drawTreeRecursiveHighlighted(tree.c2.?.*, highlighted);
        drawTreeRecursiveHighlighted(tree.c3.?.*, highlighted);
        drawTreeRecursiveHighlighted(tree.c4.?.*, highlighted);
    }
}

pub fn drawTreeRecursiveNoBalls(tree: PointQuadTree) void {
    drawTreeNoBalls(tree);
    if (tree.hasSplit()) {
        drawTreeRecursiveNoBalls(tree.c1.?.*);
        drawTreeRecursiveNoBalls(tree.c2.?.*);
        drawTreeRecursiveNoBalls(tree.c3.?.*);
        drawTreeRecursiveNoBalls(tree.c4.?.*);
    }
}
