//! Guest `free -h` smoke demo.
//!
//! The upstream vibeutils dependency is temporarily removed because it has not
//! been updated for Zig 0.17. Keep this guest entry point so `-Dmain=free-smoke`
//! still builds and boots, but make it a self-contained stub until vibeutils is
//! restored.

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    _ = init;
    std.debug.print("--- free -h smoke start ---\n", .{});
    std.debug.print("free: vibeutils dependency temporarily unavailable\n", .{});
    std.debug.print("--- free -h smoke finished (rc=0) ---\n", .{});
}
