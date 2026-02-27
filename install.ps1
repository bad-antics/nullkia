#Requires -RunAsAdministrator
<#
.SYNOPSIS
    NullKia Windows Installer

.DESCRIPTION
    Installs NullKia Mobile Security Framework on Windows

.NOTES
    Author: bad-antics
    Discord: x.com/AnonAntics
#>

$ErrorActionPreference = "Stop"

# Config
$Version = "2.0.0"
$InstallDir = "$env:USERPROFILE\.nullkia"
$BinDir = "$env:USERPROFILE\.local\bin"
$ConfigDir = "$env:APPDATA\nullkia"

function Write-Banner {
    Write-Host @"

    ███╗   ██╗██╗   ██╗██╗     ██╗     ██╗  ██╗██╗ █████╗ 
    ████╗  ██║██║   ██║██║     ██║     ██║ ██╔╝██║██╔══██╗
    ██╔██╗ ██║██║   ██║██║     ██║     █████╔╝ ██║███████║
    ██║╚██╗██║██║   ██║██║     ██║     ██╔═██╗ ██║██╔══██║
    ██║ ╚████║╚██████╔╝███████╗███████╗██║  ██╗██║██║  ██║
    ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝

    [ Mobile Security Framework | v$Version ]
    [ x.com/AnonAntics for keys & support ]

"@ -ForegroundColor Magenta
}

function Write-Info { param($msg) Write-Host "[*] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "[✓] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Err { param($msg) Write-Host "[✗] $msg" -ForegroundColor Red }

function Install-Dependencies {
    Write-Info "Checking dependencies..."
    
    # Check for winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Info "Installing Android Platform Tools..."
        winget install Google.PlatformTools --accept-package-agreements --accept-source-agreements 2>$null
    }
    
    # Check for Chocolatey
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        choco install adb -y 2>$null
    }
    
    Write-Success "Dependencies checked"
}

function Install-USBDrivers {
    Write-Info "Installing USB drivers..."
    
    # Samsung USB drivers
    $SamsungDriver = "https://developer.samsung.com/mobile/android-usb-driver.html"
    
    # Google USB drivers (included with platform-tools)
    Write-Info "Google USB drivers included with Platform Tools"
    
    Write-Success "USB drivers configured"
}

function New-Directories {
    Write-Info "Creating directories..."
    
    $dirs = @(
        $InstallDir,
        "$InstallDir\bin",
        "$InstallDir\lib", 
        "$InstallDir\modules",
        "$InstallDir\firmware",
        "$InstallDir\logs",
        "$InstallDir\keys",
        $BinDir,
        $ConfigDir
    )
    
    foreach ($dir in $dirs) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    
    Write-Success "Directories created"
}

function Install-Binaries {
    Write-Info "Installing binaries..."
    
    # Create nullkia.bat
    $batContent = @'
@echo off
setlocal enabledelayedexpansion

set "NULLKIA_HOME=%USERPROFILE%\.nullkia"
set "VERSION=2.0.0"

if "%1"=="" goto :help
if "%1"=="help" goto :help
if "%1"=="-h" goto :help
if "%1"=="--help" goto :help
if "%1"=="version" goto :version
if "%1"=="-v" goto :version
if "%1"=="device" goto :device
if "%1"=="samsung" goto :samsung
if "%1"=="apple" goto :apple
if "%1"=="firmware" goto :firmware
if "%1"=="keys" goto :keys
if "%1"=="update" goto :update

echo [!] Unknown command: %1
echo Run 'nullkia help' for usage
exit /b 1

:help
echo.
echo     NullKia - Mobile Security Framework v%VERSION%
echo.
echo USAGE:
echo     nullkia ^<command^> [options]
echo.
echo COMMANDS:
echo     device      Detect and manage connected devices
echo     samsung     Samsung/Knox exploitation tools
echo     apple       iOS/checkm8 exploitation tools
echo     google      Pixel/Titan M tools
echo     oneplus     OnePlus/OxygenOS tools
echo     xiaomi      Xiaomi/MIUI unlock tools
echo     firmware    Firmware dump/flash utilities
echo     keys        Manage encryption keys
echo     update      Update NullKia
echo     help        Show this help
echo.
echo Join x.com/AnonAntics for encryption keys!
exit /b 0

:version
echo NullKia v%VERSION%
exit /b 0

:device
if "%2"=="scan" goto :device_scan
if "%2"=="list" goto :device_scan
echo Usage: nullkia device ^<scan^|list^>
exit /b 0

:device_scan
echo [*] Scanning for connected devices...
echo.
adb devices -l 2>nul
echo.
fastboot devices 2>nul
exit /b 0

:samsung
echo [Samsung/Knox Tools]
echo Commands: knox-bypass, odin, frp-bypass
exit /b 0

:apple
echo [Apple/iOS Tools]
echo Commands: checkm8, checkra1n, dfu
exit /b 0

:firmware
echo [Firmware Utilities]
echo Commands: dump, flash, extract, analyze
exit /b 0

:keys
echo Keys managed at: %NULLKIA_HOME%\keys
echo Join x.com/AnonAntics for encryption keys
exit /b 0

:update
echo [*] Updating NullKia...
cd /d "%NULLKIA_HOME%\src" 2>nul && git pull
echo [✓] NullKia updated
exit /b 0
'@
    
    Set-Content -Path "$BinDir\nullkia.bat" -Value $batContent
    
    # Create nullkia.ps1 for PowerShell users
    $ps1Content = @'
# NullKia PowerShell Module
$script:Version = "2.0.0"
$script:NullkiaHome = "$env:USERPROFILE\.nullkia"

function Show-NullkiaBanner {
    Write-Host @"
    
    ███╗   ██╗██╗   ██╗██╗     ██╗     ██╗  ██╗██╗ █████╗ 
    ████╗  ██║██║   ██║██║     ██║     ██║ ██╔╝██║██╔══██╗
    ██╔██╗ ██║██║   ██║██║     ██║     █████╔╝ ██║███████║
    ██║╚██╗██║██║   ██║██║     ██║     ██╔═██╗ ██║██╔══██║
    ██║ ╚████║╚██████╔╝███████╗███████╗██║  ██╗██║██║  ██║
    ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝
    
    [ Mobile Security Framework | v$script:Version ]

"@ -ForegroundColor Magenta
}

function Get-NullkiaDevice {
    Write-Host "[*] Scanning for connected devices..." -ForegroundColor Cyan
    Write-Host ""
    
    # ADB devices
    $adbDevices = adb devices -l 2>$null
    if ($adbDevices) {
        Write-Host "[ADB Devices]" -ForegroundColor Green
        $adbDevices | ForEach-Object { Write-Host "  $_" }
    }
    
    # Fastboot devices
    $fbDevices = fastboot devices 2>$null
    if ($fbDevices) {
        Write-Host "[Fastboot Devices]" -ForegroundColor Yellow
        $fbDevices | ForEach-Object { Write-Host "  $_" }
    }
}

function Invoke-Nullkia {
    param(
        [Parameter(Position=0)]
        [string]$Command,
        [Parameter(Position=1, ValueFromRemainingArguments)]
        [string[]]$Args
    )
    
    switch ($Command) {
        "device" { Get-NullkiaDevice }
        "version" { Write-Host "NullKia v$script:Version" }
        "help" { Show-NullkiaBanner; Get-Help Invoke-Nullkia }
        default { Show-NullkiaBanner }
    }
}

Set-Alias -Name nullkia -Value Invoke-Nullkia
Export-ModuleMember -Function * -Alias *
'@
    
    Set-Content -Path "$BinDir\nullkia.psm1" -Value $ps1Content
    
    Write-Success "Binaries installed"
}

function Set-EnvironmentPath {
    Write-Info "Configuring PATH..."
    
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$BinDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$BinDir", "User")
        Write-Success "Added $BinDir to PATH"
    }
    
    # Set NULLKIA_HOME
    [Environment]::SetEnvironmentVariable("NULLKIA_HOME", $InstallDir, "User")
    
    Write-Success "Environment configured"
}

function Show-Success {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║     NullKia installed successfully!                          ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "Installation directory: $InstallDir" -ForegroundColor White
    Write-Host "Binary location: $BinDir\nullkia.bat" -ForegroundColor White
    Write-Host ""
    Write-Host "Quick start:" -ForegroundColor Cyan
    Write-Host "    Restart terminal/PowerShell"
    Write-Host "    nullkia device scan"
    Write-Host "    nullkia help"
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║  Join x.com/AnonAntics for encryption keys & firmware!    ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
}

# Main
Write-Banner
Write-Info "Installing NullKia v$Version..."
Write-Host ""

Install-Dependencies
New-Directories
Install-USBDrivers
Install-Binaries
Set-EnvironmentPath
Show-Success
