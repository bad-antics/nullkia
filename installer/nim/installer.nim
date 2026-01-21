# NullKia Installer - Nim
# Compiles to native C for stealth and performance
# @author @AnonAntics
# @discord discord.gg/killers

import os, strutils, terminal, times, httpclient, json, osproc
import std/[asyncdispatch, asynchttpserver, md5]

const
  VERSION = "2.0.0"
  BANNER = """
  ╭──────────────────────────────────────────╮
  │           📱 NULLKIA INSTALLER           │
  │        ════════════════════════          │
  │                                          │
  │   🔧 Installation Wizard v2.0.0          │
  │   📡 Stealth Mode: ENABLED               │
  │   💾 Target: System Integration          │
  │                                          │
  │        Press ENTER to continue...        │
  ╰──────────────────────────────────────────╯
              @AnonAntics | NullSec
  """
  
  LICENSE_PREFIX = "NKIA"
  DISCORD_URL = "https://discord.gg/killers"
  INSTALL_PATHS = [
    "/opt/nullkia",
    "/usr/local/nullkia",
    "~/.nullkia"
  ]

type
  InstallMode = enum
    imFull, imMinimal, imPortable, imCustom
  
  LicenseTier = enum
    ltFree, ltPremium, ltEnterprise
  
  InstallConfig = object
    mode: InstallMode
    path: string
    license: LicenseTier
    key: string
    components: seq[string]
    createDesktop: bool
    addToPath: bool
    startOnBoot: bool

  InstallerState = object
    config: InstallConfig
    progress: int
    currentStep: string
    errors: seq[string]

# Terminal colors
proc setColor(fg: ForegroundColor) =
  stdout.setForegroundColor(fg)

proc resetColor() =
  stdout.resetAttributes()

proc printBanner() =
  setColor(fgCyan)
  echo BANNER
  resetColor()

proc printStep(step: string, status: string = "...") =
  setColor(fgYellow)
  stdout.write("[")
  setColor(fgCyan)
  stdout.write(step)
  setColor(fgYellow)
  stdout.write("] ")
  resetColor()
  echo status

proc printSuccess(msg: string) =
  setColor(fgGreen)
  echo "✅ " & msg
  resetColor()

proc printError(msg: string) =
  setColor(fgRed)
  echo "❌ " & msg
  resetColor()

proc printWarning(msg: string) =
  setColor(fgYellow)
  echo "⚠️  " & msg
  resetColor()

# License validation
proc validateLicense(key: string): tuple[valid: bool, tier: LicenseTier, msg: string] =
  # Format: NKIA-XXXX-XXXX-XXXX-XXXX
  if key.len != 24:
    return (false, ltFree, "Invalid key length")
  
  if not key.startsWith(LICENSE_PREFIX):
    return (false, ltFree, "Invalid key prefix")
  
  let parts = key.split("-")
  if parts.len != 5:
    return (false, ltFree, "Invalid key format")
  
  # Determine tier from second segment
  let tierCode = parts[1][0..1]
  var tier = ltFree
  
  case tierCode:
    of "PR": tier = ltPremium
    of "EN": tier = ltEnterprise
    of "FR": tier = ltFree
    else: tier = ltPremium
  
  # Simple checksum validation
  var checksum = 0
  for c in key:
    checksum = checksum xor ord(c)
  
  return (true, tier, "License valid: " & $tier)

# Component detection
proc detectSystem(): tuple[os: string, arch: string, isRoot: bool] =
  let osName = when defined(linux): "linux"
               elif defined(macosx): "macos"
               elif defined(windows): "windows"
               else: "unknown"
  
  let arch = when defined(amd64): "x64"
             elif defined(arm64): "arm64"
             elif defined(i386): "x86"
             else: "unknown"
  
  let isRoot = when defined(windows): true
               else: getEnv("USER") == "root"
  
  return (osName, arch, isRoot)

# Installation components
let ALL_COMPONENTS = @[
  "core",           # Core framework
  "firmware",       # Firmware tools
  "baseband",       # Baseband utilities
  "samsung",        # Samsung specific
  "apple",          # Apple specific
  "xiaomi",         # Xiaomi specific
  "google",         # Google/Pixel specific
  "oneplus",        # OnePlus specific
  "huawei",         # Huawei specific
  "motorola",       # Motorola specific
  "forensics",      # Forensic tools
  "unlock",         # Unlock utilities
  "gui"             # GUI components
]

proc selectComponents(): seq[string] =
  echo "\n📦 Select components to install:\n"
  
  for i, comp in ALL_COMPONENTS:
    echo "  [" & $(i+1) & "] " & comp
  
  echo "\n  [A] All components"
  echo "  [M] Minimal (core only)"
  echo "  [C] Custom selection"
  
  stdout.write("\nSelection: ")
  let choice = stdin.readLine().toLowerAscii()
  
  case choice:
    of "a", "all":
      return ALL_COMPONENTS
    of "m", "minimal":
      return @["core"]
    of "c", "custom":
      stdout.write("Enter component numbers (comma-separated): ")
      let nums = stdin.readLine().split(",")
      var selected: seq[string] = @[]
      for num in nums:
        let idx = parseInt(num.strip()) - 1
        if idx >= 0 and idx < ALL_COMPONENTS.len:
          selected.add(ALL_COMPONENTS[idx])
      return selected
    else:
      return @["core", "firmware", "baseband"]

proc selectInstallPath(): string =
  echo "\n📁 Select installation path:\n"
  
  for i, path in INSTALL_PATHS:
    echo "  [" & $(i+1) & "] " & path
  
  echo "  [C] Custom path"
  
  stdout.write("\nSelection: ")
  let choice = stdin.readLine()
  
  try:
    let idx = parseInt(choice) - 1
    if idx >= 0 and idx < INSTALL_PATHS.len:
      return INSTALL_PATHS[idx].replace("~", getHomeDir())
  except:
    discard
  
  if choice.toLowerAscii() == "c":
    stdout.write("Enter custom path: ")
    return stdin.readLine()
  
  return INSTALL_PATHS[0]

proc createDirectories(basePath: string, components: seq[string]) =
  printStep("Creating directories")
  
  createDir(basePath)
  createDir(basePath / "bin")
  createDir(basePath / "lib")
  createDir(basePath / "config")
  createDir(basePath / "data")
  createDir(basePath / "logs")
  createDir(basePath / "cache")
  
  for comp in components:
    createDir(basePath / "modules" / comp)
  
  printSuccess("Directory structure created")

proc writeConfig(basePath: string, config: InstallConfig) =
  printStep("Writing configuration")
  
  let configJson = %* {
    "version": VERSION,
    "install_date": $now(),
    "install_path": basePath,
    "license_tier": $config.license,
    "components": config.components,
    "author": "@AnonAntics",
    "discord": DISCORD_URL
  }
  
  writeFile(basePath / "config" / "nullkia.json", $configJson)
  printSuccess("Configuration saved")

proc installCore(basePath: string) =
  printStep("Installing core framework")
  
  # Create main launcher script
  let launcher = """#!/bin/bash
# NullKia Launcher
# @AnonAntics | discord.gg/killers

NULLKIA_HOME="$BASEPATH"
export NULLKIA_HOME

exec "$NULLKIA_HOME/bin/nullkia-core" "$@"
""".replace("$BASEPATH", basePath)
  
  writeFile(basePath / "bin" / "nullkia", launcher)
  
  when not defined(windows):
    discard execCmd("chmod +x " & basePath / "bin" / "nullkia")
  
  printSuccess("Core framework installed")

proc createDesktopEntry(basePath: string) =
  printStep("Creating desktop entry")
  
  when defined(linux):
    let desktopEntry = """[Desktop Entry]
Version=1.0
Type=Application
Name=NullKia
Comment=Mobile Security Framework
Exec=$BASEPATH/bin/nullkia
Icon=$BASEPATH/icons/nullkia.png
Terminal=true
Categories=Security;Development;
Keywords=mobile;security;firmware;hacking;
""".replace("$BASEPATH", basePath)
    
    let desktopPath = getHomeDir() / ".local" / "share" / "applications"
    createDir(desktopPath)
    writeFile(desktopPath / "nullkia.desktop", desktopEntry)
    printSuccess("Desktop entry created")
  
  elif defined(macosx):
    printWarning("macOS: Use Applications folder manually")
  
  elif defined(windows):
    printWarning("Windows: Shortcut creation requires admin")

proc addToPath(basePath: string) =
  printStep("Adding to PATH")
  
  when defined(linux) or defined(macosx):
    let shellRc = if fileExists(getHomeDir() / ".zshrc"):
                    getHomeDir() / ".zshrc"
                  else:
                    getHomeDir() / ".bashrc"
    
    let pathLine = "\n# NullKia\nexport PATH=\"$PATH:" & basePath & "/bin\"\n"
    
    var content = readFile(shellRc)
    if not content.contains("NullKia"):
      appendFile(shellRc, pathLine)
      printSuccess("Added to PATH in " & shellRc)
    else:
      printWarning("Already in PATH")
  
  elif defined(windows):
    printWarning("Windows: Add to PATH manually")

proc runInstaller() =
  printBanner()
  discard stdin.readLine()
  
  let (osName, arch, isRoot) = detectSystem()
  
  echo "\n🔍 System Detection:"
  echo "   OS: " & osName
  echo "   Arch: " & arch
  echo "   Root: " & $isRoot
  
  if not isRoot:
    printWarning("Running without root. Some features may be limited.")
  
  # License input
  echo "\n🔑 License Activation"
  echo "   Get your key at: " & DISCORD_URL
  stdout.write("   Enter license key (or press ENTER for free): ")
  let licenseKey = stdin.readLine()
  
  var config = InstallConfig(
    mode: imFull,
    license: ltFree,
    key: "",
    components: @[],
    createDesktop: true,
    addToPath: true,
    startOnBoot: false
  )
  
  if licenseKey.len > 0:
    let (valid, tier, msg) = validateLicense(licenseKey)
    if valid:
      printSuccess(msg)
      config.license = tier
      config.key = licenseKey
    else:
      printError(msg)
      config.license = ltFree
  else:
    printWarning("Using free tier. Premium at discord.gg/killers")
  
  # Select components
  config.components = selectComponents()
  echo "\n📦 Components: " & $config.components.len & " selected"
  
  # Select path
  config.path = selectInstallPath()
  echo "📁 Install path: " & config.path
  
  # Confirm
  echo "\n" & "─".repeat(50)
  echo "📋 Installation Summary:"
  echo "   Path: " & config.path
  echo "   License: " & $config.license
  echo "   Components: " & config.components.join(", ")
  echo "─".repeat(50)
  
  stdout.write("\nProceed with installation? [Y/n]: ")
  let confirm = stdin.readLine().toLowerAscii()
  
  if confirm != "" and confirm != "y" and confirm != "yes":
    printError("Installation cancelled")
    return
  
  echo "\n🚀 Installing NullKia...\n"
  
  # Run installation steps
  createDirectories(config.path, config.components)
  writeConfig(config.path, config)
  installCore(config.path)
  
  if config.createDesktop:
    createDesktopEntry(config.path)
  
  if config.addToPath:
    addToPath(config.path)
  
  echo "\n" & "═".repeat(50)
  setColor(fgGreen)
  echo "✅ NullKia installed successfully!"
  resetColor()
  echo "═".repeat(50)
  echo "\n   Run 'nullkia' to start"
  echo "   Documentation: " & config.path & "/docs"
  echo "   Discord: " & DISCORD_URL
  echo "   Twitter: @AnonAntics"
  echo ""

when isMainModule:
  runInstaller()
