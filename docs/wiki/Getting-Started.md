# Getting Started

## Prerequisites

```bash
# Python 3.9+
python3 --version

# Android tools
sudo apt install android-tools-adb android-tools-fastboot

# USB permissions (Linux)
sudo usermod -aG plugdev $USER
```

## Installation

```bash
git clone https://github.com/bad-antics/nullkia
cd nullkia
pip install -r requirements.txt
```

## Quick Start

```bash
# Detect connected device
python3 nullkia.py detect

# Run full security audit
python3 nullkia.py audit --device <device-id>

# Check bootloader status
python3 nullkia.py bootloader --status

# Extract firmware info
python3 nullkia.py firmware --info
```

## Device Connection

### Android (USB Debugging)
1. Enable Developer Options (tap Build Number 7x)
2. Enable USB Debugging
3. Connect via USB
4. Authorize the computer on device

### iOS
1. Install libimobiledevice: `sudo apt install libimobiledevice-utils`
2. Connect via USB
3. Trust the computer on device

## Configuration

```yaml
# ~/.nullkia/config.yaml
device_db: /path/to/device-database.json
log_level: info
output_dir: ~/nullkia-output
modules:
  samsung: enabled
  apple: enabled
  google: enabled
  xiaomi: enabled
```
