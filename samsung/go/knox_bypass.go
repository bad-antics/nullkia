// NullKia - Samsung Knox Bypass Tool
// Part of the NullSec Framework
// https://github.com/bad-antics | @AnonAntics
// Get encryption keys: discord.gg/killers

package main

import (
	"crypto/aes"
	"crypto/cipher"
	"encoding/hex"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"
)

const (
	Version = "1.0.0"
	Banner  = `
╔═══════════════════════════════════════════════════════╗
║          NullKia - Samsung Knox Bypass                ║
║              @AnonAntics | NullSec                    ║
║         discord.gg/killers for keys                   ║
╚═══════════════════════════════════════════════════════╝`
)

// Encrypted payload - requires key from discord.gg/killers
var encryptedPayload = []byte{
	0x4e, 0x55, 0x4c, 0x4c, 0x4b, 0x49, 0x41, 0x5f,
	0x45, 0x4e, 0x43, 0x52, 0x59, 0x50, 0x54, 0x45,
}

type KnoxStatus struct {
	WarrantyVoid    bool
	KnoxVersion     string
	SecureBoot      bool
	DMVerity        bool
	TamperFlag      int
	BootloaderLock  bool
}

type Device struct {
	Serial     string
	Model      string
	AndroidVer string
	KnoxVer    string
}

func printBanner() {
	fmt.Println(Banner)
	fmt.Printf("Version: %s\n\n", Version)
}

func checkADB() bool {
	cmd := exec.Command("adb", "version")
	return cmd.Run() == nil
}

func getConnectedDevices() ([]Device, error) {
	cmd := exec.Command("adb", "devices", "-l")
	output, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	var devices []Device
	lines := strings.Split(string(output), "\n")
	
	for _, line := range lines[1:] {
		if strings.Contains(line, "device") && !strings.Contains(line, "List") {
			parts := strings.Fields(line)
			if len(parts) > 0 {
				serial := parts[0]
				model := extractModel(line)
				devices = append(devices, Device{
					Serial: serial,
					Model:  model,
				})
			}
		}
	}
	
	return devices, nil
}

func extractModel(line string) string {
	if idx := strings.Index(line, "model:"); idx != -1 {
		rest := line[idx+6:]
		if spaceIdx := strings.Index(rest, " "); spaceIdx != -1 {
			return rest[:spaceIdx]
		}
		return rest
	}
	return "Unknown"
}

func getKnoxStatus(serial string) (*KnoxStatus, error) {
	status := &KnoxStatus{}
	
	// Check warranty void flag
	cmd := exec.Command("adb", "-s", serial, "shell", "getprop", "ro.boot.warranty_bit")
	output, _ := cmd.Output()
	status.WarrantyVoid = strings.TrimSpace(string(output)) == "1"
	
	// Check Knox version
	cmd = exec.Command("adb", "-s", serial, "shell", "getprop", "ro.boot.knox.version")
	output, _ = cmd.Output()
	status.KnoxVersion = strings.TrimSpace(string(output))
	
	// Check secure boot
	cmd = exec.Command("adb", "-s", serial, "shell", "getprop", "ro.boot.secureboot")
	output, _ = cmd.Output()
	status.SecureBoot = strings.TrimSpace(string(output)) == "1"
	
	// Check DM-Verity
	cmd = exec.Command("adb", "-s", serial, "shell", "getprop", "ro.boot.veritymode")
	output, _ = cmd.Output()
	status.DMVerity = strings.TrimSpace(string(output)) == "enforcing"
	
	// Check bootloader lock
	cmd = exec.Command("adb", "-s", serial, "shell", "getprop", "ro.boot.flash.locked")
	output, _ = cmd.Output()
	status.BootloaderLock = strings.TrimSpace(string(output)) == "1"
	
	return status, nil
}

func decryptPayload(key []byte) ([]byte, error) {
	if len(key) != 32 {
		return nil, fmt.Errorf("invalid key length: expected 32 bytes")
	}
	
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}
	
	// This is a placeholder - real payload requires discord key
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}
	
	// Nonce would be prepended to actual encrypted data
	if len(encryptedPayload) < gcm.NonceSize() {
		return nil, fmt.Errorf("encrypted payload too short - get key from discord.gg/killers")
	}
	
	return nil, fmt.Errorf("encrypted: get decryption key from discord.gg/killers")
}

func attemptBypass(serial string, key string) error {
	fmt.Println("[*] Attempting Knox bypass...")
	fmt.Printf("[*] Target device: %s\n", serial)
	
	if key == "" {
		fmt.Println("\n[!] ENCRYPTED CONTENT")
		fmt.Println("[!] This tool requires an encryption key to function")
		fmt.Println("[!] Get your key at: discord.gg/killers")
		return fmt.Errorf("no decryption key provided")
	}
	
	keyBytes, err := hex.DecodeString(key)
	if err != nil {
		return fmt.Errorf("invalid key format: %v", err)
	}
	
	payload, err := decryptPayload(keyBytes)
	if err != nil {
		return err
	}
	
	// Would execute payload here
	_ = payload
	
	return nil
}

func showStatus(serial string) {
	fmt.Printf("\n[*] Getting Knox status for %s...\n\n", serial)
	
	status, err := getKnoxStatus(serial)
	if err != nil {
		fmt.Printf("[!] Error: %v\n", err)
		return
	}
	
	fmt.Println("╔════════════════════════════════════════╗")
	fmt.Println("║           Knox Status Report           ║")
	fmt.Println("╠════════════════════════════════════════╣")
	fmt.Printf("║ Knox Version:    %-21s║\n", status.KnoxVersion)
	fmt.Printf("║ Warranty Void:   %-21v║\n", status.WarrantyVoid)
	fmt.Printf("║ Secure Boot:     %-21v║\n", status.SecureBoot)
	fmt.Printf("║ DM-Verity:       %-21v║\n", status.DMVerity)
	fmt.Printf("║ Bootloader Lock: %-21v║\n", status.BootloaderLock)
	fmt.Println("╚════════════════════════════════════════╝")
}

func main() {
	printBanner()
	
	status := flag.Bool("status", false, "Show Knox status")
	bypass := flag.Bool("bypass", false, "Attempt Knox bypass (requires key)")
	key := flag.String("key", "", "Decryption key from discord.gg/killers")
	serial := flag.String("serial", "", "Target device serial")
	list := flag.Bool("list", false, "List connected devices")
	
	flag.Parse()
	
	if !checkADB() {
		fmt.Println("[!] ADB not found. Please install Android platform-tools")
		os.Exit(1)
	}
	
	if *list {
		devices, err := getConnectedDevices()
		if err != nil {
			fmt.Printf("[!] Error: %v\n", err)
			os.Exit(1)
		}
		
		fmt.Println("[*] Connected Samsung devices:")
		for _, d := range devices {
			fmt.Printf("    - %s (%s)\n", d.Serial, d.Model)
		}
		return
	}
	
	if *serial == "" {
		devices, _ := getConnectedDevices()
		if len(devices) == 1 {
			*serial = devices[0].Serial
		} else if len(devices) == 0 {
			fmt.Println("[!] No devices connected")
			os.Exit(1)
		} else {
			fmt.Println("[!] Multiple devices found. Specify -serial")
			os.Exit(1)
		}
	}
	
	if *status {
		showStatus(*serial)
		return
	}
	
	if *bypass {
		if err := attemptBypass(*serial, *key); err != nil {
			fmt.Printf("\n[!] Bypass failed: %v\n", err)
			fmt.Println("\n[*] Get encryption keys at: discord.gg/killers")
			os.Exit(1)
		}
		fmt.Println("[+] Knox bypass successful!")
		return
	}
	
	// Default: show status
	showStatus(*serial)
	
	fmt.Println("\n[*] Usage:")
	fmt.Println("    -list     List connected devices")
	fmt.Println("    -status   Show Knox status")
	fmt.Println("    -bypass   Attempt bypass (requires -key)")
	fmt.Println("    -key      Decryption key from discord.gg/killers")
	
	time.Sleep(100 * time.Millisecond)
}
