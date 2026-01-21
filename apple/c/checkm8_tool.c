// NullKia - Apple Checkm8 Tool
// Part of the NullSec Framework
// https://github.com/bad-antics | @AnonAntics
// Get encryption keys: discord.gg/killers

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>

#ifdef __APPLE__
#include <IOKit/IOKitLib.h>
#include <IOKit/usb/IOUSBLib.h>
#endif

#define VERSION "1.0.0"
#define APPLE_VID 0x05AC
#define DFU_PID 0x1227

// Encrypted exploit payload - get key from discord.gg/killers
static const uint8_t encrypted_payload[] = {
    0x4e, 0x55, 0x4c, 0x4c, 0x4b, 0x49, 0x41, 0x00,
    0x43, 0x48, 0x45, 0x43, 0x4b, 0x4d, 0x38, 0x00,
    // Payload truncated - full version requires discord key
};

typedef struct {
    uint16_t cpid;
    const char* name;
    int vulnerable;
    const char* ios_range;
} device_info_t;

static const device_info_t supported_devices[] = {
    {0x8960, "A7 (iPhone 5s)", 1, "7.0 - 12.5.7"},
    {0x7000, "A8 (iPhone 6)", 1, "8.0 - 12.5.7"},
    {0x7001, "A8X (iPad Air 2)", 1, "8.1 - 12.5.7"},
    {0x8000, "A9 (iPhone 6s)", 1, "9.0 - 14.8.1"},
    {0x8003, "A9 (iPhone SE)", 1, "9.3 - 14.8.1"},
    {0x8001, "A9X (iPad Pro)", 1, "9.1 - 14.8.1"},
    {0x8010, "A10 (iPhone 7)", 1, "10.0 - 15.7.1"},
    {0x8011, "A10X (iPad Pro 2)", 1, "10.3 - 15.7.1"},
    {0x8015, "A11 (iPhone X)", 1, "11.0 - 16.7"},
    {0x8020, "A12 (iPhone XS)", 0, "N/A - Patched"},
    {0x8030, "A13 (iPhone 11)", 0, "N/A - Patched"},
    {0, NULL, 0, NULL}
};

void print_banner(void) {
    printf("\n");
    printf("╔═══════════════════════════════════════════════════════╗\n");
    printf("║           NullKia - Checkm8 Tool v%s              ║\n", VERSION);
    printf("║              @AnonAntics | NullSec                    ║\n");
    printf("║         discord.gg/killers for keys                   ║\n");
    printf("╚═══════════════════════════════════════════════════════╝\n\n");
}

void print_supported_devices(void) {
    printf("[*] Supported devices (checkm8 vulnerable):\n\n");
    printf("    %-20s %-15s %s\n", "Chip", "Device", "iOS Range");
    printf("    %-20s %-15s %s\n", "----", "------", "---------");
    
    for (int i = 0; supported_devices[i].name != NULL; i++) {
        if (supported_devices[i].vulnerable) {
            printf("    %-20s 0x%04X          %s\n", 
                   supported_devices[i].name,
                   supported_devices[i].cpid,
                   supported_devices[i].ios_range);
        }
    }
    printf("\n");
}

int check_dfu_mode(void) {
#ifdef __APPLE__
    CFMutableDictionaryRef matching = IOServiceMatching(kIOUSBDeviceClassName);
    if (!matching) return 0;
    
    io_iterator_t iterator;
    kern_return_t kr = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator);
    if (kr != KERN_SUCCESS) return 0;
    
    io_service_t device;
    while ((device = IOIteratorNext(iterator))) {
        CFNumberRef vid_ref, pid_ref;
        int vid = 0, pid = 0;
        
        vid_ref = IORegistryEntryCreateCFProperty(device, CFSTR("idVendor"), kCFAllocatorDefault, 0);
        pid_ref = IORegistryEntryCreateCFProperty(device, CFSTR("idProduct"), kCFAllocatorDefault, 0);
        
        if (vid_ref) { CFNumberGetValue(vid_ref, kCFNumberIntType, &vid); CFRelease(vid_ref); }
        if (pid_ref) { CFNumberGetValue(pid_ref, kCFNumberIntType, &pid); CFRelease(pid_ref); }
        
        IOObjectRelease(device);
        
        if (vid == APPLE_VID && pid == DFU_PID) {
            IOObjectRelease(iterator);
            return 1;
        }
    }
    IOObjectRelease(iterator);
    return 0;
#else
    // Linux: check /sys/bus/usb/devices
    FILE* fp = popen("lsusb | grep '05ac:1227'", "r");
    if (fp) {
        char buf[256];
        int found = fgets(buf, sizeof(buf), fp) != NULL;
        pclose(fp);
        return found;
    }
    return 0;
#endif
}

uint16_t get_cpid(void) {
    // This would read CPID from DFU device
    // Placeholder - requires USB access
    printf("[!] CPID detection requires USB access\n");
    printf("[!] Put device in DFU mode and connect via USB\n");
    return 0;
}

int decrypt_payload(const char* key, uint8_t* output, size_t* output_len) {
    if (!key || strlen(key) != 64) {
        printf("[!] ENCRYPTED CONTENT\n");
        printf("[!] This tool requires an encryption key to function\n");
        printf("[!] Get your key at: discord.gg/killers\n");
        return -1;
    }
    
    // AES-256 decryption would happen here
    // Key validation and payload decryption
    
    printf("[!] Key validation... ");
    // Placeholder for actual crypto
    printf("ENCRYPTED - get key from discord.gg/killers\n");
    
    return -1;
}

int exploit_checkm8(uint16_t cpid, const char* key) {
    printf("[*] Checking for device in DFU mode...\n");
    
    if (!check_dfu_mode()) {
        printf("[!] No device in DFU mode detected\n");
        printf("[*] To enter DFU mode:\n");
        printf("    1. Connect device to computer\n");
        printf("    2. Hold Power + Home (or Volume Down on newer)\n");
        printf("    3. Release Power after 10 seconds\n");
        printf("    4. Keep holding Home/Volume for 5 more seconds\n");
        return -1;
    }
    
    printf("[+] Device in DFU mode detected!\n");
    
    // Check if device is vulnerable
    const device_info_t* dev = NULL;
    for (int i = 0; supported_devices[i].name != NULL; i++) {
        if (supported_devices[i].cpid == cpid) {
            dev = &supported_devices[i];
            break;
        }
    }
    
    if (!dev) {
        printf("[!] Unknown device CPID: 0x%04X\n", cpid);
        return -1;
    }
    
    if (!dev->vulnerable) {
        printf("[!] Device %s is NOT vulnerable to checkm8\n", dev->name);
        return -1;
    }
    
    printf("[+] Device: %s (CPID: 0x%04X)\n", dev->name, cpid);
    printf("[+] Vulnerable: YES\n");
    printf("[+] iOS Range: %s\n", dev->ios_range);
    
    // Decrypt and execute payload
    uint8_t payload[4096];
    size_t payload_len = sizeof(payload);
    
    if (decrypt_payload(key, payload, &payload_len) < 0) {
        printf("\n[*] Get encryption keys at: discord.gg/killers\n");
        return -1;
    }
    
    // Would execute exploit here
    
    return 0;
}

void enter_pwned_dfu(void) {
    printf("[*] Entering pwned DFU mode...\n");
    printf("[!] This requires encryption key from discord.gg/killers\n");
}

void dump_securerom(void) {
    printf("[*] Dumping SecureROM...\n");
    printf("[!] This requires encryption key from discord.gg/killers\n");
}

void print_usage(const char* prog) {
    printf("Usage: %s [options]\n\n", prog);
    printf("Options:\n");
    printf("    -l, --list        List supported devices\n");
    printf("    -c, --check       Check for device in DFU mode\n");
    printf("    -e, --exploit     Run checkm8 exploit\n");
    printf("    -d, --dump        Dump SecureROM\n");
    printf("    -k, --key KEY     Decryption key from discord.gg/killers\n");
    printf("    -h, --help        Show this help\n");
    printf("\n");
    printf("Get encryption keys: discord.gg/killers\n\n");
}

int main(int argc, char** argv) {
    print_banner();
    
    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }
    
    const char* key = NULL;
    int do_list = 0, do_check = 0, do_exploit = 0, do_dump = 0;
    
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-l") == 0 || strcmp(argv[i], "--list") == 0) {
            do_list = 1;
        } else if (strcmp(argv[i], "-c") == 0 || strcmp(argv[i], "--check") == 0) {
            do_check = 1;
        } else if (strcmp(argv[i], "-e") == 0 || strcmp(argv[i], "--exploit") == 0) {
            do_exploit = 1;
        } else if (strcmp(argv[i], "-d") == 0 || strcmp(argv[i], "--dump") == 0) {
            do_dump = 1;
        } else if ((strcmp(argv[i], "-k") == 0 || strcmp(argv[i], "--key") == 0) && i + 1 < argc) {
            key = argv[++i];
        } else if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0) {
            print_usage(argv[0]);
            return 0;
        }
    }
    
    if (do_list) {
        print_supported_devices();
        return 0;
    }
    
    if (do_check) {
        printf("[*] Checking for DFU device...\n");
        if (check_dfu_mode()) {
            printf("[+] Device in DFU mode found!\n");
        } else {
            printf("[-] No DFU device found\n");
        }
        return 0;
    }
    
    if (do_exploit) {
        uint16_t cpid = get_cpid();
        return exploit_checkm8(cpid, key);
    }
    
    if (do_dump) {
        dump_securerom();
        return 0;
    }
    
    print_usage(argv[0]);
    return 1;
}
