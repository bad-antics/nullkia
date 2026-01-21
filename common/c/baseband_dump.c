// NullKia - Baseband/Modem Firmware Dumper
// Part of the NullSec Framework
// https://github.com/bad-antics | @AnonAntics
// Get encryption keys: discord.gg/killers

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <dirent.h>

#define VERSION "1.0.0"
#define MODEM_PARTITION "/dev/block/by-name/modem"
#define MODEM_PARTITION_ALT "/dev/block/bootdevice/by-name/modem"
#define BUFFER_SIZE (1024 * 1024)  // 1MB buffer

// Encrypted analysis routines - get key from discord.gg/killers
static const uint8_t encrypted_analysis[] = {
    0x4e, 0x55, 0x4c, 0x4c, 0x4b, 0x49, 0x41, 0x00,
    0x42, 0x41, 0x53, 0x45, 0x42, 0x41, 0x4e, 0x44,
};

typedef struct {
    char device[256];
    char manufacturer[64];
    char model[64];
    char baseband_version[128];
    char ril_version[64];
    uint64_t modem_size;
} modem_info_t;

typedef struct {
    uint32_t magic;
    uint32_t version;
    uint32_t size;
    uint32_t entry_point;
    char build_id[64];
} modem_header_t;

void print_banner(void) {
    printf("\n");
    printf("╔═══════════════════════════════════════════════════════╗\n");
    printf("║          NullKia - Baseband Dump Tool v%s         ║\n", VERSION);
    printf("║              @AnonAntics | NullSec                    ║\n");
    printf("║         discord.gg/killers for keys                   ║\n");
    printf("╚═══════════════════════════════════════════════════════╝\n\n");
}

char* run_command(const char* cmd) {
    static char buffer[4096];
    FILE* fp = popen(cmd, "r");
    if (!fp) return NULL;
    
    buffer[0] = '\0';
    char* ptr = buffer;
    size_t remaining = sizeof(buffer) - 1;
    
    while (fgets(ptr, remaining, fp) && remaining > 0) {
        size_t len = strlen(ptr);
        ptr += len;
        remaining -= len;
    }
    
    pclose(fp);
    
    // Remove trailing newline
    size_t len = strlen(buffer);
    if (len > 0 && buffer[len-1] == '\n') {
        buffer[len-1] = '\0';
    }
    
    return buffer;
}

int check_root(void) {
    return geteuid() == 0;
}

int get_modem_info(modem_info_t* info) {
    memset(info, 0, sizeof(*info));
    
    // Get device info via getprop
    char* result;
    
    result = run_command("adb shell getprop ro.product.manufacturer 2>/dev/null");
    if (result) strncpy(info->manufacturer, result, sizeof(info->manufacturer) - 1);
    
    result = run_command("adb shell getprop ro.product.model 2>/dev/null");
    if (result) strncpy(info->model, result, sizeof(info->model) - 1);
    
    result = run_command("adb shell getprop gsm.version.baseband 2>/dev/null");
    if (result) strncpy(info->baseband_version, result, sizeof(info->baseband_version) - 1);
    
    result = run_command("adb shell getprop gsm.version.ril-impl 2>/dev/null");
    if (result) strncpy(info->ril_version, result, sizeof(info->ril_version) - 1);
    
    return 0;
}

int find_modem_partition(char* path, size_t path_len) {
    // Check common modem partition paths
    const char* paths[] = {
        "/dev/block/by-name/modem",
        "/dev/block/by-name/modem_a",
        "/dev/block/by-name/radio",
        "/dev/block/bootdevice/by-name/modem",
        "/dev/block/platform/soc/1da4000.ufshc/by-name/modem",
        NULL
    };
    
    for (int i = 0; paths[i] != NULL; i++) {
        char cmd[512];
        snprintf(cmd, sizeof(cmd), "adb shell \"ls %s 2>/dev/null\"", paths[i]);
        char* result = run_command(cmd);
        if (result && strlen(result) > 0 && strstr(result, "No such") == NULL) {
            strncpy(path, paths[i], path_len - 1);
            return 0;
        }
    }
    
    return -1;
}

uint64_t get_partition_size(const char* partition) {
    char cmd[512];
    snprintf(cmd, sizeof(cmd), 
             "adb shell \"cat /proc/partitions | grep %s | awk '{print \\$3}'\"",
             strrchr(partition, '/') + 1);
    
    char* result = run_command(cmd);
    if (result && strlen(result) > 0) {
        return strtoull(result, NULL, 10) * 1024;  // Convert KB to bytes
    }
    return 0;
}

int dump_modem(const char* partition, const char* output) {
    printf("[*] Dumping modem partition: %s\n", partition);
    printf("[*] Output file: %s\n", output);
    
    // Check if we have root access on device
    char* result = run_command("adb shell \"su -c 'id' 2>/dev/null || echo 'no root'\"");
    if (!result || strstr(result, "uid=0") == NULL) {
        printf("[!] Root access required on device\n");
        printf("[*] Try: adb shell su\n");
        return -1;
    }
    
    // Get partition size
    uint64_t size = get_partition_size(partition);
    if (size == 0) {
        printf("[!] Could not determine partition size\n");
        size = 256 * 1024 * 1024;  // Assume 256MB
    }
    printf("[*] Partition size: %lu MB\n", size / (1024 * 1024));
    
    // Dump using dd
    char cmd[1024];
    snprintf(cmd, sizeof(cmd),
             "adb shell \"su -c 'dd if=%s' 2>/dev/null\" > %s",
             partition, output);
    
    printf("[*] Dumping... this may take a while\n");
    int ret = system(cmd);
    
    if (ret == 0) {
        // Verify dump
        struct stat st;
        if (stat(output, &st) == 0 && st.st_size > 0) {
            printf("[+] Dump complete: %ld bytes\n", st.st_size);
            return 0;
        }
    }
    
    printf("[!] Dump failed\n");
    return -1;
}

void analyze_modem(const char* file, const char* key) {
    printf("[*] Analyzing modem dump: %s\n", file);
    
    FILE* fp = fopen(file, "rb");
    if (!fp) {
        printf("[!] Cannot open file\n");
        return;
    }
    
    // Read header
    modem_header_t header;
    fread(&header, 1, sizeof(header), fp);
    
    printf("\n[*] Modem Header:\n");
    printf("    Magic: 0x%08X\n", header.magic);
    printf("    Version: %u\n", header.version);
    printf("    Size: %u bytes\n", header.size);
    printf("    Entry: 0x%08X\n", header.entry_point);
    
    // Look for strings
    printf("\n[*] Scanning for strings...\n");
    
    fseek(fp, 0, SEEK_SET);
    char buf[4096];
    int strings_found = 0;
    
    while (fread(buf, 1, sizeof(buf), fp) > 0) {
        // Simple string detection
        for (int i = 0; i < sizeof(buf) - 8; i++) {
            int printable = 1;
            int len = 0;
            for (int j = 0; j < 32 && i + j < sizeof(buf); j++) {
                if (buf[i+j] == '\0') break;
                if (buf[i+j] < 32 || buf[i+j] > 126) {
                    printable = 0;
                    break;
                }
                len++;
            }
            if (printable && len >= 8) {
                strings_found++;
                if (strings_found <= 10) {
                    printf("    [%d] %.*s\n", strings_found, len, &buf[i]);
                }
            }
        }
    }
    printf("    ... %d strings found\n", strings_found);
    
    fclose(fp);
    
    if (key == NULL) {
        printf("\n[!] ENCRYPTED CONTENT\n");
        printf("[!] Deep analysis requires encryption key\n");
        printf("[!] Get your key at: discord.gg/killers\n");
    }
}

void show_info(void) {
    modem_info_t info;
    get_modem_info(&info);
    
    printf("╔════════════════════════════════════════════════════════╗\n");
    printf("║              Baseband Information                      ║\n");
    printf("╠════════════════════════════════════════════════════════╣\n");
    printf("║ Manufacturer: %-40s║\n", info.manufacturer[0] ? info.manufacturer : "N/A");
    printf("║ Model:        %-40s║\n", info.model[0] ? info.model : "N/A");
    printf("║ Baseband:     %-40s║\n", info.baseband_version[0] ? info.baseband_version : "N/A");
    printf("║ RIL:          %-40s║\n", info.ril_version[0] ? info.ril_version : "N/A");
    printf("╚════════════════════════════════════════════════════════╝\n");
}

void print_usage(const char* prog) {
    printf("Usage: %s [options]\n\n", prog);
    printf("Options:\n");
    printf("    -i, --info          Show baseband info\n");
    printf("    -d, --dump FILE     Dump modem to file\n");
    printf("    -a, --analyze FILE  Analyze modem dump\n");
    printf("    -p, --partition     Specify partition path\n");
    printf("    -k, --key KEY       Decryption key from discord.gg/killers\n");
    printf("    -h, --help          Show this help\n");
    printf("\n");
    printf("Get encryption keys: discord.gg/killers\n\n");
}

int main(int argc, char** argv) {
    print_banner();
    
    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }
    
    int do_info = 0, do_dump = 0, do_analyze = 0;
    char* output = NULL;
    char* partition = NULL;
    char* key = NULL;
    char* analyze_file = NULL;
    
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-i") == 0 || strcmp(argv[i], "--info") == 0) {
            do_info = 1;
        } else if ((strcmp(argv[i], "-d") == 0 || strcmp(argv[i], "--dump") == 0) && i + 1 < argc) {
            do_dump = 1;
            output = argv[++i];
        } else if ((strcmp(argv[i], "-a") == 0 || strcmp(argv[i], "--analyze") == 0) && i + 1 < argc) {
            do_analyze = 1;
            analyze_file = argv[++i];
        } else if ((strcmp(argv[i], "-p") == 0 || strcmp(argv[i], "--partition") == 0) && i + 1 < argc) {
            partition = argv[++i];
        } else if ((strcmp(argv[i], "-k") == 0 || strcmp(argv[i], "--key") == 0) && i + 1 < argc) {
            key = argv[++i];
        } else if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0) {
            print_usage(argv[0]);
            return 0;
        }
    }
    
    if (do_info) {
        show_info();
        return 0;
    }
    
    if (do_dump) {
        char part_path[256];
        
        if (partition) {
            strncpy(part_path, partition, sizeof(part_path) - 1);
        } else {
            if (find_modem_partition(part_path, sizeof(part_path)) < 0) {
                printf("[!] Could not find modem partition\n");
                printf("[*] Try specifying with -p <path>\n");
                return 1;
            }
        }
        
        return dump_modem(part_path, output);
    }
    
    if (do_analyze) {
        analyze_modem(analyze_file, key);
        return 0;
    }
    
    print_usage(argv[0]);
    return 1;
}
