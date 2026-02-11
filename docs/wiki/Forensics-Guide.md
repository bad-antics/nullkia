# Mobile Forensics Guide

## Workflow Overview

```
Device Acquisition → Data Extraction → Analysis → Reporting
```

## 1. Device Acquisition

### Physical Acquisition
- Full bit-for-bit image of device storage
- Requires root/jailbreak or exploit
- Most comprehensive but invasive

### Logical Acquisition
- File system level extraction
- Works over ADB/USB
- Less data but non-destructive

### Cloud Acquisition
- Pull data from cloud backups
- Requires account credentials
- iCloud, Google Drive, Samsung Cloud

## 2. Data Extraction

```bash
# Android logical extraction
python3 nullkia.py forensics extract --type logical --output ./evidence/

# Full filesystem dump (rooted)
python3 nullkia.py forensics extract --type physical --output ./evidence/

# App data extraction
python3 nullkia.py forensics apps --package com.whatsapp --output ./evidence/
```

## 3. Key Artifacts

| Artifact | Location (Android) | Location (iOS) |
|----------|-------------------|----------------|
| Call logs | `/data/data/com.android.providers.contacts/` | `CallHistory.storedata` |
| SMS/MMS | `/data/data/com.android.providers.telephony/` | `sms.db` |
| WiFi passwords | `/data/misc/wifi/` | Keychain |
| Browser history | App-specific | `History.db` |
| Location data | `/data/data/com.google.android.gms/` | `consolidated.db` |

## 4. Reporting

```bash
# Generate forensics report
python3 nullkia.py forensics report --input ./evidence/ --format html
```

## Legal Considerations

⚠️ Always obtain proper authorization before conducting mobile forensics. Document chain of custody. Use write-blockers when possible.
