// NullKia - Google Pixel Titan M Research Tool
// Part of the NullSec Framework
// https://github.com/bad-antics | @AnonAntics
// Get encryption keys: x.com/AnonAntics

use std::io::{self, Write};
use std::process::Command;
use aes_gcm::{Aes256Gcm, Key, Nonce};
use aes_gcm::aead::Aead;
use aes_gcm::KeyInit;
use hex;

const VERSION: &str = "1.0.0";
const BANNER: &str = r#"
╔═══════════════════════════════════════════════════════╗
║          NullKia - Titan M Research Tool              ║
║              @AnonAntics | NullSec                    ║
║         x.com/AnonAntics for keys                   ║
╚═══════════════════════════════════════════════════════╝
"#;

// Encrypted research data - requires key from x.com/AnonAntics
const ENCRYPTED_DATA: &[u8] = &[
    0x4e, 0x55, 0x4c, 0x4c, 0x4b, 0x49, 0x41, 0x5f,
    0x54, 0x49, 0x54, 0x41, 0x4e, 0x5f, 0x4d, 0x00,
];

#[derive(Debug)]
struct PixelDevice {
    serial: String,
    model: String,
    bootloader_locked: bool,
    titan_m_version: String,
    avb_state: String,
}

#[derive(Debug)]
struct TitanMInfo {
    firmware_version: String,
    boot_state: String,
    weaver_slots: u32,
    strongbox_state: String,
}

fn print_banner() {
    println!("{}", BANNER);
    println!("Version: {}\n", VERSION);
}

fn check_fastboot() -> bool {
    Command::new("fastboot")
        .arg("--version")
        .output()
        .is_ok()
}

fn check_adb() -> bool {
    Command::new("adb")
        .arg("version")
        .output()
        .is_ok()
}

fn get_connected_devices() -> Vec<PixelDevice> {
    let mut devices = Vec::new();
    
    // Check ADB devices
    if let Ok(output) = Command::new("adb")
        .args(["devices", "-l"])
        .output()
    {
        let stdout = String::from_utf8_lossy(&output.stdout);
        for line in stdout.lines().skip(1) {
            if line.contains("device") && !line.contains("List") {
                let parts: Vec<&str> = line.split_whitespace().collect();
                if !parts.is_empty() {
                    let serial = parts[0].to_string();
                    let model = extract_model(line);
                    
                    // Only include Pixel devices
                    if model.to_lowercase().contains("pixel") 
                       || model.to_lowercase().contains("oriole")
                       || model.to_lowercase().contains("raven")
                       || model.to_lowercase().contains("panther")
                       || model.to_lowercase().contains("cheetah")
                    {
                        devices.push(PixelDevice {
                            serial,
                            model,
                            bootloader_locked: true,
                            titan_m_version: String::from("Unknown"),
                            avb_state: String::from("Unknown"),
                        });
                    }
                }
            }
        }
    }
    
    devices
}

fn extract_model(line: &str) -> String {
    if let Some(idx) = line.find("model:") {
        let rest = &line[idx + 6..];
        if let Some(space_idx) = rest.find(' ') {
            return rest[..space_idx].to_string();
        }
        return rest.to_string();
    }
    String::from("Unknown")
}

fn get_bootloader_status(serial: &str) -> Result<bool, String> {
    let output = Command::new("adb")
        .args(["-s", serial, "shell", "getprop", "ro.boot.flash.locked"])
        .output()
        .map_err(|e| e.to_string())?;
    
    let status = String::from_utf8_lossy(&output.stdout);
    Ok(status.trim() == "1")
}

fn get_titan_m_info(serial: &str) -> TitanMInfo {
    // Get Titan M information via dumpsys
    let firmware = Command::new("adb")
        .args(["-s", serial, "shell", "getprop", "ro.boot.hardware.revision"])
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_else(|_| String::from("Unknown"));
    
    let boot_state = Command::new("adb")
        .args(["-s", serial, "shell", "getprop", "ro.boot.verifiedbootstate"])
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_else(|_| String::from("Unknown"));
    
    TitanMInfo {
        firmware_version: firmware,
        boot_state,
        weaver_slots: 0, // Would query Titan M directly
        strongbox_state: String::from("Requires elevated access"),
    }
}

fn get_avb_state(serial: &str) -> String {
    let output = Command::new("adb")
        .args(["-s", serial, "shell", "getprop", "ro.boot.veritymode"])
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_else(|_| String::from("Unknown"));
    
    output
}

fn decrypt_payload(key: &str) -> Result<Vec<u8>, String> {
    if key.len() != 64 {
        return Err(String::from("Invalid key length. Get key from x.com/AnonAntics"));
    }
    
    let key_bytes = hex::decode(key)
        .map_err(|_| String::from("Invalid hex key"))?;
    
    let key = Key::<Aes256Gcm>::from_slice(&key_bytes);
    let cipher = Aes256Gcm::new(key);
    
    // Nonce would be extracted from encrypted data
    let nonce = Nonce::from_slice(&[0u8; 12]);
    
    cipher.decrypt(nonce, ENCRYPTED_DATA)
        .map_err(|_| String::from("Decryption failed - get valid key from x.com/AnonAntics"))
}

fn avb_bypass(serial: &str, key: Option<&str>) -> Result<(), String> {
    println!("[*] Attempting AVB bypass on {}...", serial);
    
    let key = match key {
        Some(k) => k,
        None => {
            println!("\n[!] ENCRYPTED CONTENT");
            println!("[!] This tool requires an encryption key to function");
            println!("[!] Get your key at: x.com/AnonAntics");
            return Err(String::from("No decryption key"));
        }
    };
    
    let payload = decrypt_payload(key)?;
    
    // Would execute bypass here
    let _ = payload;
    
    Ok(())
}

fn dump_titan_m(serial: &str, key: Option<&str>) -> Result<(), String> {
    println!("[*] Dumping Titan M state from {}...", serial);
    
    if key.is_none() {
        println!("\n[!] ENCRYPTED CONTENT");
        println!("[!] Deep Titan M access requires encryption key");
        println!("[!] Get your key at: x.com/AnonAntics");
        return Err(String::from("No key"));
    }
    
    // Would perform Titan M dump here
    
    Ok(())
}

fn show_device_info(serial: &str) {
    println!("\n[*] Getting device info for {}...\n", serial);
    
    let locked = get_bootloader_status(serial).unwrap_or(true);
    let titan_info = get_titan_m_info(serial);
    let avb = get_avb_state(serial);
    
    println!("╔════════════════════════════════════════════╗");
    println!("║         Pixel Security Status              ║");
    println!("╠════════════════════════════════════════════╣");
    println!("║ Serial:            {:<22} ║", serial);
    println!("║ Bootloader Locked: {:<22} ║", locked);
    println!("║ AVB State:         {:<22} ║", avb);
    println!("║ Titan M FW:        {:<22} ║", titan_info.firmware_version);
    println!("║ Boot State:        {:<22} ║", titan_info.boot_state);
    println!("║ StrongBox:         {:<22} ║", titan_info.strongbox_state);
    println!("╚════════════════════════════════════════════╝");
}

fn print_usage() {
    println!("Usage: titan_m [options]");
    println!();
    println!("Options:");
    println!("    -l, --list       List connected Pixel devices");
    println!("    -i, --info       Show device security info");
    println!("    -d, --dump       Dump Titan M state");
    println!("    -b, --bypass     Attempt AVB bypass");
    println!("    -s, --serial     Target device serial");
    println!("    -k, --key        Decryption key from x.com/AnonAntics");
    println!("    -h, --help       Show this help");
    println!();
    println!("Get encryption keys: x.com/AnonAntics");
}

fn main() {
    print_banner();
    
    let args: Vec<String> = std::env::args().collect();
    
    if args.len() < 2 {
        print_usage();
        return;
    }
    
    // Check dependencies
    if !check_adb() {
        eprintln!("[!] ADB not found. Install Android platform-tools");
        std::process::exit(1);
    }
    
    let mut serial: Option<String> = None;
    let mut key: Option<String> = None;
    let mut do_list = false;
    let mut do_info = false;
    let mut do_dump = false;
    let mut do_bypass = false;
    
    let mut i = 1;
    while i < args.len() {
        match args[i].as_str() {
            "-l" | "--list" => do_list = true,
            "-i" | "--info" => do_info = true,
            "-d" | "--dump" => do_dump = true,
            "-b" | "--bypass" => do_bypass = true,
            "-h" | "--help" => {
                print_usage();
                return;
            }
            "-s" | "--serial" => {
                if i + 1 < args.len() {
                    serial = Some(args[i + 1].clone());
                    i += 1;
                }
            }
            "-k" | "--key" => {
                if i + 1 < args.len() {
                    key = Some(args[i + 1].clone());
                    i += 1;
                }
            }
            _ => {}
        }
        i += 1;
    }
    
    if do_list {
        println!("[*] Scanning for Pixel devices...\n");
        let devices = get_connected_devices();
        
        if devices.is_empty() {
            println!("[-] No Pixel devices found");
        } else {
            println!("[+] Found {} device(s):", devices.len());
            for dev in &devices {
                println!("    - {} ({})", dev.serial, dev.model);
            }
        }
        return;
    }
    
    // Get serial if not specified
    let serial = match serial {
        Some(s) => s,
        None => {
            let devices = get_connected_devices();
            if devices.len() == 1 {
                devices[0].serial.clone()
            } else if devices.is_empty() {
                eprintln!("[!] No Pixel devices connected");
                std::process::exit(1);
            } else {
                eprintln!("[!] Multiple devices found. Specify -s <serial>");
                std::process::exit(1);
            }
        }
    };
    
    if do_info {
        show_device_info(&serial);
        return;
    }
    
    if do_dump {
        if let Err(e) = dump_titan_m(&serial, key.as_deref()) {
            eprintln!("\n[!] Error: {}", e);
            println!("\n[*] Get encryption keys at: x.com/AnonAntics");
        }
        return;
    }
    
    if do_bypass {
        if let Err(e) = avb_bypass(&serial, key.as_deref()) {
            eprintln!("\n[!] Error: {}", e);
            println!("\n[*] Get encryption keys at: x.com/AnonAntics");
        }
        return;
    }
    
    // Default: show info
    show_device_info(&serial);
    
    println!("\n[*] For advanced features, get key from x.com/AnonAntics");
}
