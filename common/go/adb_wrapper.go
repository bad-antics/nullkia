// NullKia - Universal ADB Wrapper
// Part of the NullSec Framework
// https://github.com/bad-antics | @AnonAntics
// Get encryption keys: x.com/AnonAntics

package main

import (
	"bufio"
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
║            NullKia - Universal ADB Wrapper            ║
║              @AnonAntics | NullSec                    ║
║         x.com/AnonAntics for keys                   ║
╚═══════════════════════════════════════════════════════╝`
)

type Device struct {
	Serial     string
	State      string
	Model      string
	Product    string
	Authorized bool
}

func printBanner() {
	fmt.Println(Banner)
	fmt.Printf("Version: %s\n\n", Version)
}

func checkADB() bool {
	cmd := exec.Command("adb", "version")
	return cmd.Run() == nil
}

func startServer() error {
	cmd := exec.Command("adb", "start-server")
	return cmd.Run()
}

func killServer() error {
	cmd := exec.Command("adb", "kill-server")
	return cmd.Run()
}

func getDevices() ([]Device, error) {
	cmd := exec.Command("adb", "devices", "-l")
	output, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	var devices []Device
	lines := strings.Split(string(output), "\n")

	for _, line := range lines[1:] {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		parts := strings.Fields(line)
		if len(parts) < 2 {
			continue
		}

		device := Device{
			Serial: parts[0],
			State:  parts[1],
		}

		// Parse additional info
		for _, part := range parts[2:] {
			if strings.HasPrefix(part, "model:") {
				device.Model = strings.TrimPrefix(part, "model:")
			} else if strings.HasPrefix(part, "product:") {
				device.Product = strings.TrimPrefix(part, "product:")
			}
		}

		device.Authorized = device.State == "device"
		devices = append(devices, device)
	}

	return devices, nil
}

func shell(serial, command string) (string, error) {
	args := []string{}
	if serial != "" {
		args = append(args, "-s", serial)
	}
	args = append(args, "shell", command)

	cmd := exec.Command("adb", args...)
	output, err := cmd.CombinedOutput()
	return string(output), err
}

func push(serial, local, remote string) error {
	args := []string{}
	if serial != "" {
		args = append(args, "-s", serial)
	}
	args = append(args, "push", local, remote)

	cmd := exec.Command("adb", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func pull(serial, remote, local string) error {
	args := []string{}
	if serial != "" {
		args = append(args, "-s", serial)
	}
	args = append(args, "pull", remote, local)

	cmd := exec.Command("adb", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func reboot(serial, mode string) error {
	args := []string{}
	if serial != "" {
		args = append(args, "-s", serial)
	}

	if mode == "" {
		args = append(args, "reboot")
	} else {
		args = append(args, "reboot", mode)
	}

	cmd := exec.Command("adb", args...)
	return cmd.Run()
}

func getprop(serial, prop string) string {
	output, _ := shell(serial, "getprop "+prop)
	return strings.TrimSpace(output)
}

func getSecurityInfo(serial string) {
	fmt.Println("\n╔════════════════════════════════════════╗")
	fmt.Println("║         Security Information           ║")
	fmt.Println("╠════════════════════════════════════════╣")

	props := map[string]string{
		"ro.build.fingerprint":    "Build",
		"ro.boot.verifiedbootstate": "Verified Boot",
		"ro.boot.flash.locked":    "Bootloader",
		"ro.boot.warranty_bit":    "Warranty",
		"ro.build.selinux":        "SELinux",
		"ro.debuggable":           "Debuggable",
		"ro.secure":               "Secure",
	}

	for prop, name := range props {
		value := getprop(serial, prop)
		if value == "" {
			value = "N/A"
		}
		fmt.Printf("║ %-18s: %-17s║\n", name, truncate(value, 17))
	}

	fmt.Println("╚════════════════════════════════════════╝")
}

func truncate(s string, maxLen int) string {
	if len(s) > maxLen {
		return s[:maxLen-3] + "..."
	}
	return s
}

func dumpPackages(serial string) {
	fmt.Println("[*] Dumping installed packages...")
	output, _ := shell(serial, "pm list packages")
	packages := strings.Split(output, "\n")
	fmt.Printf("[+] Found %d packages\n", len(packages)-1)

	for _, pkg := range packages[:10] {
		if pkg != "" {
			fmt.Println("    " + strings.TrimPrefix(pkg, "package:"))
		}
	}
	fmt.Println("    ...")
}

func logcat(serial string, filter string) {
	args := []string{}
	if serial != "" {
		args = append(args, "-s", serial)
	}
	args = append(args, "logcat")
	if filter != "" {
		args = append(args, "-s", filter)
	}

	cmd := exec.Command("adb", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	fmt.Println("[*] Starting logcat (Ctrl+C to stop)...")
	cmd.Run()
}

func interactiveShell(serial string) {
	fmt.Println("[*] Starting interactive shell...")
	fmt.Println("[*] Type 'exit' to quit\n")

	reader := bufio.NewReader(os.Stdin)
	prompt := "nullkia> "

	for {
		fmt.Print(prompt)
		input, _ := reader.ReadString('\n')
		input = strings.TrimSpace(input)

		if input == "exit" || input == "quit" {
			break
		}

		if input == "" {
			continue
		}

		output, _ := shell(serial, input)
		fmt.Print(output)
	}
}

func main() {
	printBanner()

	list := flag.Bool("list", false, "List connected devices")
	serial := flag.String("s", "", "Target device serial")
	shellCmd := flag.String("shell", "", "Execute shell command")
	pushFlag := flag.String("push", "", "Push file (local:remote)")
	pullFlag := flag.String("pull", "", "Pull file (remote:local)")
	rebootFlag := flag.String("reboot", "", "Reboot device (empty/bootloader/recovery)")
	security := flag.Bool("security", false, "Show security info")
	packages := flag.Bool("packages", false, "List packages")
	logcatFlag := flag.String("logcat", "", "Start logcat (optional filter)")
	interactive := flag.Bool("i", false, "Interactive shell")
	startSrv := flag.Bool("start", false, "Start ADB server")
	killSrv := flag.Bool("kill", false, "Kill ADB server")

	flag.Parse()

	if !checkADB() {
		fmt.Println("[!] ADB not found. Install Android platform-tools")
		os.Exit(1)
	}

	if *startSrv {
		startServer()
		fmt.Println("[+] ADB server started")
		return
	}

	if *killSrv {
		killServer()
		fmt.Println("[+] ADB server killed")
		return
	}

	if *list {
		devices, err := getDevices()
		if err != nil {
			fmt.Printf("[!] Error: %v\n", err)
			os.Exit(1)
		}

		if len(devices) == 0 {
			fmt.Println("[-] No devices connected")
			return
		}

		fmt.Println("[*] Connected devices:\n")
		for _, d := range devices {
			auth := "✓"
			if !d.Authorized {
				auth = "✗"
			}
			fmt.Printf("    [%s] %s - %s (%s)\n", auth, d.Serial, d.Model, d.State)
		}
		return
	}

	// Auto-select device if only one
	if *serial == "" {
		devices, _ := getDevices()
		if len(devices) == 1 {
			*serial = devices[0].Serial
		}
	}

	if *shellCmd != "" {
		output, _ := shell(*serial, *shellCmd)
		fmt.Print(output)
		return
	}

	if *pushFlag != "" {
		parts := strings.SplitN(*pushFlag, ":", 2)
		if len(parts) == 2 {
			push(*serial, parts[0], parts[1])
		} else {
			fmt.Println("[!] Format: local:remote")
		}
		return
	}

	if *pullFlag != "" {
		parts := strings.SplitN(*pullFlag, ":", 2)
		if len(parts) == 2 {
			pull(*serial, parts[0], parts[1])
		} else {
			fmt.Println("[!] Format: remote:local")
		}
		return
	}

	if *rebootFlag != "" || flag.NArg() > 0 && os.Args[len(os.Args)-1] == "-reboot" {
		reboot(*serial, *rebootFlag)
		fmt.Println("[+] Rebooting...")
		return
	}

	if *security {
		getSecurityInfo(*serial)
		return
	}

	if *packages {
		dumpPackages(*serial)
		return
	}

	if *logcatFlag != "" || flag.Lookup("logcat").Changed {
		logcat(*serial, *logcatFlag)
		return
	}

	if *interactive {
		interactiveShell(*serial)
		return
	}

	// Default: show devices and help
	devices, _ := getDevices()
	if len(devices) > 0 {
		fmt.Println("[*] Connected devices:")
		for _, d := range devices {
			fmt.Printf("    - %s (%s)\n", d.Serial, d.Model)
		}
	} else {
		fmt.Println("[-] No devices connected")
	}

	fmt.Println("\n[*] Usage:")
	fmt.Println("    -list       List devices")
	fmt.Println("    -shell CMD  Execute command")
	fmt.Println("    -security   Security info")
	fmt.Println("    -i          Interactive shell")
	fmt.Println("    -reboot     Reboot device")
}
