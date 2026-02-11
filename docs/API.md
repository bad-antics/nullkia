# NullKia API Reference

## Core Module

```python
from nullkia import NullKia

# Initialize
nk = NullKia()

# Detect device
device = nk.detect()
print(device.manufacturer, device.model, device.os_version)

# Run security audit
report = nk.audit(device)
report.save("audit_report.html")
```

## Samsung Module

```python
from nullkia.samsung import SamsungDevice

device = SamsungDevice()
device.check_knox_status()
device.dump_firmware_info()
device.check_bootloader()
```

## Forensics Module

```python
from nullkia.forensics import ForensicExtractor

fx = ForensicExtractor(device)
fx.extract_logical(output_dir="./evidence")
fx.extract_app_data("com.whatsapp")
fx.generate_report(format="html")
```
