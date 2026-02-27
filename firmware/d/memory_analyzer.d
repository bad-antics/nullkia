// NullKia Memory Analyzer - D Language
// Safe systems programming with GC
// @author bad-antics
// @twitter x.com/AnonAntics

module memory_analyzer;

import std.stdio;
import std.string;
import std.conv;
import std.file;
import std.path;
import std.process;
import std.json;
import std.datetime;
import std.algorithm;
import std.array;
import std.format;
import core.stdc.stdlib;

enum VERSION = "2.0.0";

immutable string BANNER = `
╭──────────────────────────────────────────╮
│        📱 NULLKIA MEMORY ANALYZER        │
│       ════════════════════════════       │
│                                          │
│   🔧 Memory Analysis Tool v2.0.0         │
│   📡 RAM Dump & Analysis                 │
│   💾 Process Memory Inspection           │
│                                          │
│            bad-antics | NullSec         │
╰──────────────────────────────────────────╯
`;

// License management
enum LicenseTier { Free, Premium, Enterprise }

struct License {
    string key;
    LicenseTier tier = LicenseTier.Free;
    bool valid = false;
    
    this(string licenseKey) {
        key = licenseKey;
        validate();
    }
    
    void validate() {
        if (key.length != 24 || !key.startsWith("NKIA-")) {
            tier = LicenseTier.Free;
            valid = false;
            return;
        }
        
        auto parts = key.split("-");
        if (parts.length != 5) {
            tier = LicenseTier.Free;
            valid = false;
            return;
        }
        
        string tierCode = parts[1][0..2];
        switch (tierCode) {
            case "PR": tier = LicenseTier.Premium; break;
            case "EN": tier = LicenseTier.Enterprise; break;
            default: tier = LicenseTier.Free;
        }
        valid = true;
    }
    
    bool isPremium() {
        return valid && tier != LicenseTier.Free;
    }
}

// Memory region structure
struct MemoryRegion {
    ulong start;
    ulong end;
    string permissions;
    string name;
    ulong size;
    
    string toString() const {
        return format("0x%016X-0x%016X %s %s (%d bytes)", 
                     start, end, permissions, name, size);
    }
}

// Process structure
struct ProcessInfo {
    int pid;
    string name;
    string cmdline;
    string user;
    ulong memUsage;
    MemoryRegion[] regions;
}

// Device connection
struct Device {
    string serial;
    string model;
    string manufacturer;
    bool isRooted;
}

// Terminal colors
void printColored(string color, string msg) {
    string code;
    switch (color) {
        case "red": code = "\x1b[31m"; break;
        case "green": code = "\x1b[32m"; break;
        case "yellow": code = "\x1b[33m"; break;
        case "blue": code = "\x1b[34m"; break;
        case "cyan": code = "\x1b[36m"; break;
        default: code = "\x1b[0m";
    }
    writeln(code, msg, "\x1b[0m");
}

void printSuccess(string msg) { printColored("green", "✅ " ~ msg); }
void printError(string msg) { printColored("red", "❌ " ~ msg); }
void printWarning(string msg) { printColored("yellow", "⚠️  " ~ msg); }
void printInfo(string msg) { printColored("blue", "ℹ️  " ~ msg); }

// Execute ADB command
string adbExec(string[] args...) {
    try {
        auto result = execute(["adb"] ~ args.dup);
        if (result.status == 0) {
            return result.output.strip();
        }
    } catch (Exception e) {
        // Ignore
    }
    return "";
}

// Get connected devices
Device[] getDevices() {
    Device[] devices;
    
    string output = adbExec("devices", "-l");
    foreach (line; output.lineSplitter) {
        if (line.startsWith("List") || line.strip().length == 0)
            continue;
        
        auto parts = line.split();
        if (parts.length < 2)
            continue;
        
        string serial = parts[0];
        
        Device device;
        device.serial = serial;
        device.model = adbExec("-s", serial, "shell", "getprop", "ro.product.model");
        device.manufacturer = adbExec("-s", serial, "shell", "getprop", "ro.product.manufacturer");
        
        // Check root
        string rootCheck = adbExec("-s", serial, "shell", "su", "-c", "id");
        device.isRooted = rootCheck.canFind("uid=0");
        
        devices ~= device;
    }
    
    return devices;
}

// Get process list from device
ProcessInfo[] getProcessList(string serial) {
    ProcessInfo[] processes;
    
    string output = adbExec("-s", serial, "shell", "ps", "-A", "-o", "PID,USER,RSS,NAME");
    
    foreach (line; output.lineSplitter) {
        if (line.startsWith("PID") || line.strip().length == 0)
            continue;
        
        auto parts = line.split();
        if (parts.length < 4)
            continue;
        
        try {
            ProcessInfo proc;
            proc.pid = to!int(parts[0]);
            proc.user = parts[1];
            proc.memUsage = to!ulong(parts[2]) * 1024; // KB to bytes
            proc.name = parts[3];
            
            // Get cmdline
            proc.cmdline = adbExec("-s", serial, "shell", "cat", 
                                   format("/proc/%d/cmdline", proc.pid));
            
            processes ~= proc;
        } catch (Exception e) {
            continue;
        }
    }
    
    // Sort by memory usage
    processes.sort!((a, b) => a.memUsage > b.memUsage);
    
    return processes;
}

// Get memory maps for a process
MemoryRegion[] getMemoryMaps(string serial, int pid) {
    MemoryRegion[] regions;
    
    string output = adbExec("-s", serial, "shell", "su", "-c",
                           format("cat /proc/%d/maps", pid));
    
    foreach (line; output.lineSplitter) {
        if (line.strip().length == 0)
            continue;
        
        // Parse memory map line
        // Format: address perms offset dev inode pathname
        auto parts = line.split();
        if (parts.length < 5)
            continue;
        
        try {
            auto addrParts = parts[0].split("-");
            if (addrParts.length != 2)
                continue;
            
            MemoryRegion region;
            region.start = to!ulong(addrParts[0], 16);
            region.end = to!ulong(addrParts[1], 16);
            region.permissions = parts[1];
            region.name = parts.length > 5 ? parts[5] : "[anon]";
            region.size = region.end - region.start;
            
            regions ~= region;
        } catch (Exception e) {
            continue;
        }
    }
    
    return regions;
}

// Dump process memory
bool dumpProcessMemory(string serial, int pid, string outputPath, License license) {
    if (!license.isPremium()) {
        printWarning("Memory dump requires premium license");
        printWarning("Get premium at x.com/AnonAntics");
        return false;
    }
    
    printInfo(format("Dumping memory for PID %d...", pid));
    
    // Get memory regions
    auto regions = getMemoryMaps(serial, pid);
    
    if (regions.length == 0) {
        printError("No memory regions found. Device may not be rooted.");
        return false;
    }
    
    // Create output directory
    string dumpDir = buildPath(outputPath, format("pid_%d_%s", pid, 
                              Clock.currTime().toISOString().replace(":", "-")));
    mkdirRecurse(dumpDir);
    
    int dumped = 0;
    ulong totalSize = 0;
    
    foreach (region; regions) {
        // Only dump readable regions
        if (!region.permissions.startsWith("r"))
            continue;
        
        // Skip very large regions
        if (region.size > 100 * 1024 * 1024)  // 100MB limit
            continue;
        
        string regionFile = buildPath(dumpDir, 
                                     format("%016x_%016x_%s.bin", 
                                           region.start, region.end,
                                           region.name.replace("/", "_")));
        
        // Dump using dd
        string cmd = format("su -c 'dd if=/proc/%d/mem bs=1 skip=%d count=%d 2>/dev/null'",
                           pid, region.start, region.size);
        
        auto result = execute(["adb", "-s", serial, "shell", cmd]);
        
        if (result.status == 0 && result.output.length > 0) {
            std.file.write(regionFile, result.output);
            dumped++;
            totalSize += result.output.length;
        }
    }
    
    // Write manifest
    JSONValue manifest = [
        "tool": "NullKia Memory Analyzer",
        "version": VERSION,
        "author": "bad-antics",
        "discord": "x.com/AnonAntics",
        "pid": pid,
        "regions_total": regions.length,
        "regions_dumped": dumped,
        "total_size": totalSize
    ];
    
    std.file.write(buildPath(dumpDir, "manifest.json"), manifest.toPrettyString());
    
    printSuccess(format("Dumped %d regions (%d bytes) to %s", dumped, totalSize, dumpDir));
    return true;
}

// Search memory for pattern
struct SearchResult {
    ulong address;
    string context;
}

SearchResult[] searchMemory(string serial, int pid, string pattern, License license) {
    SearchResult[] results;
    
    if (!license.isPremium()) {
        printWarning("Memory search requires premium license");
        return results;
    }
    
    printInfo(format("Searching for '%s' in PID %d...", pattern, pid));
    
    auto regions = getMemoryMaps(serial, pid);
    
    foreach (region; regions) {
        if (!region.permissions.startsWith("r"))
            continue;
        
        if (region.size > 10 * 1024 * 1024)  // 10MB limit for search
            continue;
        
        // Read region
        string cmd = format("su -c 'dd if=/proc/%d/mem bs=1 skip=%d count=%d 2>/dev/null'",
                           pid, region.start, region.size);
        
        auto result = execute(["adb", "-s", serial, "shell", cmd]);
        
        if (result.status == 0 && result.output.length > 0) {
            // Search for pattern
            auto data = cast(ubyte[])result.output;
            auto searchBytes = cast(ubyte[])pattern;
            
            for (size_t i = 0; i <= data.length - searchBytes.length; i++) {
                if (data[i .. i + searchBytes.length] == searchBytes) {
                    SearchResult sr;
                    sr.address = region.start + i;
                    
                    // Get context
                    size_t ctxStart = i > 16 ? i - 16 : 0;
                    size_t ctxEnd = i + searchBytes.length + 16;
                    if (ctxEnd > data.length) ctxEnd = data.length;
                    
                    sr.context = format("%(%02X %)", data[ctxStart .. ctxEnd]);
                    results ~= sr;
                }
            }
        }
    }
    
    printSuccess(format("Found %d matches", results.length));
    return results;
}

// Interactive menu
void runInteractive(License license) {
    printColored("cyan", BANNER);
    
    auto devices = getDevices();
    
    if (devices.length == 0) {
        printError("No devices connected");
        return;
    }
    
    writeln("\n📱 Connected Devices:\n");
    foreach (i, device; devices) {
        string rootStatus = device.isRooted ? "🔓 Rooted" : "🔒 Not rooted";
        writefln("  [%d] %s %s", i + 1, device.manufacturer, device.model);
        writefln("      Serial: %s", device.serial);
        writefln("      Status: %s\n", rootStatus);
    }
    
    write("Select device [1-", devices.length, "]: ");
    int idx = to!int(readln().strip()) - 1;
    
    if (idx < 0 || idx >= devices.length) {
        printError("Invalid selection");
        return;
    }
    
    auto device = devices[idx];
    
    if (!device.isRooted) {
        printWarning("Device is not rooted. Some features may not work.");
    }
    
    writeln("\n📦 Operations:\n");
    writeln("  [1] List processes");
    writeln("  [2] Memory map for process");
    writeln("  [3] Dump process memory (Premium)");
    writeln("  [4] Search memory (Premium)");
    writeln("  [5] System memory info");
    writeln("  [0] Exit");
    
    write("\nSelect operation: ");
    int op = to!int(readln().strip());
    
    switch (op) {
        case 1:
            auto procs = getProcessList(device.serial);
            writeln("\n📋 Processes (top 20 by memory):\n");
            foreach (i, proc; procs[0 .. min(20, procs.length)]) {
                writefln("  [%d] PID %d: %s (%s KB)", i + 1, proc.pid, proc.name, proc.memUsage / 1024);
            }
            break;
            
        case 2:
            write("Enter PID: ");
            int pid = to!int(readln().strip());
            auto regions = getMemoryMaps(device.serial, pid);
            writefln("\n📍 Memory regions for PID %d (%d total):\n", pid, regions.length);
            foreach (region; regions[0 .. min(30, regions.length)]) {
                writeln("  ", region.toString());
            }
            break;
            
        case 3:
            write("Enter PID: ");
            int pid = to!int(readln().strip());
            string outputDir = buildPath(expandTilde("~"), ".nullkia", "dumps");
            dumpProcessMemory(device.serial, pid, outputDir, license);
            break;
            
        case 4:
            write("Enter PID: ");
            int pid = to!int(readln().strip());
            write("Enter search pattern: ");
            string pattern = readln().strip();
            auto results = searchMemory(device.serial, pid, pattern, license);
            writeln("\n🔍 Search Results:\n");
            foreach (r; results[0 .. min(20, results.length)]) {
                writefln("  0x%016X: %s", r.address, r.context);
            }
            break;
            
        case 5:
            string memInfo = adbExec("-s", device.serial, "shell", "cat", "/proc/meminfo");
            writeln("\n💾 Memory Info:\n");
            writeln(memInfo);
            break;
            
        default:
            writeln("Exiting...");
    }
    
    writeln("\n─────────────────────────────────────────");
    writeln("📱 NullKia Memory Analyzer");
    writeln("🔑 Premium: x.com/AnonAntics");
    writeln("🐦 GitHub: bad-antics");
    writeln("─────────────────────────────────────────");
}

void main(string[] args) {
    License license;
    
    // Parse args
    for (int i = 1; i < args.length; i++) {
        if ((args[i] == "-k" || args[i] == "--key") && i + 1 < args.length) {
            license = License(args[i + 1]);
            printInfo(format("License: %s", license.tier));
            i++;
        } else if (args[i] == "-h" || args[i] == "--help") {
            writeln("NullKia Memory Analyzer v", VERSION);
            writeln("bad-antics | x.com/AnonAntics");
            writeln();
            writeln("Usage: memory_analyzer [options]");
            writeln();
            writeln("Options:");
            writeln("  -k, --key KEY    License key");
            writeln("  -h, --help       Show help");
            writeln("  -v, --version    Show version");
            return;
        } else if (args[i] == "-v" || args[i] == "--version") {
            writeln("NullKia Memory Analyzer v", VERSION);
            return;
        }
    }
    
    runInteractive(license);
}
