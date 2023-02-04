const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");
const print = std.debug.print;
const panic = std.debug.panic;

var window: *c.GLFWwindow = undefined;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

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

export fn framebufferSizeCallback(w: ?*c.GLFWwindow, width: c_int, height: c_int) void {
    _ = w;
    print("Framebuffer size: {?} × {?}\n", .{ width, height });
    c.glViewport(0, 0, width, height);
}

const Triangle = struct {
    const Self = @This();

    vertices: [9]f32 = undefined,
    vao: u32 = undefined,
    vbo: u32 = undefined,
    vertexShader: c_uint = undefined,
    fragmentShader: c_uint = undefined,
    shaderProgram: c_uint = undefined,

    pub fn init(self: *Self) void {
        self.vertices = [_]f32 { -0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0 };
        c.glGenBuffers(1, &self.vbo);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        c.glBufferData(c.GL_ARRAY_BUFFER, self.vertices.len, &self.vertices, c.GL_STATIC_DRAW);
        self.creatShader() catch return;
    }

    pub fn creatShader(self: *Self) !void {
        const vertexShaderSource =
            \\#version 330 core
            \\layout (location = 0) in vec3 aPos;
            \\
            \\void main()
            \\{
            \\    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
            \\}
        ;
        const vertexCode = @as([]const u8, vertexShaderSource);
        const vertexCodePtr = vertexCode.ptr;
        self.vertexShader = c.glCreateShader(c.GL_VERTEX_SHADER);
        c.glShaderSource(self.vertexShader, 1, &vertexCodePtr, null);
        c.glCompileShader(self.vertexShader);
        var success: c_int = undefined;
        var info_log: [512]u8 = undefined;
        _ = info_log;
        c.glGetShaderiv(self.vertexShader, c.GL_COMPILE_STATUS, &success);
        if (success == c.GL_FALSE) {
            print("\nCould not compile vertex shader", .{});
        }

        const fragmentShaderSource =
            \\#version 330 core
            \\out vec4 FragColor;
            \\
            \\void main()
            \\{
            \\    FragColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);
            \\}
        ;
        const fragmentCode = @as([]const u8, fragmentShaderSource);
        const fragmentCodePtr = fragmentCode.ptr;
        self.fragmentShader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
        c.glShaderSource(self.fragmentShader, 1, &fragmentCodePtr, null);
        c.glCompileShader(self.fragmentShader);
        c.glGetShaderiv(self.fragmentShader, c.GL_COMPILE_STATUS, &success);
        if (success == c.GL_FALSE) {
            print("\nCould not compile fragment shader", .{});
        }

        self.shaderProgram = c.glCreateProgram();
        c.glAttachShader(self.shaderProgram, self.vertexShader);
        c.glAttachShader(self.shaderProgram, self.fragmentShader);
        c.glLinkProgram(self.shaderProgram);
        c.glGetProgramiv(self.shaderProgram, c.GL_LINK_STATUS, &success);
        if (success == c.GL_FALSE) {
            print("\nCould not link shader program", .{}); 
        }

        defer c.glDeleteShader(self.vertexShader);
        defer c.glDeleteShader(self.fragmentShader);

        c.glGenVertexArrays(1, &self.vao);
        c.glBindVertexArray(self.vao);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        c.glBufferData(c.GL_ARRAY_BUFFER,
                       @sizeOf(f32) * self.vertices.len,
                       &self.vertices,
                       c.GL_STATIC_DRAW);

        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
        c.glEnableVertexAttribArray(0);
    }

    pub fn draw(self: *Self) void {
        c.glUseProgram(self.shaderProgram);
        c.glBindVertexArray(self.vao);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
    }
};

pub fn main() void {
    _ = c.glfwSetErrorCallback(errorCallback);
    if (c.glfwInit() == c.GL_FALSE) {
        print("Failed to initalize GLFW.\n", .{});
    }
    defer c.glfwTerminate();

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    if (c.glfwVulkanSupported() == c.GL_FALSE) {
        print("Vulkan not supported!\n", .{});
    } else {
        print("Vulkan supported!\n", .{});
    }

    var monitor: ?*c.GLFWmonitor = null; // or either use c.glfwGetPrimaryMonitor();
    window = c.glfwCreateWindow(1000, 1000, "engine", monitor, null) orelse undefined;
    c.glfwMakeContextCurrent(window);
    _ = c.glfwSetKeyCallback(window, keyCallback);
    _ = c.glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);

    if (c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, &c.glfwGetProcAddress)) == 0) {
        panic("Failed to initialise GLAD\n", .{});
    }

    var triangle = Triangle {};
    triangle.init();

    while (c.glfwWindowShouldClose(window) == c.GL_FALSE) {
        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        // c.glViewport(0, 0, 800, 800);

        triangle.draw();

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
