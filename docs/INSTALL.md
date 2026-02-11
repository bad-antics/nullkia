# NullKia Installation

## Requirements
- Python 3.9+
- Android Platform Tools (adb, fastboot)
- libimobiledevice (for iOS)
- libusb

## Linux
```bash
sudo apt install android-tools-adb android-tools-fastboot libimobiledevice-utils python3-pip
git clone https://github.com/bad-antics/nullkia
cd nullkia
pip install -r requirements.txt
```

## macOS
```bash
brew install android-platform-tools libimobiledevice
git clone https://github.com/bad-antics/nullkia
cd nullkia
pip3 install -r requirements.txt
```

## Arch Linux
```bash
sudo pacman -S android-tools libimobiledevice python-pip
git clone https://github.com/bad-antics/nullkia
cd nullkia
pip install -r requirements.txt
```
