// ═══════════════════════════════════════════════════════════════════
//  NULLKIA ZIG INSTALLER
//  High-performance system installer in Zig
//  @author bad-antics | discord.gg/killers
// ═══════════════════════════════════════════════════════════════════

const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const os = std.os;
const io = std.io;

const VERSION = "2.0.0";
const AUTHOR = "bad-antics";
const DISCORD = "discord.gg/killers";

const BANNER =
    \\
    \\ ╭──────────────────────────────────────────╮
    \\ │       📱 NULLKIA ZIG INSTALLER           │
    \\ │       ════════════════════════           │
    \\ │                                          │
    \\ │   ⚡ Zero-Cost Abstractions              │
    \\ │   🔧 Memory-Safe Installation            │
    \\ │   💾 Compile-Time Verification           │
    \\ │                                          │
    \\ │          bad-antics | NullSec            │
    \\ ╰──────────────────────────────────────────╯
    \\
;

// ═══════════════════════════════════════════════════════════════════
// License Management
// ═══════════════════════════════════════════════════════════════════

const LicenseTier = enum {
    Free,
    Premium,
    Enterprise,
};

const License = struct {
    key: []const u8,
    tier: LicenseTier,
    valid: bool,
};

fn validateLicense(key: []const u8) License {
    if (key.len != 24) {
        return License{ .key = "", .tier = .Free, .valid = false };
    }

    if (!mem.startsWith(u8, key, "NKIA-")) {
        return License{ .key = "", .tier = .Free, .valid = false };
    }

    // Check tier based on key pattern
    var tier: LicenseTier = .Free;
    if (key.len > 5) {
        if (mem.startsWith(u8, key[5..], "PR")) {
            tier = .Premium;
        } else if (mem.startsWith(u8, key[5..], "EN")) {
            tier = .Enterprise;
        }
    }

    return License{
        .key = key,
        .tier = tier,
        .valid = true,
    };
}

// ═══════════════════════════════════════════════════════════════════
// Installation Components
// ═══════════════════════════════════════════════════════════════════

const Component = struct {
    name: []const u8,
    description: []const u8,
    size_mb: u32,
    requires_premium: bool,
    selected: bool,
};

const components = [_]Component{
    .{ .name = "core", .description = "NullKia Core Framework", .size_mb = 50, .requires_premium = false, .selected = true },
    .{ .name = "samsung", .description = "Samsung/Knox Tools", .size_mb = 120, .requires_premium = false, .selected = true },
    .{ .name = "apple", .description = "Apple/iOS Tools", .size_mb = 150, .requires_premium = true, .selected = false },
    .{ .name = "google", .description = "Google Pixel/Titan M", .size_mb = 100, .requires_premium = false, .selected = true },
    .{ .name = "oneplus", .description = "OnePlus Tools", .size_mb = 80, .requires_premium = false, .selected = false },
    .{ .name = "xiaomi", .description = "Xiaomi/MIUI Tools", .size_mb = 90, .requires_premium = false, .selected = false },
    .{ .name = "huawei", .description = "Huawei/EMUI Tools", .size_mb = 85, .requires_premium = true, .selected = false },
    .{ .name = "firmware", .description = "Firmware Analysis Suite", .size_mb = 200, .requires_premium = true, .selected = false },
    .{ .name = "baseband", .description = "Baseband Research Tools", .size_mb = 180, .requires_premium = true, .selected = false },
    .{ .name = "exploits", .description = "Exploit Database", .size_mb = 300, .requires_premium = true, .selected = false },
};

// ═══════════════════════════════════════════════════════════════════
// Console Output
// ═══════════════════════════════════════════════════════════════════

fn printColored(comptime color: []const u8, msg: []const u8) void {
    const stdout = std.io.getStdOut().writer();
    stdout.print("\x1b[{s}m{s}\x1b[0m\n", .{ color, msg }) catch {};
}

fn printSuccess(msg: []const u8) void {
    printColored("32", msg);
}

fn printError(msg: []const u8) void {
    printColored("31", msg);
}

fn printWarning(msg: []const u8) void {
    printColored("33", msg);
}

fn printInfo(msg: []const u8) void {
    printColored("36", msg);
}

// ═══════════════════════════════════════════════════════════════════
// Progress Bar
// ═══════════════════════════════════════════════════════════════════

fn drawProgressBar(current: u32, total: u32, width: u32) void {
    const stdout = std.io.getStdOut().writer();
    const progress = @as(f32, @floatFromInt(current)) / @as(f32, @floatFromInt(total));
    const filled = @as(u32, @intFromFloat(progress * @as(f32, @floatFromInt(width))));
    
    stdout.print("\r  [", .{}) catch {};
    
    var i: u32 = 0;
    while (i < width) : (i += 1) {
        if (i < filled) {
            stdout.print("█", .{}) catch {};
        } else {
            stdout.print("░", .{}) catch {};
        }
    }
    
    const percent = @as(u32, @intFromFloat(progress * 100));
    stdout.print("] {d}%", .{percent}) catch {};
}

// ═══════════════════════════════════════════════════════════════════
// Installation Functions
// ═══════════════════════════════════════════════════════════════════

fn createDirectory(path: []const u8) !void {
    fs.cwd().makePath(path) catch |err| {
        if (err != error.PathAlreadyExists) {
            return err;
        }
    };
}

fn installComponent(comp: Component, install_path: []const u8, allocator: std.mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();
    
    stdout.print("\n  📦 Installing {s}...\n", .{comp.name}) catch {};
    stdout.print("     {s}\n", .{comp.description}) catch {};
    
    // Create component directory
    var path_buf: [512]u8 = undefined;
    const comp_path = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ install_path, comp.name }) catch return;
    try createDirectory(comp_path);
    
    // Simulate installation progress
    const steps: u32 = 20;
    var i: u32 = 0;
    while (i <= steps) : (i += 1) {
        drawProgressBar(i, steps, 30);
        std.time.sleep(50_000_000); // 50ms
    }
    
    stdout.print("\n     ✅ Installed: {d} MB\n", .{comp.size_mb}) catch {};
    _ = allocator;
}

fn performInstallation(license: License, install_path: []const u8, allocator: std.mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();
    
    stdout.print("\n═══════════════════════════════════════════\n", .{}) catch {};
    stdout.print("  📱 NULLKIA INSTALLATION\n", .{}) catch {};
    stdout.print("═══════════════════════════════════════════\n", .{}) catch {};
    
    stdout.print("\n  📂 Install Path: {s}\n", .{install_path}) catch {};
    stdout.print("  🔑 License: {s}\n", .{if (license.valid) "Valid" else "Free"}) catch {};
    
    // Create base directory
    try createDirectory(install_path);
    
    // Install selected components
    var total_size: u32 = 0;
    var installed: u32 = 0;
    
    for (components) |comp| {
        if (comp.selected) {
            if (comp.requires_premium and license.tier == .Free) {
                stdout.print("\n  ⚠️  Skipping {s} (Premium required)\n", .{comp.name}) catch {};
                stdout.print("     🔑 Get premium at discord.gg/killers\n", .{}) catch {};
                continue;
            }
            
            try installComponent(comp, install_path, allocator);
            total_size += comp.size_mb;
            installed += 1;
        }
    }
    
    stdout.print("\n═══════════════════════════════════════════\n", .{}) catch {};
    stdout.print("  ✅ INSTALLATION COMPLETE\n", .{}) catch {};
    stdout.print("═══════════════════════════════════════════\n", .{}) catch {};
    stdout.print("\n  📦 Components: {d}\n", .{installed}) catch {};
    stdout.print("  💾 Total Size: {d} MB\n", .{total_size}) catch {};
    stdout.print("  📂 Location: {s}\n", .{install_path}) catch {};
}

// ═══════════════════════════════════════════════════════════════════
// System Detection
// ═══════════════════════════════════════════════════════════════════

const SystemInfo = struct {
    os_name: []const u8,
    arch: []const u8,
    home_dir: []const u8,
};

fn detectSystem() SystemInfo {
    const os_tag = @import("builtin").os.tag;
    const arch_tag = @import("builtin").cpu.arch;
    
    const os_name = switch (os_tag) {
        .linux => "Linux",
        .macos => "macOS",
        .windows => "Windows",
        else => "Unknown",
    };
    
    const arch = switch (arch_tag) {
        .x86_64 => "x86_64",
        .aarch64 => "arm64",
        .arm => "arm",
        else => "unknown",
    };
    
    const home = std.os.getenv("HOME") orelse "/tmp";
    
    return SystemInfo{
        .os_name = os_name,
        .arch = arch,
        .home_dir = home,
    };
}

// ═══════════════════════════════════════════════════════════════════
// Main Entry Point
// ═══════════════════════════════════════════════════════════════════

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    
    // Print banner
    stdout.print("{s}\n", .{BANNER}) catch {};
    stdout.print("  Version {s} | {s}\n", .{ VERSION, AUTHOR }) catch {};
    stdout.print("  🔑 Premium: {s}\n\n", .{DISCORD}) catch {};
    
    // Detect system
    const sys = detectSystem();
    stdout.print("  💻 System: {s} ({s})\n", .{ sys.os_name, sys.arch }) catch {};
    
    // Get license key
    stdout.print("\n  Enter license key (or press Enter for free): ", .{}) catch {};
    
    var key_buf: [256]u8 = undefined;
    const key_len = stdin.readUntilDelimiter(&key_buf, '\n') catch |err| {
        if (err == error.EndOfStream) {
            return;
        }
        return err;
    };
    
    const key = mem.trim(u8, key_buf[0..key_len.len], &[_]u8{ '\r', '\n', ' ' });
    const license = validateLicense(key);
    
    if (license.valid) {
        printSuccess("  ✅ License validated!");
        stdout.print("     Tier: {s}\n", .{@tagName(license.tier)}) catch {};
    } else if (key.len > 0) {
        printWarning("  ⚠️  Invalid license, using free tier");
    }
    
    // Default install path
    var path_buf: [512]u8 = undefined;
    const default_path = std.fmt.bufPrint(&path_buf, "{s}/.nullkia", .{sys.home_dir}) catch "/tmp/.nullkia";
    
    // Confirm installation
    stdout.print("\n  Install to {s}? [Y/n]: ", .{default_path}) catch {};
    
    var confirm_buf: [16]u8 = undefined;
    const confirm_len = stdin.readUntilDelimiter(&confirm_buf, '\n') catch "";
    const confirm = mem.trim(u8, confirm_buf[0..confirm_len.len], &[_]u8{ '\r', '\n', ' ' });
    
    if (confirm.len > 0 and (confirm[0] == 'n' or confirm[0] == 'N')) {
        printInfo("  Installation cancelled.");
        return;
    }
    
    // Perform installation
    try performInstallation(license, default_path, allocator);
    
    // Print footer
    stdout.print("\n─────────────────────────────────────────\n", .{}) catch {};
    stdout.print("  📱 NullKia Zig Installer\n", .{}) catch {};
    stdout.print("  🔑 Premium: discord.gg/killers\n", .{}) catch {};
    stdout.print("  👤 Author: bad-antics\n", .{}) catch {};
    stdout.print("─────────────────────────────────────────\n\n", .{}) catch {};
}
