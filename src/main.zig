const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");
const print = std.debug.print;
const panic = std.debug.panic;

var window: *c.GLFWwindow = undefined;

export fn errorCallback(err: c_int, description: [*c]const u8) void {
    _ = err;
    panic("Error: {s}\n", .{description});
}

export fn keyCallback(w: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mode: c_int) void {
    print("mode: {} / scancode: {} / key: {}\n", .{ mode, scancode, key });
    if (key == c.GLFW_KEY_ESCAPE and action == c.GLFW_PRESS) {
        c.glfwSetWindowShouldClose(w, c.GL_TRUE);
    }
}

pub fn main() void {
    _ = c.glfwSetErrorCallback(errorCallback);
    if (c.glfwInit() == c.GL_FALSE) {
        print("Failed to initalize GLFW.\n", .{});
    }

    if (c.glfwVulkanSupported() == c.GL_FALSE) {
        print("Vulkan not supported!\n", .{});
    } else {
        print("Vulkan supported!\n", .{});
    }

    var monitor: ?*c.GLFWmonitor = null; // or either use c.glfwGetPrimaryMonitor();
    window = c.glfwCreateWindow(800, 800, "engine", monitor, null) orelse undefined;
    c.glfwMakeContextCurrent(window);
    _ = c.glfwSetKeyCallback(window, keyCallback);

    while (c.glfwWindowShouldClose(window) == c.GL_FALSE) {
        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
