# 📱 NullKia Installation Guide

## Quick Install (Recommended)

### Linux / macOS
```bash
curl -sL https://raw.githubusercontent.com/bad-antics/nullkia/main/get-nullkia.sh | bash
```

### Windows (PowerShell as Admin)
```powershell
iwr -useb https://raw.githubusercontent.com/bad-antics/nullkia/main/install.ps1 | iex
```

---

## Manual Installation

### Linux

```bash
# Clone repository
git clone https://github.com/bad-antics/nullkia.git
cd nullkia

# Run installer
chmod +x install.sh
./install.sh

# Or use make
make install
```

### macOS

```bash
# Install via Homebrew dependencies first
brew install android-platform-tools libusb

# Clone and install
git clone https://github.com/bad-antics/nullkia.git
cd nullkia
./install.sh
```

### Windows

1. Download and extract from [Releases](https://github.com/bad-antics/nullkia/releases)
2. Right-click `install.ps1` → "Run with PowerShell"
3. Or run in elevated PowerShell:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process
   .\install.ps1
   ```

### Android (Termux)

```bash
# Install Termux from F-Droid (NOT Play Store)
pkg update && pkg upgrade
pkg install git android-tools

# Clone and install
git clone https://github.com/bad-antics/nullkia.git
cd nullkia
make termux
```

### Docker

```bash
# Build image
docker build -t nullkia .

# Run with USB access (Linux)
docker run -it --privileged \
  -v /dev/bus/usb:/dev/bus/usb \
  nullkia

# Run with USB access (macOS - requires Docker Desktop)
docker run -it --privileged nullkia
```

---

## Post-Installation

### Verify Installation
```bash
nullkia --version
nullkia help
nullkia device scan
```

### Configure USB Access (Linux)
```bash
# Add yourself to plugdev group
sudo usermod -aG plugdev $USER

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Log out and back in
```

### Enable USB Debugging (Android Device)
1. Go to **Settings → About Phone**
2. Tap **Build Number** 7 times to enable Developer Options
3. Go to **Settings → Developer Options**
4. Enable **USB Debugging**
5. Connect device and authorize computer

---

## Platform-Specific Notes

### Samsung
- Install Samsung USB drivers from [developer.samsung.com](https://developer.samsung.com)
- ODIN mode: Power off, hold Vol Down + Power while connecting USB

### Google Pixel
- Unlock bootloader: `fastboot flashing unlock`
- May need to disable Titan M: Settings → Security → Advanced

### OnePlus
- OEM unlock in Developer Options
- MSM Tool for unbrick: [oneplus.com](https://oneplus.com)

### Xiaomi
- Mi Unlock Tool required (7-day wait period)
- EDL mode: Hold Vol Down while connecting

### Huawei
- Bootloader unlock codes discontinued (use DC-Unlocker)
- HiSuite for firmware updates

### Apple (checkm8)
- Supported: iPhone 4s - iPhone X (A5-A11 chips)
- Enter DFU: Connect → Hold Power + Home 10s → Release Power

---

## Uninstall

### Linux / macOS
```bash
./install.sh --uninstall
# or
make uninstall
```

### Windows
```powershell
# Remove directories
Remove-Item -Recurse "$env:USERPROFILE\.nullkia"
Remove-Item -Recurse "$env:APPDATA\nullkia"
Remove-Item "$env:USERPROFILE\.local\bin\nullkia.*"
```

---

## Troubleshooting

### Device not detected
```bash
# Check USB connection
lsusb | grep -i "samsung\|google\|xiaomi"

# Restart ADB
adb kill-server
adb start-server
adb devices
```

### Permission denied
```bash
# Linux: Add udev rules
sudo cp installer/51-nullkia.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
```

### Windows driver issues
1. Device Manager → Find device with yellow warning
2. Update driver → Browse → Select Google USB Driver

---

## Get Help

- **Twitter**: [x.com/AnonAntics](https://x.com/AnonAntics) - Get encryption keys here!
- **GitHub Issues**: [github.com/bad-antics/nullkia/issues](https://github.com/bad-antics/nullkia/issues)

---

*NullKia v2.0.0 - Mobile Security Framework by [@bad-antics](https://github.com/bad-antics)*
