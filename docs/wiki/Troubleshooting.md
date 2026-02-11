# Troubleshooting

## Device Not Detected

### Android
```bash
# Check ADB connection
adb devices
# If empty, try:
adb kill-server && adb start-server
# Check USB permissions
ls -la /dev/bus/usb/
```

### iOS
```bash
# Check idevice connection
idevice_id -l
# If empty, re-trust computer on device
idevicepair unpair && idevicepair pair
```

## Samsung Knox Locked

Knox e-fuse is a one-time hardware flag. If tripped:
- Cannot be reversed
- Some Samsung Pay/Secure Folder features lost
- Device still fully functional for security research

## Bootloader Won't Unlock

Some manufacturers require:
1. **Developer account** (Xiaomi Mi Unlock)
2. **Waiting period** (7-30 days for some OEMs)
3. **OEM unlock toggle** in Developer Options
4. **Carrier unlock** (carrier-locked devices)

## Permission Denied

```bash
# Fix ADB permissions on Linux
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666"' | sudo tee /etc/udev/rules.d/51-android.rules
sudo udevadm control --reload-rules
```
