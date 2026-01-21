// NullKia Firmware Dumper - V Language
// Simple, fast, no dependencies
// @author @AnonAntics
// @discord discord.gg/killers

import os
import time
import json
import net.http
import crypto.md5

const version = '2.0.0'
const banner = '
╭──────────────────────────────────────────╮
│        📱 NULLKIA FIRMWARE DUMPER        │
│       ════════════════════════════       │
│                                          │
│   🔧 Firmware Extraction Tool v2.0.0     │
│   📡 Supports: Samsung/Apple/Xiaomi/+    │
│   💾 Output: Raw IMG, TAR, ZIP           │
│                                          │
│            @AnonAntics | NullSec         │
╰──────────────────────────────────────────╯
'

// Device structure
struct Device {
mut:
    serial      string
    model       string
    manufacturer string
    android_ver string
    build_id    string
    bootloader  string
    baseband    string
    connection  string
    is_rooted   bool
}

// Partition structure
struct Partition {
    name     string
    path     string
    size     u64
    fs_type  string
    writable bool
}

// Firmware dump result
struct DumpResult {
    partition string
    success   bool
    path      string
    size      u64
    md5       string
    duration  time.Duration
}

// License tiers
enum LicenseTier {
    free
    premium
    enterprise
}

// Global state
struct NullKiaState {
mut:
    license_key  string
    license_tier LicenseTier
    output_dir   string
    device       ?Device
    partitions   []Partition
}

// Initialize state
fn new_state() NullKiaState {
    return NullKiaState{
        license_tier: .free
        output_dir: os.join_path(os.home_dir(), '.nullkia', 'dumps')
    }
}

// Print colored output
fn print_banner() {
    println('\x1b[36m${banner}\x1b[0m')
}

fn print_success(msg string) {
    println('\x1b[32m✅ ${msg}\x1b[0m')
}

fn print_error(msg string) {
    println('\x1b[31m❌ ${msg}\x1b[0m')
}

fn print_warning(msg string) {
    println('\x1b[33m⚠️  ${msg}\x1b[0m')
}

fn print_info(msg string) {
    println('\x1b[34mℹ️  ${msg}\x1b[0m')
}

// Execute ADB command
fn adb_exec(args ...string) !string {
    result := os.execute('adb ${args.join(' ')}')
    if result.exit_code != 0 {
        return error('ADB command failed: ${result.output}')
    }
    return result.output.trim_space()
}

// Execute ADB shell command
fn adb_shell(cmd string) !string {
    return adb_exec('shell', cmd)!
}

// Get connected devices
fn get_devices() []Device {
    mut devices := []Device{}
    
    result := os.execute('adb devices -l')
    if result.exit_code != 0 {
        return devices
    }
    
    lines := result.output.split_into_lines()
    for line in lines {
        if line.starts_with('List') || line.trim_space() == '' {
            continue
        }
        
        parts := line.split_any(' \t')
        if parts.len < 2 {
            continue
        }
        
        serial := parts[0]
        
        // Get device properties
        mut device := Device{
            serial: serial
            connection: 'ADB'
        }
        
        // Get model
        if model := adb_exec('-s', serial, 'shell', 'getprop', 'ro.product.model') {
            device.model = model
        }
        
        // Get manufacturer
        if mfr := adb_exec('-s', serial, 'shell', 'getprop', 'ro.product.manufacturer') {
            device.manufacturer = mfr
        }
        
        // Get Android version
        if ver := adb_exec('-s', serial, 'shell', 'getprop', 'ro.build.version.release') {
            device.android_ver = ver
        }
        
        // Get build ID
        if build := adb_exec('-s', serial, 'shell', 'getprop', 'ro.build.id') {
            device.build_id = build
        }
        
        // Get bootloader
        if bl := adb_exec('-s', serial, 'shell', 'getprop', 'ro.bootloader') {
            device.bootloader = bl
        }
        
        // Get baseband
        if bb := adb_exec('-s', serial, 'shell', 'getprop', 'gsm.version.baseband') {
            device.baseband = bb
        }
        
        // Check root
        if root_check := adb_exec('-s', serial, 'shell', 'su', '-c', 'id') {
            device.is_rooted = root_check.contains('uid=0')
        }
        
        devices << device
    }
    
    return devices
}

// Get partition list
fn get_partitions(serial string) []Partition {
    mut partitions := []Partition{}
    
    // Common partition paths
    partition_paths := [
        '/dev/block/by-name',
        '/dev/block/bootdevice/by-name',
        '/dev/block/platform/*/by-name'
    ]
    
    for path in partition_paths {
        if result := adb_exec('-s', serial, 'shell', 'ls', '-la', path) {
            for line in result.split_into_lines() {
                parts := line.split_any(' \t')
                if parts.len < 9 {
                    continue
                }
                
                name := parts[parts.len - 1]
                if name == '.' || name == '..' {
                    continue
                }
                
                // Get actual path (resolve symlink)
                actual_path := if link_idx := line.index('->') {
                    line[link_idx + 3..].trim_space()
                } else {
                    '${path}/${name}'
                }
                
                partitions << Partition{
                    name: name
                    path: actual_path
                    fs_type: 'raw'
                }
            }
            break
        }
    }
    
    // Standard partitions if detection fails
    if partitions.len == 0 {
        standard := ['boot', 'recovery', 'system', 'vendor', 'userdata', 'cache', 'modem', 'efs']
        for name in standard {
            partitions << Partition{
                name: name
                path: '/dev/block/by-name/${name}'
                fs_type: 'raw'
            }
        }
    }
    
    return partitions
}

// Dump single partition
fn dump_partition(serial string, partition Partition, output_dir string) DumpResult {
    start := time.now()
    output_path := os.join_path(output_dir, '${partition.name}.img')
    
    print_info('Dumping ${partition.name}...')
    
    // Try direct dump with root
    result := os.execute('adb -s ${serial} shell "su -c dd if=${partition.path} 2>/dev/null" > "${output_path}"')
    
    mut success := false
    mut file_size := u64(0)
    mut checksum := ''
    
    if result.exit_code == 0 && os.exists(output_path) {
        file_size = u64(os.file_size(output_path))
        if file_size > 0 {
            success = true
            // Calculate MD5
            if data := os.read_bytes(output_path) {
                checksum = md5.sum(data).hex()
            }
        }
    }
    
    if !success {
        // Try adb pull as fallback
        result2 := os.execute('adb -s ${serial} pull ${partition.path} "${output_path}" 2>/dev/null')
        if result2.exit_code == 0 && os.exists(output_path) {
            file_size = u64(os.file_size(output_path))
            if file_size > 0 {
                success = true
                if data := os.read_bytes(output_path) {
                    checksum = md5.sum(data).hex()
                }
            }
        }
    }
    
    duration := time.since(start)
    
    if success {
        print_success('${partition.name}: ${file_size} bytes (${duration.milliseconds()}ms)')
    } else {
        print_warning('${partition.name}: Failed to dump')
        os.rm(output_path) or {}
    }
    
    return DumpResult{
        partition: partition.name
        success: success
        path: output_path
        size: file_size
        md5: checksum
        duration: duration
    }
}

// Full firmware dump
fn dump_firmware(mut state NullKiaState, serial string, partitions []string) []DumpResult {
    mut results := []DumpResult{}
    
    // Create output directory
    timestamp := time.now().format_ss()
    device_dir := os.join_path(state.output_dir, serial, timestamp.replace(':', '-').replace(' ', '_'))
    os.mkdir_all(device_dir) or {
        print_error('Failed to create output directory')
        return results
    }
    
    print_info('Output directory: ${device_dir}')
    println('')
    
    // Get all partitions if not specified
    all_partitions := get_partitions(serial)
    target_partitions := if partitions.len > 0 {
        all_partitions.filter(fn [partitions] (p Partition) bool {
            return p.name in partitions
        })
    } else {
        all_partitions
    }
    
    // Check premium for full dump
    if target_partitions.len > 5 && state.license_tier == .free {
        print_warning('Free tier limited to 5 partitions')
        print_warning('Get premium at discord.gg/killers for full dump')
        println('')
    }
    
    max_partitions := if state.license_tier == .free { 5 } else { target_partitions.len }
    
    for i, partition in target_partitions {
        if i >= max_partitions {
            break
        }
        results << dump_partition(serial, partition, device_dir)
    }
    
    // Write manifest
    manifest := {
        'tool': 'NullKia Firmware Dumper'
        'version': version
        'author': '@AnonAntics'
        'discord': 'discord.gg/killers'
        'device': serial
        'timestamp': timestamp
        'results': results.map(fn (r DumpResult) map[string]json.Any {
            return {
                'partition': json.Any(r.partition)
                'success': json.Any(r.success)
                'size': json.Any(i64(r.size))
                'md5': json.Any(r.md5)
            }
        })
    }
    
    os.write_file(os.join_path(device_dir, 'manifest.json'), json.encode_pretty(manifest)) or {}
    
    return results
}

// Validate license
fn validate_license(key string) LicenseTier {
    if key.len != 24 || !key.starts_with('NKIA-') {
        return .free
    }
    
    parts := key.split('-')
    if parts.len != 5 {
        return .free
    }
    
    tier_code := parts[1][0..2]
    return match tier_code {
        'PR' { LicenseTier.premium }
        'EN' { LicenseTier.enterprise }
        else { LicenseTier.free }
    }
}

// Interactive menu
fn run_interactive(mut state NullKiaState) {
    print_banner()
    
    // Check for devices
    devices := get_devices()
    
    if devices.len == 0 {
        print_error('No devices found. Connect a device via USB and enable USB debugging.')
        return
    }
    
    println('\n📱 Connected Devices:\n')
    for i, device in devices {
        root_status := if device.is_rooted { '🔓 Rooted' } else { '🔒 Not rooted' }
        println('  [${i + 1}] ${device.manufacturer} ${device.model}')
        println('      Serial: ${device.serial}')
        println('      Android: ${device.android_ver} | Build: ${device.build_id}')
        println('      Status: ${root_status}')
        println('')
    }
    
    // Select device
    print('Select device [1-${devices.len}]: ')
    input := os.get_line()
    idx := input.int() - 1
    
    if idx < 0 || idx >= devices.len {
        print_error('Invalid selection')
        return
    }
    
    device := devices[idx]
    state.device = device
    
    println('\n📦 Available Operations:\n')
    println('  [1] Dump all partitions')
    println('  [2] Dump boot/recovery only')
    println('  [3] Dump system/vendor only')
    println('  [4] List partitions')
    println('  [5] Device info')
    println('  [0] Exit')
    
    print('\nSelect operation: ')
    op := os.get_line().int()
    
    match op {
        1 {
            results := dump_firmware(mut state, device.serial, [])
            println('\n📊 Dump Summary:')
            println('   Total: ${results.len}')
            println('   Success: ${results.filter(fn (r DumpResult) bool { return r.success }).len}')
            println('   Failed: ${results.filter(fn (r DumpResult) bool { return !r.success }).len}')
        }
        2 {
            dump_firmware(mut state, device.serial, ['boot', 'recovery'])
        }
        3 {
            dump_firmware(mut state, device.serial, ['system', 'vendor'])
        }
        4 {
            partitions := get_partitions(device.serial)
            println('\n📁 Partitions (${partitions.len}):')
            for p in partitions {
                println('   ${p.name}: ${p.path}')
            }
        }
        5 {
            println('\n📱 Device Information:')
            println('   Manufacturer: ${device.manufacturer}')
            println('   Model: ${device.model}')
            println('   Serial: ${device.serial}')
            println('   Android: ${device.android_ver}')
            println('   Build: ${device.build_id}')
            println('   Bootloader: ${device.bootloader}')
            println('   Baseband: ${device.baseband}')
            println('   Rooted: ${device.is_rooted}')
        }
        else {
            println('Exiting...')
        }
    }
}

// Main entry point
fn main() {
    mut state := new_state()
    
    // Parse command line args
    args := os.args[1..]
    
    if args.len > 0 {
        match args[0] {
            '-k', '--key' {
                if args.len > 1 {
                    state.license_key = args[1]
                    state.license_tier = validate_license(args[1])
                    print_info('License: ${state.license_tier}')
                }
            }
            '-h', '--help' {
                println('NullKia Firmware Dumper v${version}')
                println('@AnonAntics | discord.gg/killers')
                println('')
                println('Usage: firmware [options]')
                println('')
                println('Options:')
                println('  -k, --key KEY    License key')
                println('  -o, --output DIR Output directory')
                println('  -h, --help       Show help')
                println('  -v, --version    Show version')
                return
            }
            '-v', '--version' {
                println('NullKia Firmware Dumper v${version}')
                return
            }
            '-o', '--output' {
                if args.len > 1 {
                    state.output_dir = args[1]
                }
            }
            else {}
        }
    }
    
    run_interactive(mut state)
    
    println('\n─────────────────────────────────────────')
    println('📱 NullKia Firmware Dumper')
    println('🔑 Premium: discord.gg/killers')
    println('🐦 Twitter: @AnonAntics')
    println('─────────────────────────────────────────')
}
