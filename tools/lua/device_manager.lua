#!/usr/bin/env lua
-- ═══════════════════════════════════════════════════════════════════
--  NULLKIA LUA DEVICE MANAGER
--  Lightweight scripting for device management
--  @author bad-antics | discord.gg/killers
-- ═══════════════════════════════════════════════════════════════════

local VERSION = "2.0.0"
local AUTHOR = "bad-antics"
local DISCORD = "discord.gg/killers"

local BANNER = [[
╭──────────────────────────────────────────╮
│      📱 NULLKIA LUA DEVICE MANAGER       │
│      ══════════════════════════════      │
│                                          │
│   🔧 Lightweight Device Management       │
│   📡 ADB/Fastboot Integration            │
│   💾 Firmware Operations                 │
│                                          │
│          bad-antics | NullSec            │
╰──────────────────────────────────────────╯
]]

-- ═══════════════════════════════════════════════════════════════════
-- Utility Functions
-- ═══════════════════════════════════════════════════════════════════

local colors = {
    reset = "\27[0m",
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    cyan = "\27[36m",
    white = "\27[37m"
}

local function printColored(color, msg)
    print(color .. msg .. colors.reset)
end

local function printSuccess(msg)
    printColored(colors.green, "✅ " .. msg)
end

local function printError(msg)
    printColored(colors.red, "❌ " .. msg)
end

local function printWarning(msg)
    printColored(colors.yellow, "⚠️  " .. msg)
end

local function printInfo(msg)
    printColored(colors.cyan, "ℹ️  " .. msg)
end

local function execute(cmd)
    local handle = io.popen(cmd .. " 2>&1")
    if not handle then return nil, "Failed to execute command" end
    local result = handle:read("*a")
    local success = handle:close()
    return result, success
end

local function fileExists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

-- ═══════════════════════════════════════════════════════════════════
-- License Management
-- ═══════════════════════════════════════════════════════════════════

local LicenseTier = {
    FREE = "Free",
    PREMIUM = "Premium ⭐",
    ENTERPRISE = "Enterprise 💎"
}

local function validateLicense(key)
    if not key or #key ~= 24 then
        return { valid = false, tier = LicenseTier.FREE }
    end
    
    if not key:match("^NKIA%-") then
        return { valid = false, tier = LicenseTier.FREE }
    end
    
    local parts = {}
    for part in key:gmatch("([^%-]+)") do
        table.insert(parts, part)
    end
    
    if #parts ~= 5 then
        return { valid = false, tier = LicenseTier.FREE }
    end
    
    local tierCode = parts[2]:sub(1, 2)
    local tier = LicenseTier.FREE
    
    if tierCode == "PR" then
        tier = LicenseTier.PREMIUM
    elseif tierCode == "EN" then
        tier = LicenseTier.ENTERPRISE
    end
    
    return { valid = true, tier = tier, key = key }
end

-- ═══════════════════════════════════════════════════════════════════
-- Device Detection
-- ═══════════════════════════════════════════════════════════════════

local DeviceManager = {}
DeviceManager.__index = DeviceManager

function DeviceManager.new()
    local self = setmetatable({}, DeviceManager)
    self.devices = {}
    self.license = { valid = false, tier = LicenseTier.FREE }
    return self
end

function DeviceManager:setLicense(key)
    self.license = validateLicense(key)
    if self.license.valid then
        printSuccess("License activated: " .. self.license.tier)
    end
end

function DeviceManager:isPremium()
    return self.license.valid and self.license.tier ~= LicenseTier.FREE
end

function DeviceManager:detectADBDevices()
    print("\n  🔍 Detecting ADB devices...\n")
    
    local result, success = execute("adb devices -l")
    if not result then
        printError("ADB not found or not working")
        return {}
    end
    
    self.devices = {}
    local lines = {}
    for line in result:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    
    for i = 2, #lines do
        local line = lines[i]
        if line and #trim(line) > 0 then
            local serial = line:match("^(%S+)")
            local status = line:match("device") and "device" or "offline"
            local model = line:match("model:(%S+)") or "Unknown"
            local product = line:match("product:(%S+)") or "Unknown"
            
            if serial and serial ~= "" then
                table.insert(self.devices, {
                    serial = serial,
                    status = status,
                    model = model,
                    product = product,
                    mode = "adb"
                })
            end
        end
    end
    
    return self.devices
end

function DeviceManager:detectFastbootDevices()
    print("  🔍 Detecting Fastboot devices...\n")
    
    local result, success = execute("fastboot devices -l")
    if not result then
        printWarning("Fastboot not found")
        return {}
    end
    
    for line in result:gmatch("[^\r\n]+") do
        local serial = line:match("^(%S+)")
        if serial and serial ~= "" then
            -- Check if already in list
            local found = false
            for _, dev in ipairs(self.devices) do
                if dev.serial == serial then
                    dev.mode = "fastboot"
                    found = true
                    break
                end
            end
            
            if not found then
                table.insert(self.devices, {
                    serial = serial,
                    status = "fastboot",
                    model = "Unknown",
                    product = "Unknown",
                    mode = "fastboot"
                })
            end
        end
    end
    
    return self.devices
end

function DeviceManager:listDevices()
    print("  ═══════════════════════════════════════════")
    print("  📱 CONNECTED DEVICES")
    print("  ═══════════════════════════════════════════\n")
    
    if #self.devices == 0 then
        printWarning("No devices connected")
        print("     Connect a device via USB with debugging enabled")
        return
    end
    
    for i, dev in ipairs(self.devices) do
        print(string.format("  [%d] %s", i, dev.serial))
        print(string.format("      Model: %s | Product: %s", dev.model, dev.product))
        print(string.format("      Mode: %s | Status: %s", dev.mode, dev.status))
        print("")
    end
end

function DeviceManager:getDeviceInfo(serial)
    if not self:isPremium() then
        printWarning("Premium feature - Get keys at discord.gg/killers")
        return nil
    end
    
    print("\n  📊 Getting device info for: " .. serial .. "\n")
    
    local info = {}
    
    -- Get various properties
    local props = {
        "ro.product.model",
        "ro.product.brand",
        "ro.product.device",
        "ro.build.version.release",
        "ro.build.version.sdk",
        "ro.build.fingerprint",
        "ro.serialno",
        "ro.bootimage.build.date",
        "ro.hardware"
    }
    
    for _, prop in ipairs(props) do
        local cmd = string.format("adb -s %s shell getprop %s", serial, prop)
        local result = execute(cmd)
        if result then
            info[prop] = trim(result)
        end
    end
    
    -- Display info
    print("  ────────────────────────────────────────")
    for prop, value in pairs(info) do
        print(string.format("  %s: %s", prop, value))
    end
    print("  ────────────────────────────────────────")
    
    return info
end

function DeviceManager:rebootDevice(serial, mode)
    mode = mode or "system"
    
    local validModes = {
        system = "",
        recovery = "recovery",
        bootloader = "bootloader",
        fastboot = "bootloader",
        download = "download"
    }
    
    if not validModes[mode] then
        printError("Invalid reboot mode: " .. mode)
        return false
    end
    
    print(string.format("\n  🔄 Rebooting %s to %s...\n", serial, mode))
    
    local cmd
    if validModes[mode] == "" then
        cmd = string.format("adb -s %s reboot", serial)
    else
        cmd = string.format("adb -s %s reboot %s", serial, validModes[mode])
    end
    
    local result, success = execute(cmd)
    
    if success then
        printSuccess("Reboot command sent")
    else
        printError("Reboot failed")
    end
    
    return success
end

function DeviceManager:pullFile(serial, remotePath, localPath)
    print(string.format("\n  📥 Pulling file: %s\n", remotePath))
    
    local cmd = string.format("adb -s %s pull '%s' '%s'", serial, remotePath, localPath)
    local result, success = execute(cmd)
    
    if success and fileExists(localPath) then
        printSuccess("File pulled successfully to: " .. localPath)
        return true
    else
        printError("Failed to pull file")
        return false
    end
end

function DeviceManager:pushFile(serial, localPath, remotePath)
    if not fileExists(localPath) then
        printError("Local file not found: " .. localPath)
        return false
    end
    
    print(string.format("\n  📤 Pushing file: %s\n", localPath))
    
    local cmd = string.format("adb -s %s push '%s' '%s'", serial, localPath, remotePath)
    local result, success = execute(cmd)
    
    if success then
        printSuccess("File pushed successfully")
        return true
    else
        printError("Failed to push file")
        return false
    end
end

function DeviceManager:shellCommand(serial, command)
    print(string.format("\n  💻 Executing: %s\n", command))
    
    local cmd = string.format("adb -s %s shell '%s'", serial, command)
    local result, success = execute(cmd)
    
    if result then
        print(result)
    end
    
    return result, success
end

-- ═══════════════════════════════════════════════════════════════════
-- Menu System
-- ═══════════════════════════════════════════════════════════════════

local function showMenu(dm)
    while true do
        print("\n  ═══════════════════════════════════════════")
        print("  📱 NULLKIA LUA MENU")
        print("  ═══════════════════════════════════════════\n")
        
        print("  [1] Detect Devices")
        print("  [2] List Devices")
        print("  [3] Device Info (Premium)")
        print("  [4] Reboot Device")
        print("  [5] Shell Command")
        print("  [6] Pull File")
        print("  [7] Push File")
        print("  [8] Enter License Key")
        print("  [0] Exit")
        print("")
        
        io.write("  Select: ")
        local choice = io.read()
        
        if choice == "1" then
            dm:detectADBDevices()
            dm:detectFastbootDevices()
            printSuccess("Detection complete. Found " .. #dm.devices .. " device(s)")
            
        elseif choice == "2" then
            dm:listDevices()
            
        elseif choice == "3" then
            if #dm.devices == 0 then
                printWarning("No devices. Run detection first.")
            else
                io.write("  Device serial: ")
                local serial = io.read()
                dm:getDeviceInfo(serial)
            end
            
        elseif choice == "4" then
            if #dm.devices == 0 then
                printWarning("No devices. Run detection first.")
            else
                io.write("  Device serial: ")
                local serial = io.read()
                io.write("  Mode (system/recovery/bootloader): ")
                local mode = io.read()
                dm:rebootDevice(serial, mode)
            end
            
        elseif choice == "5" then
            if #dm.devices == 0 then
                printWarning("No devices. Run detection first.")
            else
                io.write("  Device serial: ")
                local serial = io.read()
                io.write("  Command: ")
                local cmd = io.read()
                dm:shellCommand(serial, cmd)
            end
            
        elseif choice == "6" then
            io.write("  Device serial: ")
            local serial = io.read()
            io.write("  Remote path: ")
            local remote = io.read()
            io.write("  Local path: ")
            local local_path = io.read()
            dm:pullFile(serial, remote, local_path)
            
        elseif choice == "7" then
            io.write("  Device serial: ")
            local serial = io.read()
            io.write("  Local path: ")
            local local_path = io.read()
            io.write("  Remote path: ")
            local remote = io.read()
            dm:pushFile(serial, local_path, remote)
            
        elseif choice == "8" then
            io.write("  License key: ")
            local key = io.read()
            dm:setLicense(key)
            
        elseif choice == "0" then
            break
        else
            printError("Invalid option")
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- Main Entry Point
-- ═══════════════════════════════════════════════════════════════════

local function main()
    printColored(colors.cyan, BANNER)
    print("  Version " .. VERSION .. " | " .. AUTHOR)
    print("  🔑 Premium: " .. DISCORD .. "\n")
    
    local dm = DeviceManager.new()
    
    -- Check for license key in args
    if arg and arg[1] then
        if arg[1] == "-k" or arg[1] == "--key" then
            if arg[2] then
                dm:setLicense(arg[2])
            end
        elseif arg[1] == "-h" or arg[1] == "--help" then
            print("  Usage: lua device_manager.lua [options]")
            print("")
            print("  Options:")
            print("    -k, --key KEY    License key")
            print("    -h, --help       Show help")
            print("    -v, --version    Show version")
            return
        elseif arg[1] == "-v" or arg[1] == "--version" then
            print("  NullKia Lua Device Manager v" .. VERSION)
            return
        end
    end
    
    showMenu(dm)
    
    -- Footer
    print("\n─────────────────────────────────────────")
    print("  📱 NullKia Lua Device Manager")
    print("  🔑 Premium: discord.gg/killers")
    print("  👤 Author: bad-antics")
    print("─────────────────────────────────────────\n")
end

main()
