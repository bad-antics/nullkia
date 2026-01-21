/*
 * NullKia Cross-Platform GUI - Haxe
 * Write once, deploy everywhere
 * @author bad-antics
 * @discord discord.gg/killers
 */

package nullkia.gui;

import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

// Version info
class Config {
    public static inline var VERSION:String = "2.0.0";
    public static inline var AUTHOR:String = "bad-antics";
    public static inline var DISCORD:String = "discord.gg/killers";
    public static inline var TWITTER:String = "bad-antics";
}

// License management
enum LicenseTier {
    Free;
    Premium;
    Enterprise;
}

class License {
    public var key:String;
    public var tier:LicenseTier;
    public var valid:Bool;
    
    public function new(?licenseKey:String) {
        key = licenseKey != null ? licenseKey : "";
        tier = LicenseTier.Free;
        valid = false;
        validate();
    }
    
    private function validate():Void {
        if (key.length != 24 || !StringTools.startsWith(key, "NKIA-")) {
            tier = LicenseTier.Free;
            valid = false;
            return;
        }
        
        var parts = key.split("-");
        if (parts.length != 5) {
            tier = LicenseTier.Free;
            valid = false;
            return;
        }
        
        var tierCode = parts[1].substr(0, 2);
        switch (tierCode) {
            case "PR": tier = LicenseTier.Premium;
            case "EN": tier = LicenseTier.Enterprise;
            default: tier = LicenseTier.Free;
        }
        valid = true;
    }
    
    public function isPremium():Bool {
        return valid && tier != LicenseTier.Free;
    }
}

// Device representation
enum DeviceMode {
    ADB;
    Fastboot;
    Recovery;
    Unknown;
}

class Device {
    public var serial:String;
    public var model:String;
    public var manufacturer:String;
    public var mode:DeviceMode;
    public var isRooted:Bool;
    
    public function new() {
        serial = "";
        model = "";
        manufacturer = "";
        mode = DeviceMode.Unknown;
        isRooted = false;
    }
}

// Terminal colors for console output
class Colors {
    public static inline var RESET:String = "\x1b[0m";
    public static inline var RED:String = "\x1b[31m";
    public static inline var GREEN:String = "\x1b[32m";
    public static inline var YELLOW:String = "\x1b[33m";
    public static inline var BLUE:String = "\x1b[34m";
    public static inline var CYAN:String = "\x1b[36m";
    
    public static function success(msg:String):Void {
        Sys.println('${GREEN}✅ ${msg}${RESET}');
    }
    
    public static function error(msg:String):Void {
        Sys.println('${RED}❌ ${msg}${RESET}');
    }
    
    public static function warning(msg:String):Void {
        Sys.println('${YELLOW}⚠️  ${msg}${RESET}');
    }
    
    public static function info(msg:String):Void {
        Sys.println('${BLUE}ℹ️  ${msg}${RESET}');
    }
}

// Command executor
class CommandRunner {
    public static function exec(command:String, args:Array<String>):String {
        try {
            var process = new Process(command, args);
            var output = process.stdout.readAll().toString();
            var exitCode = process.exitCode();
            process.close();
            return StringTools.trim(output);
        } catch (e:Dynamic) {
            return "";
        }
    }
    
    public static function adb(args:Array<String>):String {
        return exec("adb", args);
    }
    
    public static function fastboot(args:Array<String>):String {
        return exec("fastboot", args);
    }
}

// Device manager
class DeviceManager {
    public static function getADBDevices():Array<Device> {
        var devices:Array<Device> = [];
        var output = CommandRunner.adb(["devices", "-l"]);
        
        var lines = output.split("\n");
        for (line in lines) {
            line = StringTools.trim(line);
            if (StringTools.startsWith(line, "List") || line.length == 0) continue;
            
            var parts = line.split("\t");
            if (parts.length < 2) continue;
            
            var device = new Device();
            device.serial = parts[0];
            device.mode = DeviceMode.ADB;
            
            // Get model
            device.model = CommandRunner.adb(["-s", device.serial, "shell", "getprop", "ro.product.model"]);
            device.manufacturer = CommandRunner.adb(["-s", device.serial, "shell", "getprop", "ro.product.manufacturer"]);
            
            // Check root
            var rootCheck = CommandRunner.adb(["-s", device.serial, "shell", "su", "-c", "id"]);
            device.isRooted = rootCheck.indexOf("uid=0") != -1;
            
            devices.push(device);
        }
        
        return devices;
    }
    
    public static function getFastbootDevices():Array<Device> {
        var devices:Array<Device> = [];
        var output = CommandRunner.fastboot(["devices"]);
        
        var lines = output.split("\n");
        for (line in lines) {
            line = StringTools.trim(line);
            if (line.length == 0) continue;
            
            var parts = line.split("\t");
            if (parts.length < 2) continue;
            
            var device = new Device();
            device.serial = parts[0];
            device.mode = DeviceMode.Fastboot;
            
            devices.push(device);
        }
        
        return devices;
    }
    
    public static function getAllDevices():Array<Device> {
        var devices:Array<Device> = [];
        for (d in getADBDevices()) devices.push(d);
        for (d in getFastbootDevices()) devices.push(d);
        return devices;
    }
}

// Firmware operations
class FirmwareManager {
    private var license:License;
    
    public function new(lic:License) {
        license = lic;
    }
    
    public function dumpPartition(serial:String, partition:String, outputDir:String):Bool {
        if (!license.isPremium()) {
            Colors.warning("Partition dump requires premium license");
            Colors.warning("Get premium at discord.gg/killers");
            return false;
        }
        
        Colors.info('Dumping partition: ${partition}');
        
        // Ensure output directory exists
        if (!FileSystem.exists(outputDir)) {
            FileSystem.createDirectory(outputDir);
        }
        
        // Get partition path
        var devPath = CommandRunner.adb(["-s", serial, "shell", "su", "-c", 
            'readlink -f /dev/block/by-name/${partition}']);
        
        if (devPath.length == 0) {
            Colors.error("Could not find partition");
            return false;
        }
        
        var outputFile = Path.join([outputDir, '${partition}.img']);
        
        // Dump using dd
        var result = CommandRunner.adb(["-s", serial, "shell", "su", "-c",
            'dd if=${devPath} 2>/dev/null | base64']);
        
        if (result.length > 0) {
            // Decode base64 and save
            try {
                var decoded = haxe.crypto.Base64.decode(result);
                File.saveBytes(outputFile, decoded);
                Colors.success('Saved to ${outputFile}');
                return true;
            } catch (e:Dynamic) {
                Colors.error('Failed to save: ${e}');
            }
        }
        
        return false;
    }
    
    public function flashPartition(serial:String, partition:String, imagePath:String):Bool {
        if (!license.isPremium()) {
            Colors.warning("Flashing requires premium license");
            return false;
        }
        
        if (!FileSystem.exists(imagePath)) {
            Colors.error('Image not found: ${imagePath}');
            return false;
        }
        
        Colors.info('Flashing ${partition}...');
        
        var result = CommandRunner.fastboot(["-s", serial, "flash", partition, imagePath]);
        
        if (result.indexOf("OKAY") != -1) {
            Colors.success('Successfully flashed ${partition}');
            return true;
        }
        
        Colors.error('Flash failed: ${result}');
        return false;
    }
    
    public function getPartitions(serial:String):Array<String> {
        var partitions:Array<String> = [];
        
        var output = CommandRunner.adb(["-s", serial, "shell", "su", "-c", 
            "ls /dev/block/by-name/"]);
        
        var lines = output.split("\n");
        for (line in lines) {
            line = StringTools.trim(line);
            if (line.length > 0) {
                partitions.push(line);
            }
        }
        
        return partitions;
    }
}

// Data extraction
class DataExtractor {
    private var license:License;
    
    public function new(lic:License) {
        license = lic;
    }
    
    public function extractContacts(serial:String, outputDir:String):Bool {
        if (!license.isPremium()) {
            Colors.warning("Contact extraction requires premium license");
            return false;
        }
        
        Colors.info("Extracting contacts...");
        
        var result = CommandRunner.adb(["-s", serial, "shell", 
            "content", "query", "--uri", "content://contacts/phones"]);
        
        if (result.length > 0) {
            var outputFile = Path.join([outputDir, "contacts.txt"]);
            File.saveContent(outputFile, result);
            Colors.success('Saved contacts to ${outputFile}');
            return true;
        }
        
        return false;
    }
    
    public function extractSMS(serial:String, outputDir:String):Bool {
        if (!license.isPremium()) {
            Colors.warning("SMS extraction requires premium license");
            return false;
        }
        
        Colors.info("Extracting SMS...");
        
        var result = CommandRunner.adb(["-s", serial, "shell",
            "content", "query", "--uri", "content://sms"]);
        
        if (result.length > 0) {
            var outputFile = Path.join([outputDir, "sms.txt"]);
            File.saveContent(outputFile, result);
            Colors.success('Saved SMS to ${outputFile}');
            return true;
        }
        
        return false;
    }
    
    public function extractCallLog(serial:String, outputDir:String):Bool {
        if (!license.isPremium()) {
            Colors.warning("Call log extraction requires premium license");
            return false;
        }
        
        Colors.info("Extracting call log...");
        
        var result = CommandRunner.adb(["-s", serial, "shell",
            "content", "query", "--uri", "content://call_log/calls"]);
        
        if (result.length > 0) {
            var outputFile = Path.join([outputDir, "call_log.txt"]);
            File.saveContent(outputFile, result);
            Colors.success('Saved call log to ${outputFile}');
            return true;
        }
        
        return false;
    }
}

// Menu system
class Menu {
    private var license:License;
    private var firmwareManager:FirmwareManager;
    private var dataExtractor:DataExtractor;
    
    public function new(lic:License) {
        license = lic;
        firmwareManager = new FirmwareManager(license);
        dataExtractor = new DataExtractor(license);
    }
    
    public function showBanner():Void {
        Sys.println('${Colors.CYAN}');
        Sys.println("╭──────────────────────────────────────────╮");
        Sys.println("│        📱 NULLKIA CROSS-PLATFORM         │");
        Sys.println("│       ════════════════════════════       │");
        Sys.println("│                                          │");
        Sys.println("│   🔧 Universal Mobile Security Suite     │");
        Sys.println("│   📡 Firmware • Data • Analysis          │");
        Sys.println("│   💾 Haxe Cross-Platform GUI v2.0        │");
        Sys.println("│                                          │");
        Sys.println("│            bad-antics | NullSec         │");
        Sys.println("╰──────────────────────────────────────────╯");
        Sys.println('${Colors.RESET}');
    }
    
    public function showMainMenu():Void {
        Sys.println("\n📦 Main Menu:\n");
        Sys.println("  [1] Device Manager");
        Sys.println("  [2] Firmware Tools (Premium)");
        Sys.println("  [3] Data Extraction (Premium)");
        Sys.println("  [4] System Info");
        Sys.println("  [5] License Info");
        Sys.println("  [0] Exit");
        Sys.println("");
    }
    
    public function showDevices():Void {
        var devices = DeviceManager.getAllDevices();
        
        if (devices.length == 0) {
            Colors.error("No devices connected");
            return;
        }
        
        Sys.println("\n📱 Connected Devices:\n");
        
        var idx = 1;
        for (device in devices) {
            var modeStr = switch (device.mode) {
                case DeviceMode.ADB: "📱 ADB";
                case DeviceMode.Fastboot: "⚡ Fastboot";
                case DeviceMode.Recovery: "🔧 Recovery";
                default: "❓ Unknown";
            };
            
            Sys.println('  [${idx}] ${device.manufacturer} ${device.model}');
            Sys.println('      Serial: ${device.serial}');
            Sys.println('      Mode: ${modeStr}');
            if (device.isRooted) {
                Sys.println('      Status: 🔓 Rooted');
            }
            Sys.println("");
            idx++;
        }
    }
    
    public function selectDevice():Device {
        var devices = DeviceManager.getAllDevices();
        
        if (devices.length == 0) {
            return null;
        }
        
        showDevices();
        
        Sys.print('Select device [1-${devices.length}]: ');
        var input = Sys.stdin().readLine();
        var idx = Std.parseInt(input);
        
        if (idx == null || idx < 1 || idx > devices.length) {
            Colors.error("Invalid selection");
            return null;
        }
        
        return devices[idx - 1];
    }
    
    public function firmwareMenu(device:Device):Void {
        Sys.println("\n🔧 Firmware Tools:\n");
        Sys.println("  [1] List partitions");
        Sys.println("  [2] Dump partition (Premium)");
        Sys.println("  [3] Flash partition (Premium)");
        Sys.println("  [4] Reboot device");
        Sys.println("  [0] Back");
        
        Sys.print("\nSelect: ");
        var input = Sys.stdin().readLine();
        var choice = Std.parseInt(input);
        
        switch (choice) {
            case 1:
                var partitions = firmwareManager.getPartitions(device.serial);
                Sys.println("\n📋 Partitions:\n");
                for (p in partitions) {
                    Sys.println('  • ${p}');
                }
                
            case 2:
                Sys.print("Enter partition name: ");
                var partition = Sys.stdin().readLine();
                var homeDir = Sys.getEnv("HOME");
                var outputDir = Path.join([homeDir, ".nullkia", "dumps"]);
                firmwareManager.dumpPartition(device.serial, partition, outputDir);
                
            case 3:
                Sys.print("Enter partition name: ");
                var partition = Sys.stdin().readLine();
                Sys.print("Enter image path: ");
                var imagePath = Sys.stdin().readLine();
                firmwareManager.flashPartition(device.serial, partition, imagePath);
                
            case 4:
                Sys.println("\nReboot targets:");
                Sys.println("  [1] System");
                Sys.println("  [2] Bootloader");
                Sys.println("  [3] Recovery");
                Sys.print("Select: ");
                var target = Std.parseInt(Sys.stdin().readLine());
                var targetStr = switch (target) {
                    case 1: "";
                    case 2: "bootloader";
                    case 3: "recovery";
                    default: "";
                };
                CommandRunner.adb(["-s", device.serial, "reboot", targetStr]);
                Colors.success("Reboot command sent");
                
            default:
        }
    }
    
    public function dataMenu(device:Device):Void {
        Sys.println("\n📊 Data Extraction:\n");
        Sys.println("  [1] Extract contacts (Premium)");
        Sys.println("  [2] Extract SMS (Premium)");
        Sys.println("  [3] Extract call log (Premium)");
        Sys.println("  [4] Full extraction (Premium)");
        Sys.println("  [0] Back");
        
        Sys.print("\nSelect: ");
        var input = Sys.stdin().readLine();
        var choice = Std.parseInt(input);
        
        var homeDir = Sys.getEnv("HOME");
        var outputDir = Path.join([homeDir, ".nullkia", "extractions", device.serial]);
        
        if (!FileSystem.exists(outputDir)) {
            FileSystem.createDirectory(outputDir);
        }
        
        switch (choice) {
            case 1:
                dataExtractor.extractContacts(device.serial, outputDir);
            case 2:
                dataExtractor.extractSMS(device.serial, outputDir);
            case 3:
                dataExtractor.extractCallLog(device.serial, outputDir);
            case 4:
                dataExtractor.extractContacts(device.serial, outputDir);
                dataExtractor.extractSMS(device.serial, outputDir);
                dataExtractor.extractCallLog(device.serial, outputDir);
            default:
        }
    }
    
    public function showLicenseInfo():Void {
        Sys.println("\n🔑 License Information:\n");
        Sys.println('  Key: ${license.key.length > 0 ? license.key : "Not set"}');
        Sys.println('  Tier: ${license.tier}');
        Sys.println('  Valid: ${license.valid}');
        Sys.println("");
        
        if (!license.isPremium()) {
            Colors.warning("Upgrade to Premium for full features!");
            Colors.info("Get your license at discord.gg/killers");
        }
    }
    
    public function run():Void {
        showBanner();
        
        var running = true;
        while (running) {
            showMainMenu();
            Sys.print("Select: ");
            var input = Sys.stdin().readLine();
            var choice = Std.parseInt(input);
            
            switch (choice) {
                case 1:
                    showDevices();
                    
                case 2:
                    var device = selectDevice();
                    if (device != null) {
                        firmwareMenu(device);
                    }
                    
                case 3:
                    var device = selectDevice();
                    if (device != null) {
                        dataMenu(device);
                    }
                    
                case 4:
                    var device = selectDevice();
                    if (device != null) {
                        Sys.println("\n📊 System Information:\n");
                        var props = [
                            "ro.product.model",
                            "ro.product.manufacturer",
                            "ro.build.version.release",
                            "ro.build.version.sdk",
                            "ro.build.fingerprint"
                        ];
                        for (prop in props) {
                            var value = CommandRunner.adb(["-s", device.serial, "shell", "getprop", prop]);
                            Sys.println('  ${prop}: ${value}');
                        }
                    }
                    
                case 5:
                    showLicenseInfo();
                    
                case 0:
                    running = false;
                    
                default:
                    Colors.error("Invalid option");
            }
        }
        
        Sys.println("\n─────────────────────────────────────────");
        Sys.println("📱 NullKia Cross-Platform GUI");
        Sys.println("🔑 Premium: discord.gg/killers");
        Sys.println("🐦 GitHub: bad-antics");
        Sys.println("─────────────────────────────────────────\n");
    }
}

// Main entry point
class Main {
    static function main():Void {
        var args = Sys.args();
        var license = new License();
        
        var i = 0;
        while (i < args.length) {
            if (args[i] == "-k" || args[i] == "--key") {
                if (i + 1 < args.length) {
                    license = new License(args[i + 1]);
                    Colors.info('License tier: ${license.tier}');
                    i++;
                }
            } else if (args[i] == "-h" || args[i] == "--help") {
                Sys.println('NullKia Cross-Platform GUI v${Config.VERSION}');
                Sys.println('${Config.AUTHOR} | ${Config.DISCORD}');
                Sys.println("");
                Sys.println("Usage: nullkia-gui [options]");
                Sys.println("");
                Sys.println("Options:");
                Sys.println("  -k, --key KEY    License key");
                Sys.println("  -h, --help       Show help");
                Sys.println("  -v, --version    Show version");
                return;
            } else if (args[i] == "-v" || args[i] == "--version") {
                Sys.println('NullKia Cross-Platform GUI v${Config.VERSION}');
                return;
            }
            i++;
        }
        
        var menu = new Menu(license);
        menu.run();
    }
}
