const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
   const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    const source = "./src/main.zig";
    const exe = b.addExecutable("engine", source);

    exe.addIncludePath("/Users/gs/git/c++/glfw/include");
    exe.addLibraryPath("/Users/gs/git/c++/glfw/build/src");

    exe.linkSystemLibrary("glfw3");
    exe.linkSystemLibrary("c");

    exe.setBuildMode(mode);
    exe.setTarget(target);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Start the program");
    run_step.dependOn(&run_cmd.step);
}
