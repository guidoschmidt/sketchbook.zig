const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const panic = std.debug.panic;

var window: *c.GLFWwindow = undefined;

const vertices = [9]f32 {
    -0.5, -0.5, 0.0,
     0.5, -0.5, 0.0,
     0.0, 0.5, 0.0
};
var t: f32 = 0.0;

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

const ShaderMaterial = struct {
    const Self = @This();

    vertexShader: c_uint = undefined,
    fragmentShader: c_uint = undefined,
    shaderProgram: c_uint = undefined,

    pub fn init(self: *Self, vertex_filepath: [:0]const u8, fragment_filepath: [:0]const u8) !void {
        var info_log: []u8 = allocator.alloc(u8, 1024) catch { return; };
        defer allocator.free(info_log);

        const vertex_source = self.loadShaderSource(vertex_filepath);
        const vertex_code = @as([]const u8, vertex_source);
        const vertex_code_ptr = vertex_code.ptr;
        print("Vertex Shader Source:\n------------\n{s}\n------------\n", .{ vertex_source });

        self.vertexShader = c.glCreateShader(c.GL_VERTEX_SHADER);
        c.glShaderSource(self.vertexShader, 1, &vertex_code_ptr, null);
        c.glCompileShader(self.vertexShader);
        var success: c_int = undefined;
        c.glGetShaderiv(self.vertexShader, c.GL_COMPILE_STATUS, &success);
        if (success == c.GL_FALSE) {
            print("\nCould not compile vertex shader\n", .{});
            c.glGetShaderInfoLog(self.vertexShader, 1024, null, @ptrCast([*c]u8, info_log));
            print("\nCould not compile vertex shader\n{s}\n----------", .{ info_log });
        }

        const fragment_source = self.loadShaderSource(fragment_filepath);
        const fragment_code = @as([]const u8, fragment_source);
        const fragment_code_ptr = fragment_code.ptr;
        print("Fragment Shader Source:\n------------\n{s}\n------------\n", .{ fragment_source });
        
        self.fragmentShader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
        c.glShaderSource(self.fragmentShader, 1, &fragment_code_ptr, null);
        c.glCompileShader(self.fragmentShader);
        c.glGetShaderiv(self.fragmentShader, c.GL_COMPILE_STATUS, &success);
        if (success == c.GL_FALSE) {
            print("\nCould not compile vertex shader\n", .{});
            c.glGetShaderInfoLog(self.fragmentShader, 1024, null, @ptrCast([*c]u8, info_log));
            print("\nCould not compile fragment shader\n{s}", .{ info_log });
        }

        self.shaderProgram = c.glCreateProgram();
        c.glAttachShader(self.shaderProgram, self.vertexShader);
        c.glAttachShader(self.shaderProgram, self.fragmentShader);
        c.glLinkProgram(self.shaderProgram);
        c.glGetProgramiv(self.shaderProgram, c.GL_LINK_STATUS, &success);
        if (success == c.GL_FALSE) {
            c.glGetProgramInfoLog(self.shaderProgram, 1024, null, @ptrCast([*c]u8, info_log));
            print("\nCould not link shader program\n{s}", .{ info_log });
        }

        defer c.glDeleteShader(self.vertexShader);
        defer c.glDeleteShader(self.fragmentShader);
    }

    pub fn loadShaderSource(_: *Self, filepath: [:0]const u8) []u8 {
        const file = fs.cwd().openFile(filepath, .{ .mode = .read_only }) catch {
            panic("Error: could not open shader source file {s}", .{ filepath });
        };
        const content = file.readToEndAllocOptions(allocator,
                                                   std.math.maxInt(u32),
                                                   null,
                                                   @alignOf(u8),
                                                   0) catch {
            panic("Error: could not read shader source file {s}", .{ filepath });
        };
        return content;
    }

    pub fn activate(self: *Self) void {
        c.glUseProgram(self.shaderProgram);
    }

    pub fn setUniform(self: *Self, val: f32) void {
        const location = c.glGetUniformLocation(self.shaderProgram, "u_time");
        c.glUniform1f(location, val);
    }
};

const Geometry = struct {
    const Self = @This();

    index_counter: u32 = 0,
    vao: u32 = undefined,
    vbo: u32 = undefined,

    pub fn init(self: *Self) void {
        print("Allocate {?} mesh vertices\n", .{ vertices.len });
        self.build();
    }

    pub fn build(self: *Self) void {
        // Vertex Buffer Object
        c.glGenBuffers(1, &self.vbo);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        c.glBufferData(c.GL_ARRAY_BUFFER,
                       @intCast(c_long, vertices.len),
                       @ptrCast(*const anyopaque, &vertices),
                       c.GL_STATIC_DRAW);
        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
        c.glEnableVertexAttribArray(0);

        // Vertex Array Object
        c.glGenVertexArrays(1, &self.vao);
        c.glBindVertexArray(self.vao);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        c.glBufferData(c.GL_ARRAY_BUFFER,
                       @intCast(c_long, @sizeOf(f32) * vertices.len),
                       @ptrCast(*const anyopaque, &vertices),
                       c.GL_STATIC_DRAW);

        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
        c.glEnableVertexAttribArray(0);
    }

    pub fn draw(self: *Self) void {
        c.glBindVertexArray(self.vao);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
    }
};

const Mesh = struct {
    const Self = @This();

    geometry: Geometry = undefined,
    material: ShaderMaterial = undefined,

    pub fn init(self: *Self) void {
        _ = self;
        print("Mesh Vertex Count: {?}\n", .{ vertices.len });
    }

    pub fn draw(self: *Self) void {
        self.material.activate();
        self.geometry.draw();
    }
};

pub fn main() !void {
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

    // var triangle = t.Triangle {};
    // triangle.init();

    var geometry = Geometry{};
    geometry.init();

    var shaderMaterial = ShaderMaterial{};
    try shaderMaterial.init("src/glsl/vert.glsl", "src/glsl/frag.glsl");
    var mesh = Mesh {
        .geometry = geometry,
        .material = shaderMaterial
    };
    mesh.init();

    while (c.glfwWindowShouldClose(window) == c.GL_FALSE) {
        c.glClearColor(1.0, 1.0, 1.0, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        // c.glViewport(0, 0, 800, 800);

        // triangle.draw();
        shaderMaterial.setUniform( t);
        mesh.draw();

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();

        t = t + 1.0 / 16.0;
    }
}
