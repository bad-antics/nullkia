<!-- 
SEO Keywords: NullKia, mobile security, phone hacking, Android exploitation, iOS jailbreak,
Samsung Knox bypass, bootloader unlock, firmware hacking, baseband exploitation,
checkm8, checkra1n, iPhone exploit, Pixel rooting, Titan M, OnePlus unbrick,
Xiaomi Mi Unlock, Huawei HiSuite, EDL mode, ODIN, MSM download, fastboot,
mobile pentesting, cellular security, phone forensics, SIM unlock, IMEI repair,
bad-antics, NullSec Framework, mobile red team, phone security research
-->

<div align="center">

# 📱 NullKia

### Mobile Security Framework v2.0.0

[![Discord](https://img.shields.io/badge/🔑_GET_KEYS-discord.gg/killers-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/killers)
[![GitHub](https://img.shields.io/badge/GitHub-bad--antics-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/bad-antics)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

```
 ███╗   ██╗██╗   ██╗██╗     ██╗     ██╗  ██╗██╗ █████╗ 
 ████╗  ██║██║   ██║██║     ██║     ██║ ██╔╝██║██╔══██╗
 ██╔██╗ ██║██║   ██║██║     ██║     █████╔╝ ██║███████║
 ██║╚██╗██║██║   ██║██║     ██║     ██╔═██╗ ██║██╔══██║
 ██║ ╚████║╚██████╔╝███████╗███████╗██║  ██╗██║██║  ██║
 ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝
      [ MOBILE SECURITY FRAMEWORK | bad-antics ]
```

### 🔓 **[Join discord.gg/killers](https://discord.gg/killers)** for encryption keys & firmware unlocks!

</div>

---

## ⚡ Quick Install

### Linux / macOS
```bash
curl -sL https://raw.githubusercontent.com/bad-antics/nullkia/main/get-nullkia.sh | bash
```

### Windows (PowerShell as Admin)
```powershell
iwr -useb https://raw.githubusercontent.com/bad-antics/nullkia/main/install.ps1 | iex
```

### Android (Termux)
```bash
pkg install git && git clone https://github.com/bad-antics/nullkia && cd nullkia && make termux
```

### Docker
```bash
docker run -it --privileged -v /dev/bus/usb:/dev/bus/usb ghcr.io/bad-antics/nullkia
```

📖 **[Full Installation Guide](INSTALL.md)**

---

## 🎯 Features

| Feature | Description |
|---------|-------------|
| 📱 **Multi-Manufacturer** | Samsung, Apple, Google, OnePlus, Xiaomi, Huawei, Motorola, LG, Sony, Nokia |
| ⚡ **Device Detection** | Auto-detect ADB, Fastboot, EDL, DFU modes |
| 🔓 **Bootloader Tools** | Unlock bootloaders across all manufacturers |
| 📦 **Firmware Utils** | Dump, extract, flash, and analyze firmware |
| 🛡️ **Knox/Titan Bypass** | Security chip research tools |
| 🔧 **Unbrick Tools** | Recover bricked devices |
| 🖥️ **Cross-Platform** | Linux, macOS, Windows, Termux, Docker |

---

## 🚀 Usage

```bash
# Show help
nullkia help

# Scan for connected devices
nullkia device scan

# Samsung tools
nullkia samsung knox-bypass
nullkia samsung odin
nullkia samsung frp-bypass

# Apple tools (checkm8 devices)
nullkia apple checkm8
nullkia apple dfu

# Firmware operations
nullkia firmware dump
nullkia firmware flash
nullkia firmware analyze

# Reboot device
nullkia device reboot fastboot
nullkia device reboot recovery
nullkia device reboot edl
```

---

## 📂 Project Structure

```
nullkia/
├── install.sh          # Linux/macOS installer
├── install.ps1         # Windows installer
├── get-nullkia.sh      # One-line curl installer
├── Dockerfile          # Docker support
├── Makefile            # Build system
├── INSTALL.md          # Installation guide
│
├── samsung/            # Samsung/Knox tools
├── apple/              # iOS/checkm8 tools
├── google/             # Pixel/Titan M tools
├── oneplus/            # OnePlus tools
├── xiaomi/             # Xiaomi/MIUI tools
├── huawei/             # Huawei/EMUI tools
├── motorola/           # Motorola tools
├── lg/                 # LG tools
├── sony/               # Sony tools
├── nokia/              # Nokia tools
│
├── firmware/           # Firmware utilities
├── installer/          # Platform installers
└── tools/              # Common utilities
```

---

## 📱 Supported Devices

### Samsung
- Galaxy S/Note/A/M series
- Knox bypass tools
- ODIN flash mode
- FRP bypass

### Apple (checkm8)
- iPhone 4s → iPhone X (A5-A11)
- iPad 2 → iPad 7
- checkra1n jailbreak
- DFU mode tools

### Google Pixel
- Pixel 1-8 series
- Titan M research
- Fastboot unlock
- AVB bypass

### OnePlus
- All OnePlus devices
- MSM unbrick tool
- OxygenOS tools

### Xiaomi
- Mi/Redmi/POCO series
- Mi Unlock bypass
- EDL mode tools
- MIUI flash

### Huawei
- P/Mate/Nova series
- HiSuite tools
- Bootloader unlock (legacy)

---

## 🔐 Encryption Keys

Some features require encryption keys available exclusively on our Discord:

🔑 **[discord.gg/killers](https://discord.gg/killers)**

- Knox bypass keys
- Firmware decryption
- EDL loaders
- Bootloader unlock tokens

---

## 🛠️ Requirements

| Platform | Requirements |
|----------|-------------|
| Linux | `adb`, `fastboot`, `libusb` |
| macOS | Homebrew, `android-platform-tools` |
| Windows | USB drivers, PowerShell 5+ |
| Termux | `android-tools` package |
| Docker | Docker Desktop with USB passthrough |

---

## ⚠️ Disclaimer

This tool is for **security research and educational purposes only**. Use responsibly and only on devices you own or have explicit permission to test. The authors are not responsible for any misuse or damage.

---

## 📜 License

MIT License - [@bad-antics](https://github.com/bad-antics)

---

<div align="center">

**[⭐ Star this repo](https://github.com/bad-antics/nullkia)** | **[🔑 Get Keys](https://discord.gg/killers)** | **[🐛 Report Bug](https://github.com/bad-antics/nullkia/issues)**

</div>
