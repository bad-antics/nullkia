<!-- 
SEO Keywords: NullKia, mobile security, phone hacking, Android exploitation, iOS jailbreak,
Samsung Knox bypass, bootloader unlock, firmware hacking, baseband exploitation,
checkm8, checkra1n, iPhone exploit, Pixel rooting, Titan M, OnePlus unbrick,
Xiaomi Mi Unlock, Huawei HiSuite, EDL mode, ODIN, MSM download, fastboot,
mobile pentesting, cellular security, phone forensics, SIM unlock, IMEI repair,
bad-antics, NullSec Framework, mobile red team, phone security research,
Nothing Phone, OPPO, Vivo, Realme, ASUS ROG, ZTE, Fairphone, TCL
-->

<div align="center">

# 📱 NullKia

### Mobile Security Framework v3.0.0

[![Discord](https://img.shields.io/badge/🔑_GET_KEYS-discord.gg/killers-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/killers)
[![GitHub](https://img.shields.io/badge/GitHub-bad--antics-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/bad-antics)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![Devices](https://img.shields.io/badge/Devices-500+-orange?style=for-the-badge)]()
[![Manufacturers](https://img.shields.io/badge/Manufacturers-18-blue?style=for-the-badge)]()

```
 ███╗   ██╗██╗   ██╗██╗     ██╗     ██╗  ██╗██╗ █████╗ 
 ████╗  ██║██║   ██║██║     ██║     ██║ ██╔╝██║██╔══██╗
 ██╔██╗ ██║██║   ██║██║     ██║     █████╔╝ ██║███████║
 ██║╚██╗██║██║   ██║██║     ██║     ██╔═██╗ ██║██╔══██║
 ██║ ╚████║╚██████╔╝███████╗███████╗██║  ██╗██║██║  ██║
 ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝
      [ MOBILE SECURITY FRAMEWORK v3.0 | bad-antics ]
```

### 🔓 **[Join discord.gg/killers](https://discord.gg/killers)** for encryption keys & firmware unlocks!

</div>

---

## 🆕 What's New in v3.0

- **8 New Manufacturers** — Nothing, OPPO, Vivo, Realme, ASUS, ZTE, Fairphone, TCL
- **Baseband Exploitation** — Shannon/Exynos/Qualcomm modem tools
- **eSIM Tools** — eUICC provisioning and extraction
- **5G/LTE Security** — Band locking, IMSI analysis, carrier unlock
- **iOS 17/18 Support** — Updated checkm8 toolchain
- **Android 14/15 Support** — New bypass techniques
- **GUI Mode** — Optional graphical interface
- **Plugin System** — Extend with custom modules

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
docker run -it --privileged -v /dev/bus/usb:/dev/bus/usb ghcr.io/bad-antics/nullkia:3.0
```

### GUI Mode
```bash
nullkia --gui    # Launches graphical interface
```

📖 **[Full Installation Guide](INSTALL.md)**

---

## 🎯 Features

| Feature | Description |
|---------|-------------|
| 📱 **18 Manufacturers** | Samsung, Apple, Google, OnePlus, Xiaomi, Huawei, Motorola, LG, Sony, Nokia, Nothing, OPPO, Vivo, Realme, ASUS, ZTE, Fairphone, TCL |
| ⚡ **Device Detection** | Auto-detect ADB, Fastboot, EDL, DFU, Download, BROM modes |
| 🔓 **Bootloader Tools** | Unlock bootloaders across all manufacturers |
| 📦 **Firmware Utils** | Dump, extract, flash, decrypt, and analyze firmware |
| 🛡️ **Security Bypass** | Knox, Titan M, TrustZone, TEE research tools |
| 📡 **Baseband Tools** | Modem exploitation, IMSI extraction, band manipulation |
| 📶 **Cellular Security** | 5G/LTE analysis, carrier unlock, eSIM tools |
| 🔧 **Unbrick Tools** | Recover hard-bricked devices |
| 🖥️ **Cross-Platform** | Linux, macOS, Windows, Termux, Docker |
| 🎨 **GUI Mode** | Optional graphical interface |
| 🔌 **Plugin System** | Extend with custom modules |

---

## 🚀 Usage

```bash
# Show help
nullkia help

# Launch GUI mode
nullkia --gui

# Scan for connected devices
nullkia device scan
nullkia device info          # Detailed device information

# Samsung tools
nullkia samsung knox-bypass
nullkia samsung odin
nullkia samsung frp-bypass
nullkia samsung dump-efs     # NEW: Dump EFS partition

# Apple tools (checkm8 devices)
nullkia apple checkm8
nullkia apple dfu
nullkia apple activation     # NEW: Activation bypass
nullkia apple icloud         # NEW: iCloud tools

# Google Pixel
nullkia google titan-dump    # NEW: Titan M research
nullkia google avb-bypass    # NEW: AVB bypass

# Baseband/Modem (NEW)
nullkia baseband dump        # Dump modem firmware
nullkia baseband shannon     # Samsung Shannon exploits
nullkia baseband qualcomm    # Qualcomm modem tools
nullkia baseband analyze     # Analyze baseband binary

# Cellular/Network (NEW)
nullkia cellular unlock      # Carrier unlock
nullkia cellular bands       # Band manipulation
nullkia cellular esim        # eSIM extraction/provisioning
nullkia cellular imsi        # IMSI/IMEI analysis

# Firmware operations
nullkia firmware dump
nullkia firmware flash
nullkia firmware decrypt     # NEW: Decrypt firmware
nullkia firmware analyze
nullkia firmware diff        # NEW: Compare firmware versions

# Security research
nullkia trustzone dump       # NEW: TEE extraction
nullkia bootrom dump         # NEW: BootROM extraction
nullkia secure-element       # NEW: SE research

# Plugin system (NEW)
nullkia plugin list
nullkia plugin install <name>
nullkia plugin create <name>

# Reboot device
nullkia device reboot fastboot
nullkia device reboot recovery
nullkia device reboot edl
nullkia device reboot brom   # NEW: MediaTek BROM mode
```

---

## 📱 Supported Manufacturers (18)

### Tier 1 — Full Support

| Manufacturer | Devices | Features |
|--------------|---------|----------|
| **Samsung** | Galaxy S/Note/A/M/Z series | Knox bypass, ODIN, FRP, EFS dump, Shannon baseband |
| **Apple** | iPhone 4s → iPhone X (A5-A11) | checkm8, DFU, activation bypass, iCloud tools |
| **Google** | Pixel 1-9, Tensor | Titan M research, fastboot unlock, AVB bypass |
| **OnePlus** | All models | MSM unbrick, OxygenOS tools, Engineering mode |
| **Xiaomi** | Mi/Redmi/POCO/Black Shark | Mi Unlock bypass, EDL, MIUI flash, Secure boot |

### Tier 2 — Extended Support

| Manufacturer | Devices | Features |
|--------------|---------|----------|
| **Huawei** | P/Mate/Nova (pre-2020) | HiSuite, bootloader unlock, Kirin tools |
| **OPPO** | Find/Reno/A series | ColorOS tools, MSM mode, test points |
| **Vivo** | X/V/Y series | Funtouch tools, fastboot, EDL mode |
| **Realme** | GT/Number series | Realme UI tools, deep testing |
| **Motorola** | Edge/G/Razr | Fastboot unlock, RSD Lite |
| **Nothing** | Phone (1)/(2)/(2a) | Fastboot unlock, Nothing OS tools |
| **ASUS** | ROG Phone/ZenFone | APX mode, unlock tools |

### Tier 3 — Basic Support

| Manufacturer | Devices | Features |
|--------------|---------|----------|
| **Sony** | Xperia series | Fastboot unlock, Emma tools |
| **LG** | Legacy devices | LAF mode, LGUP |
| **Nokia** | Android devices | Fastboot, OST tools |
| **ZTE** | Blade/Axon | MiFavor tools, EDL |
| **Fairphone** | FP3/FP4/FP5 | Fastboot unlock (official) |
| **TCL** | 10/20/30 series | TCL tools, EDL mode |

---

## 📡 Baseband Security (NEW in v3.0)

### Supported Modems

| Vendor | Chipsets | Capabilities |
|--------|----------|--------------|
| **Qualcomm** | SDX55, SDX65, X65, X70 | Firmware dump, diag mode, band lock |
| **Samsung Shannon** | Shannon 5100, 5123, 5300 | EFS dump, IMEI repair, NV extraction |
| **MediaTek** | Dimensity series | BROM exploit, modem dump |
| **Intel/Apple** | XMM 7560, 8160 | Legacy iPhone baseband |
| **Exynos Modem** | Exynos 5G | Research tools |

### Baseband Operations

```bash
# Dump modem firmware
nullkia baseband dump --output modem.bin

# Samsung Shannon specific
nullkia baseband shannon --extract-nv
nullkia baseband shannon --patch-imei

# Qualcomm diag mode
nullkia baseband qualcomm --diag-enable
nullkia baseband qualcomm --read-efs

# Band manipulation
nullkia cellular bands --lock "1,3,7,20,28"
nullkia cellular bands --unlock-all

# eSIM operations
nullkia cellular esim --dump-euicc
nullkia cellular esim --list-profiles
```

---

## 🔐 Security Research Tools (NEW)

### TEE/TrustZone
```bash
# Dump TrustZone components
nullkia trustzone dump --output tz_dump/

# Extract secure world binaries
nullkia trustzone extract-ta    # Trusted Applications

# Analyze TEE
nullkia trustzone analyze
```

### BootROM
```bash
# Dump BootROM (where supported)
nullkia bootrom dump --chipset exynos9825

# Exploit known vulnerabilities
nullkia bootrom exploit --checkm8    # Apple
nullkia bootrom exploit --mtk-brom   # MediaTek
```

### Secure Element
```bash
# SE research (Titan M, Knox, etc.)
nullkia secure-element info
nullkia secure-element dump-attestation
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
├── oppo/               # OPPO/ColorOS tools (NEW)
├── vivo/               # Vivo/Funtouch tools (NEW)
├── realme/             # Realme tools (NEW)
├── motorola/           # Motorola tools
├── nothing/            # Nothing Phone tools (NEW)
├── asus/               # ASUS ROG tools (NEW)
├── lg/                 # LG tools
├── sony/               # Sony tools
├── nokia/              # Nokia tools
├── zte/                # ZTE tools (NEW)
├── fairphone/          # Fairphone tools (NEW)
├── tcl/                # TCL tools (NEW)
│
├── baseband/           # Modem/baseband tools (NEW)
├── cellular/           # 5G/LTE tools (NEW)
├── trustzone/          # TEE research tools (NEW)
├── bootrom/            # BootROM tools (NEW)
├── secure-element/     # SE research (NEW)
│
├── firmware/           # Firmware utilities
├── installer/          # Platform installers
├── plugins/            # Plugin system (NEW)
├── gui/                # GUI components (NEW)
└── tools/              # Common utilities
```

---

## 🔌 Plugin System (NEW)

Extend NullKia with custom modules:

```bash
# List available plugins
nullkia plugin list

# Install community plugin
nullkia plugin install samsung-advanced
nullkia plugin install mtk-bypass

# Create your own plugin
nullkia plugin create my-plugin
```

### Plugin Structure
```
plugins/my-plugin/
├── manifest.json       # Plugin metadata
├── main.py             # Entry point
├── commands/           # CLI commands
└── lib/                # Supporting code
```

---

## 🖥️ GUI Mode (NEW)

Launch the graphical interface:

```bash
nullkia --gui
```

Features:
- Device detection dashboard
- One-click operations
- Firmware browser
- Log viewer
- Theme support (dark/light)

---

## 🔐 Encryption Keys

Some features require encryption keys available exclusively on our Discord:

🔑 **[discord.gg/killers](https://discord.gg/killers)**

- Knox bypass keys
- Firmware decryption keys
- EDL firehose loaders
- Bootloader unlock tokens
- Baseband research tools
- eSIM provisioning keys

---

## 🛠️ Requirements

| Platform | Requirements |
|----------|-------------|
| Linux | `adb`, `fastboot`, `libusb`, `python3` |
| macOS | Homebrew, `android-platform-tools` |
| Windows | USB drivers, PowerShell 5+ |
| Termux | `android-tools` package |
| Docker | Docker Desktop with USB passthrough |
| GUI | GTK3 or Qt5 |

---

## 📋 Changelog

### v3.0.0 (January 2026)
- Added 8 new manufacturers (Nothing, OPPO, Vivo, Realme, ASUS, ZTE, Fairphone, TCL)
- Baseband exploitation tools (Shannon, Qualcomm, MediaTek)
- eSIM/eUICC tools
- 5G/LTE security analysis
- TrustZone/TEE research tools
- BootROM extraction (where supported)
- Secure Element research
- GUI mode
- Plugin system
- iOS 17/18 support
- Android 14/15 support

### v2.0.0 (2025)
- Multi-manufacturer support
- Docker support
- Cross-platform installers

### v1.0.0 (2024)
- Initial release
- Samsung, Apple, Google support

---

## ⚠️ Disclaimer

This tool is for **security research and educational purposes only**. Use responsibly and only on devices you own or have explicit permission to test. The authors are not responsible for any misuse or damage.

---

## 📜 License

MIT License - [@bad-antics](https://github.com/bad-antics)

---

<div align="center">

**[⭐ Star this repo](https://github.com/bad-antics/nullkia)** | **[🔑 Get Keys](https://discord.gg/killers)** | **[🐛 Report Bug](https://github.com/bad-antics/nullkia/issues)** | **[📱 Device Request](https://github.com/bad-antics/nullkia/issues/new)**

[![GitHub](https://img.shields.io/badge/GitHub-bad--antics-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/bad-antics)
[![Discord](https://img.shields.io/badge/Discord-killers-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/killers)

**Part of the [NullSec Linux](https://github.com/bad-antics/nullsec-linux) ecosystem**

</div>

## 📱 Supported Devices

### Samsung Galaxy
- S24 Ultra, S24+, S24
- S23 Ultra, S23+, S23
- Z Fold 5, Z Flip 5
- A54 5G, A34 5G

### Apple iPhone
- iPhone 15 Pro Max, 15 Pro, 15
- iPhone 14 Pro Max, 14 Pro, 14
- iPhone SE (3rd gen)

### Google Pixel
- Pixel 8 Pro, Pixel 8
- Pixel 7 Pro, Pixel 7, Pixel 7a
- Pixel 6 Pro, Pixel 6

## 🔬 Baseband Research

| Modem | Manufacturer | Tools |
|-------|--------------|-------|
| Shannon | Samsung | shannon-dump, modem-decode |
| Snapdragon X75 | Qualcomm | qc-diag, mdm-flash |
| Dimensity 9300 | MediaTek | mtk-exploit, brom-tools |
| Apple M3 | Apple | iboot-extract, sep-dump |


<!-- Updated: 2026-01-25 13:02:45 -->

<!-- Updated: 2026-01-25 13:42:28 -->

<!-- Updated: 2026-01-25 13:42:29 -->

<!-- Updated: 2026-01-25 13:52:22 -->

<!-- Updated: 2026-01-25 18:00:09 -->

<!-- Updated: 2026-01-27 14:00:03 -->
