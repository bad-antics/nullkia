// NullKia Low-Level Tools - Odin Language
// Data-oriented systems programming
// @author bad-antics
// @discord discord.gg/killers

package nullkia_lowlevel

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:mem"
import "core:time"
import "core:encoding/json"
import "core:path/filepath"
import "core:slice"
import "core:c/libc"

VERSION :: "2.0.0"
AUTHOR :: "bad-antics"
DISCORD :: "discord.gg/killers"

BANNER :: `
╭──────────────────────────────────────────╮
│        📱 NULLKIA LOW-LEVEL TOOLS        │
│       ════════════════════════════       │
│                                          │
│   🔧 Low-Level Device Analysis           │
│   📡 Bootloader / Fastboot Interface     │
│   💾 Partition Table Analysis            │
│                                          │
│            bad-antics | NullSec         │
╰──────────────────────────────────────────╯
`

// ANSI Colors
Color :: enum {
    Reset,
    Red,
    Green,
    Yellow,
    Blue,
    Cyan,
}

get_color_code :: proc(c: Color) -> string {
    switch c {
    case .Reset:  return "\x1b[0m"
    case .Red:    return "\x1b[31m"
    case .Green:  return "\x1b[32m"
    case .Yellow: return "\x1b[33m"
    case .Blue:   return "\x1b[34m"
    case .Cyan:   return "\x1b[36m"
    }
    return ""
}

print_colored :: proc(c: Color, msg: string) {
    fmt.printf("%s%s%s\n", get_color_code(c), msg, get_color_code(.Reset))
}

print_success :: proc(msg: string) {
    print_colored(.Green, strings.concatenate({"✅ ", msg}))
}

print_error :: proc(msg: string) {
    print_colored(.Red, strings.concatenate({"❌ ", msg}))
}

print_warning :: proc(msg: string) {
    print_colored(.Yellow, strings.concatenate({"⚠️  ", msg}))
}

print_info :: proc(msg: string) {
    print_colored(.Blue, strings.concatenate({"ℹ️  ", msg}))
}

// License system
License_Tier :: enum {
    Free,
    Premium,
    Enterprise,
}

License :: struct {
    key:   string,
    tier:  License_Tier,
    valid: bool,
}

validate_license :: proc(key: string) -> License {
    license := License{key = key, tier = .Free, valid = false}
    
    if len(key) != 24 || !strings.has_prefix(key, "NKIA-") {
        return license
    }
    
    parts := strings.split(key, "-")
    if len(parts) != 5 {
        return license
    }
    
    tier_code := parts[1][:2] if len(parts[1]) >= 2 else ""
    
    switch tier_code {
    case "PR":
        license.tier = .Premium
    case "EN":
        license.tier = .Enterprise
    }
    
    license.valid = true
    return license
}

is_premium :: proc(license: License) -> bool {
    return license.valid && license.tier != .Free
}

// Device structures
Device_Mode :: enum {
    Unknown,
    ADB,
    Fastboot,
    Recovery,
    EDL,
}

Device :: struct {
    serial:       string,
    model:        string,
    manufacturer: string,
    mode:         Device_Mode,
    bootloader_unlocked: bool,
}

Partition :: struct {
    name:   string,
    start:  u64,
    size:   u64,
    type_:  string,
    flags:  string,
}

// Execute command and return output
exec_command :: proc(cmd: string) -> (output: string, success: bool) {
    // Use popen for command execution
    fp := libc.popen(strings.clone_to_cstring(cmd), "r")
    if fp == nil {
        return "", false
    }
    defer libc.pclose(fp)
    
    builder: strings.Builder
    strings.builder_init(&builder)
    
    buf: [1024]byte
    for {
        n := libc.fread(&buf[0], 1, len(buf), fp)
        if n <= 0 do break
        strings.write_bytes(&builder, buf[:n])
    }
    
    return strings.to_string(builder), true
}

// Get devices in fastboot mode
get_fastboot_devices :: proc() -> []Device {
    devices: [dynamic]Device
    
    output, ok := exec_command("fastboot devices")
    if !ok do return devices[:]
    
    lines := strings.split(output, "\n")
    for line in lines {
        line := strings.trim_space(line)
        if len(line) == 0 do continue
        
        parts := strings.split(line, "\t")
        if len(parts) < 2 do continue
        
        serial := parts[0]
        
        // Get device info
        model_out, _ := exec_command(fmt.tprintf("fastboot -s %s getvar product 2>&1", serial))
        
        device := Device{
            serial = serial,
            mode = .Fastboot,
        }
        
        // Parse model
        if strings.contains(model_out, "product:") {
            model_lines := strings.split(model_out, "\n")
            for ml in model_lines {
                if strings.has_prefix(ml, "product:") {
                    device.model = strings.trim_space(ml[8:])
                    break
                }
            }
        }
        
        // Check bootloader status
        unlock_out, _ := exec_command(fmt.tprintf("fastboot -s %s getvar unlocked 2>&1", serial))
        device.bootloader_unlocked = strings.contains(unlock_out, "yes")
        
        append(&devices, device)
    }
    
    return devices[:]
}

// Get devices in ADB mode
get_adb_devices :: proc() -> []Device {
    devices: [dynamic]Device
    
    output, ok := exec_command("adb devices -l")
    if !ok do return devices[:]
    
    lines := strings.split(output, "\n")
    for line in lines {
        line := strings.trim_space(line)
        if strings.has_prefix(line, "List") || len(line) == 0 do continue
        
        parts := strings.split(line, " ")
        if len(parts) < 2 do continue
        
        serial := parts[0]
        
        device := Device{
            serial = serial,
            mode = .ADB,
        }
        
        // Get device info
        model_out, _ := exec_command(fmt.tprintf("adb -s %s shell getprop ro.product.model", serial))
        device.model = strings.trim_space(model_out)
        
        mfr_out, _ := exec_command(fmt.tprintf("adb -s %s shell getprop ro.product.manufacturer", serial))
        device.manufacturer = strings.trim_space(mfr_out)
        
        append(&devices, device)
    }
    
    return devices[:]
}

// Get partition table
get_partitions :: proc(serial: string, mode: Device_Mode) -> []Partition {
    partitions: [dynamic]Partition
    
    if mode == .Fastboot {
        // Try to get partition list via fastboot
        common_partitions := []string{
            "boot", "recovery", "system", "vendor", "userdata",
            "cache", "modem", "persist", "efs", "metadata",
            "dtbo", "vbmeta", "aboot", "abl", "xbl",
        }
        
        for part_name in common_partitions {
            size_out, ok := exec_command(fmt.tprintf(
                "fastboot -s %s getvar partition-size:%s 2>&1", 
                serial, part_name))
            
            if !ok do continue
            
            // Parse size
            if strings.contains(size_out, "FAILED") do continue
            
            partition := Partition{
                name = part_name,
            }
            
            // Try to extract size
            lines := strings.split(size_out, "\n")
            for line in lines {
                if strings.has_prefix(line, "partition-size:") {
                    // Format: partition-size:boot: 0x4000000
                    colon_idx := strings.last_index(line, ":")
                    if colon_idx > 0 {
                        size_str := strings.trim_space(line[colon_idx+1:])
                        if strings.has_prefix(size_str, "0x") {
                            partition.size = strconv.parse_u64(size_str[2:], 16) or_else 0
                        } else {
                            partition.size = strconv.parse_u64(size_str, 10) or_else 0
                        }
                    }
                }
            }
            
            append(&partitions, partition)
        }
    } else if mode == .ADB {
        // Get from /proc/partitions or by-name
        output, ok := exec_command(fmt.tprintf(
            "adb -s %s shell su -c 'ls -la /dev/block/by-name/'", serial))
        
        if ok {
            lines := strings.split(output, "\n")
            for line in lines {
                line := strings.trim_space(line)
                if len(line) == 0 do continue
                
                // Parse symlink line
                // Format: lrwxrwxrwx ... boot -> /dev/block/mmcblk0p41
                parts := strings.split(line, " -> ")
                if len(parts) != 2 do continue
                
                name_parts := strings.split(parts[0], " ")
                if len(name_parts) == 0 do continue
                
                partition := Partition{
                    name = name_parts[len(name_parts)-1],
                }
                
                append(&partitions, partition)
            }
        }
    }
    
    return partitions[:]
}

// Flash partition
flash_partition :: proc(serial: string, part_name: string, image_path: string, license: License) -> bool {
    if !is_premium(license) {
        print_warning("Flashing requires premium license")
        print_warning("Get premium at discord.gg/killers")
        return false
    }
    
    if !os.exists(image_path) {
        print_error(fmt.tprintf("Image file not found: %s", image_path))
        return false
    }
    
    print_info(fmt.tprintf("Flashing %s to %s...", image_path, part_name))
    
    output, ok := exec_command(fmt.tprintf(
        "fastboot -s %s flash %s %s 2>&1", serial, part_name, image_path))
    
    if ok && !strings.contains(output, "FAILED") {
        print_success(fmt.tprintf("Successfully flashed %s", part_name))
        return true
    }
    
    print_error(fmt.tprintf("Failed to flash: %s", output))
    return false
}

// Unlock bootloader
unlock_bootloader :: proc(serial: string, license: License) -> bool {
    if !is_premium(license) {
        print_warning("Bootloader unlock requires premium license")
        return false
    }
    
    print_warning("⚠️  BOOTLOADER UNLOCK WILL WIPE ALL DATA! ⚠️")
    print_warning("This action is irreversible.")
    
    fmt.print("Type 'UNLOCK' to continue: ")
    confirm: [64]byte
    n, _ := os.read(os.stdin, confirm[:])
    
    if strings.trim_space(string(confirm[:n])) != "UNLOCK" {
        print_info("Unlock cancelled")
        return false
    }
    
    print_info("Unlocking bootloader...")
    
    // Try OEM unlock first
    output, _ := exec_command(fmt.tprintf("fastboot -s %s oem unlock 2>&1", serial))
    
    if strings.contains(output, "OKAY") {
        print_success("Bootloader unlocked successfully")
        return true
    }
    
    // Try flashing unlock
    output, _ = exec_command(fmt.tprintf("fastboot -s %s flashing unlock 2>&1", serial))
    
    if strings.contains(output, "OKAY") {
        print_success("Bootloader unlocked successfully")
        return true
    }
    
    print_error(fmt.tprintf("Failed to unlock: %s", output))
    return false
}

// Reboot device
reboot_device :: proc(serial: string, mode: Device_Mode, target: string) {
    print_info(fmt.tprintf("Rebooting device to %s...", target))
    
    cmd: string
    if mode == .Fastboot {
        switch target {
        case "bootloader", "fastboot":
            cmd = fmt.tprintf("fastboot -s %s reboot bootloader", serial)
        case "recovery":
            cmd = fmt.tprintf("fastboot -s %s reboot recovery", serial)
        case "system", "":
            cmd = fmt.tprintf("fastboot -s %s reboot", serial)
        case "edl", "download":
            cmd = fmt.tprintf("fastboot -s %s oem edl", serial)
        }
    } else {
        switch target {
        case "bootloader", "fastboot":
            cmd = fmt.tprintf("adb -s %s reboot bootloader", serial)
        case "recovery":
            cmd = fmt.tprintf("adb -s %s reboot recovery", serial)
        case "system", "":
            cmd = fmt.tprintf("adb -s %s reboot", serial)
        case "edl", "download":
            cmd = fmt.tprintf("adb -s %s reboot edl", serial)
        }
    }
    
    exec_command(cmd)
    print_success("Reboot command sent")
}

// Dump partition
dump_partition :: proc(serial: string, part_name: string, output_dir: string, license: License) -> bool {
    if !is_premium(license) {
        print_warning("Partition dump requires premium license")
        return false
    }
    
    print_info(fmt.tprintf("Dumping partition %s...", part_name))
    
    timestamp := time.now()
    output_file := filepath.join({output_dir, fmt.tprintf("%s_%v.img", part_name, timestamp._nsec)})
    
    // First find the actual block device
    dev_out, ok := exec_command(fmt.tprintf(
        "adb -s %s shell su -c 'readlink -f /dev/block/by-name/%s'", serial, part_name))
    
    if !ok || len(strings.trim_space(dev_out)) == 0 {
        print_error("Could not find partition device")
        return false
    }
    
    dev_path := strings.trim_space(dev_out)
    
    // Dump using dd
    cmd := fmt.tprintf("adb -s %s shell su -c 'dd if=%s 2>/dev/null' > %s", 
                       serial, dev_path, output_file)
    
    output, success := exec_command(cmd)
    
    if success {
        print_success(fmt.tprintf("Dumped to %s", output_file))
        return true
    }
    
    print_error(fmt.tprintf("Failed to dump: %s", output))
    return false
}

// Interactive menu
run_interactive :: proc(license: License) {
    print_colored(.Cyan, BANNER)
    
    // Get all devices
    fastboot_devs := get_fastboot_devices()
    adb_devs := get_adb_devices()
    
    all_devices: [dynamic]Device
    for d in fastboot_devs do append(&all_devices, d)
    for d in adb_devs do append(&all_devices, d)
    
    if len(all_devices) == 0 {
        print_error("No devices connected")
        return
    }
    
    fmt.println("\n📱 Connected Devices:\n")
    for d, i in all_devices {
        mode_str: string
        switch d.mode {
        case .Fastboot: mode_str = "⚡ Fastboot"
        case .ADB:      mode_str = "📱 ADB"
        case .Recovery: mode_str = "🔧 Recovery"
        case .EDL:      mode_str = "🔌 EDL"
        case .Unknown:  mode_str = "❓ Unknown"
        }
        
        fmt.printf("  [%d] %s %s\n", i+1, d.manufacturer, d.model)
        fmt.printf("      Serial: %s\n", d.serial)
        fmt.printf("      Mode: %s\n", mode_str)
        if d.mode == .Fastboot {
            unlock_str := d.bootloader_unlocked ? "🔓 Unlocked" : "🔒 Locked"
            fmt.printf("      Bootloader: %s\n", unlock_str)
        }
        fmt.println()
    }
    
    fmt.print("Select device [1-N]: ")
    idx_buf: [16]byte
    n, _ := os.read(os.stdin, idx_buf[:])
    idx := strconv.parse_int(strings.trim_space(string(idx_buf[:n]))) or_else 0
    
    if idx < 1 || idx > len(all_devices) {
        print_error("Invalid selection")
        return
    }
    
    device := all_devices[idx-1]
    
    fmt.println("\n📦 Operations:\n")
    fmt.println("  [1] List partitions")
    fmt.println("  [2] Dump partition (Premium)")
    fmt.println("  [3] Flash image (Premium)")
    fmt.println("  [4] Unlock bootloader (Premium)")
    fmt.println("  [5] Reboot device")
    fmt.println("  [6] Device variables")
    fmt.println("  [0] Exit")
    
    fmt.print("\nSelect operation: ")
    op_buf: [16]byte
    n, _ = os.read(os.stdin, op_buf[:])
    op := strconv.parse_int(strings.trim_space(string(op_buf[:n]))) or_else -1
    
    switch op {
    case 1:
        partitions := get_partitions(device.serial, device.mode)
        fmt.println("\n📋 Partitions:\n")
        for p in partitions {
            if p.size > 0 {
                fmt.printf("  %s: %d bytes (%.2f MB)\n", p.name, p.size, f64(p.size) / 1024 / 1024)
            } else {
                fmt.printf("  %s\n", p.name)
            }
        }
        
    case 2:
        fmt.print("Enter partition name: ")
        part_buf: [64]byte
        n, _ := os.read(os.stdin, part_buf[:])
        part_name := strings.trim_space(string(part_buf[:n]))
        
        home := os.get_env("HOME")
        output_dir := filepath.join({home, ".nullkia", "dumps"})
        os.make_directory(output_dir)
        
        dump_partition(device.serial, part_name, output_dir, license)
        
    case 3:
        fmt.print("Enter partition name: ")
        part_buf: [64]byte
        n, _ := os.read(os.stdin, part_buf[:])
        part_name := strings.trim_space(string(part_buf[:n]))
        
        fmt.print("Enter image path: ")
        img_buf: [256]byte
        n, _ = os.read(os.stdin, img_buf[:])
        img_path := strings.trim_space(string(img_buf[:n]))
        
        flash_partition(device.serial, part_name, img_path, license)
        
    case 4:
        if device.mode != .Fastboot {
            print_error("Device must be in fastboot mode")
        } else {
            unlock_bootloader(device.serial, license)
        }
        
    case 5:
        fmt.println("\nReboot targets:")
        fmt.println("  [1] System")
        fmt.println("  [2] Bootloader")
        fmt.println("  [3] Recovery")
        fmt.println("  [4] EDL/Download")
        
        fmt.print("Select target: ")
        target_buf: [16]byte
        n, _ := os.read(os.stdin, target_buf[:])
        target_op := strconv.parse_int(strings.trim_space(string(target_buf[:n]))) or_else 0
        
        target: string
        switch target_op {
        case 1: target = "system"
        case 2: target = "bootloader"
        case 3: target = "recovery"
        case 4: target = "edl"
        }
        
        reboot_device(device.serial, device.mode, target)
        
    case 6:
        if device.mode == .Fastboot {
            vars := []string{
                "product", "variant", "version", "serialno",
                "secure", "unlocked", "off-mode-charge", "slot-count",
                "current-slot", "max-download-size",
            }
            
            fmt.println("\n📊 Device Variables:\n")
            for v in vars {
                out, _ := exec_command(fmt.tprintf("fastboot -s %s getvar %s 2>&1", device.serial, v))
                lines := strings.split(out, "\n")
                for line in lines {
                    if strings.has_prefix(line, v) {
                        fmt.printf("  %s\n", line)
                        break
                    }
                }
            }
        } else {
            fmt.println("\nDevice variables only available in fastboot mode")
        }
        
    case 0:
        fmt.println("Exiting...")
    }
    
    fmt.println("\n─────────────────────────────────────────")
    fmt.println("📱 NullKia Low-Level Tools")
    fmt.println("🔑 Premium: discord.gg/killers")
    fmt.println("🐦 GitHub: bad-antics")
    fmt.println("─────────────────────────────────────────")
}

main :: proc() {
    license := License{}
    
    args := os.args[1:]
    i := 0
    for i < len(args) {
        if args[i] == "-k" || args[i] == "--key" {
            if i + 1 < len(args) {
                license = validate_license(args[i+1])
                print_info(fmt.tprintf("License tier: %v", license.tier))
                i += 1
            }
        } else if args[i] == "-h" || args[i] == "--help" {
            fmt.printf("NullKia Low-Level Tools v%s\n", VERSION)
            fmt.printf("%s | %s\n\n", AUTHOR, DISCORD)
            fmt.println("Usage: lowlevel [options]")
            fmt.println()
            fmt.println("Options:")
            fmt.println("  -k, --key KEY    License key")
            fmt.println("  -h, --help       Show help")
            fmt.println("  -v, --version    Show version")
            return
        } else if args[i] == "-v" || args[i] == "--version" {
            fmt.printf("NullKia Low-Level Tools v%s\n", VERSION)
            return
        }
        i += 1
    }
    
    run_interactive(license)
}
