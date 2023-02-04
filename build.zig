const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
   const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    const source = "./src/main.zig";
    const exe = b.addExecutable("engine", source);

    exe.addIncludePath("./libs/glfw/include");
    exe.addLibraryPath("./libs/glfw/build/src");

    exe.addIncludePath("./libs/glad/include");
    exe.addCSourceFile("./libs/glad/src/glad.c", &[_][]const u8{ "-std=c99" });

    exe.linkLibC();
    exe.linkSystemLibrary("glfw3");

    exe.setBuildMode(mode);
    exe.setTarget(target);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Start the program");
    run_step.dependOn(&run_cmd.step);
}
