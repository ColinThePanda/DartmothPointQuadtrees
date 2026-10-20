const rl = @import("raylib");
const std = @import("std");
const tr = @import("trees.zig");

const ActionMode = enum { add, query };

pub fn main(init: std.process.Init) !void {
    const screen_width: i32 = 1600;
    const screen_height: i32 = 1200;
    rl.initWindow(screen_width, screen_height, "Dot Tree GUI");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var tree: tr.PointQuadTree = .init(tr.Point2D{ .x = 0, .y = 0 }, tr.Point2D{ .x = screen_width, .y = screen_height });
    defer tree.deinit(init.gpa);
    var mode: ActionMode = .add;
    var circle_size: f32 = 25;

    var highlighted: std.ArrayList(tr.Point2D) = .empty;
    defer highlighted.deinit(init.gpa);
    while (!rl.windowShouldClose()) {
        if (rl.isKeyPressed(.a))
            mode = .add;
        if (rl.isKeyPressed(.q))
            mode = .query;
        if (rl.isKeyPressed(.equal))
            circle_size += 5;
        if (rl.isKeyPressed(.minus))
            circle_size = @max(circle_size - 5, 5);

        const mouse_pos = rl.getMousePosition();
        const point_mous_pos = tr.Point2D.fromRaylib(mouse_pos);
        if (rl.isMouseButtonPressed(.left)) {
            if (mode == .add) {
                try tree.split(init.gpa, point_mous_pos);
            }
        }

        highlighted.clearRetainingCapacity();
        if (mode == .query)
            try tree.findInCircle(init.gpa, &highlighted, point_mous_pos, @as(i32, @intFromFloat(circle_size)));

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.light_gray);

        tr.drawTreeRecursiveHighlighted(tree, highlighted);

        if (mode == .query)
            rl.drawCircle(point_mous_pos.x, point_mous_pos.y, circle_size, rl.Color{ .r = 255, .g = 0, .b = 0, .a = 100 });
    }
}
