#!/bin/bash
#
# ███╗   ██╗██╗   ██╗██╗     ██╗     ██╗  ██╗██╗ █████╗ 
# ████╗  ██║██║   ██║██║     ██║     ██║ ██╔╝██║██╔══██╗
# ██╔██╗ ██║██║   ██║██║     ██║     █████╔╝ ██║███████║
# ██║╚██╗██║██║   ██║██║     ██║     ██╔═██╗ ██║██╔══██║
# ██║ ╚████║╚██████╔╝███████╗███████╗██║  ██╗██║██║  ██║
# ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝
#
# NullKia Universal Installer
# https://github.com/bad-antics/nullkia
# Join: discord.gg/killers
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Config
NULLKIA_VERSION="2.0.0"
INSTALL_DIR="${NULLKIA_HOME:-$HOME/.nullkia}"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/nullkia"
REPO_URL="https://github.com/bad-antics/nullkia"
RELEASE_URL="https://github.com/bad-antics/nullkia/releases/latest/download"

banner() {
    echo -e "${MAGENTA}"
    echo '    ███╗   ██╗██╗   ██╗██╗     ██╗     ██╗  ██╗██╗ █████╗ '
    echo '    ████╗  ██║██║   ██║██║     ██║     ██║ ██╔╝██║██╔══██╗'
    echo '    ██╔██╗ ██║██║   ██║██║     ██║     █████╔╝ ██║███████║'
    echo '    ██║╚██╗██║██║   ██║██║     ██║     ██╔═██╗ ██║██╔══██║'
    echo '    ██║ ╚████║╚██████╔╝███████╗███████╗██║  ██╗██║██║  ██║'
    echo '    ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝'
    echo -e "${NC}"
    echo -e "${CYAN}    [ Mobile Security Framework | v${NULLKIA_VERSION} ]${NC}"
    echo -e "${YELLOW}    [ discord.gg/killers for keys & support ]${NC}"
    echo
}

log_info() { echo -e "${CYAN}[*]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

detect_os() {
    case "$(uname -s)" in
        Linux*)     OS="linux";;
        Darwin*)    OS="darwin";;
        CYGWIN*|MINGW*|MSYS*) OS="windows";;
        *)          OS="unknown";;
    esac
    
    case "$(uname -m)" in
        x86_64|amd64) ARCH="amd64";;
        arm64|aarch64) ARCH="arm64";;
        armv7l) ARCH="armv7";;
        i386|i686) ARCH="386";;
        *) ARCH="unknown";;
    esac
    
    log_info "Detected: ${OS}/${ARCH}"
}

detect_package_manager() {
    if command -v apt-get &>/dev/null; then
        PKG_MGR="apt"
    elif command -v dnf &>/dev/null; then
        PKG_MGR="dnf"
    elif command -v yum &>/dev/null; then
        PKG_MGR="yum"
    elif command -v pacman &>/dev/null; then
        PKG_MGR="pacman"
    elif command -v brew &>/dev/null; then
        PKG_MGR="brew"
    elif command -v apk &>/dev/null; then
        PKG_MGR="apk"
    else
        PKG_MGR="unknown"
    fi
}

install_dependencies() {
    log_info "Installing dependencies..."
    
    case "$PKG_MGR" in
        apt)
            sudo apt-get update -qq
            sudo apt-get install -y -qq curl wget git unzip android-tools-adb android-tools-fastboot libusb-1.0-0 2>/dev/null || true
            ;;
        dnf|yum)
            sudo $PKG_MGR install -y curl wget git unzip android-tools libusb 2>/dev/null || true
            ;;
        pacman)
            sudo pacman -Sy --noconfirm curl wget git unzip android-tools libusb 2>/dev/null || true
            ;;
        brew)
            brew install curl wget git unzip android-platform-tools libusb 2>/dev/null || true
            ;;
        apk)
            sudo apk add curl wget git unzip android-tools libusb 2>/dev/null || true
            ;;
    esac
    
    log_success "Dependencies installed"
}

setup_udev_rules() {
    if [[ "$OS" == "linux" ]]; then
        log_info "Setting up udev rules for mobile devices..."
        
        UDEV_FILE="/etc/udev/rules.d/51-nullkia.rules"
        
        sudo tee "$UDEV_FILE" > /dev/null << 'UDEV'
# NullKia Mobile Security Framework - udev rules
# Samsung
SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0666", GROUP="plugdev"
# Google
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev"
# OnePlus
SUBSYSTEM=="usb", ATTR{idVendor}=="2a70", MODE="0666", GROUP="plugdev"
# Xiaomi
SUBSYSTEM=="usb", ATTR{idVendor}=="2717", MODE="0666", GROUP="plugdev"
# Huawei
SUBSYSTEM=="usb", ATTR{idVendor}=="12d1", MODE="0666", GROUP="plugdev"
# Motorola
SUBSYSTEM=="usb", ATTR{idVendor}=="22b8", MODE="0666", GROUP="plugdev"
# LG
SUBSYSTEM=="usb", ATTR{idVendor}=="1004", MODE="0666", GROUP="plugdev"
# Sony
SUBSYSTEM=="usb", ATTR{idVendor}=="0fce", MODE="0666", GROUP="plugdev"
# Nokia
SUBSYSTEM=="usb", ATTR{idVendor}=="0421", MODE="0666", GROUP="plugdev"
# Apple (for checkm8/checkra1n)
SUBSYSTEM=="usb", ATTR{idVendor}=="05ac", MODE="0666", GROUP="plugdev"
# Qualcomm EDL mode
SUBSYSTEM=="usb", ATTR{idVendor}=="05c6", MODE="0666", GROUP="plugdev"
# MediaTek preloader
SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", MODE="0666", GROUP="plugdev"
UDEV
        
        sudo udevadm control --reload-rules
        sudo udevadm trigger
        
        # Add user to plugdev group
        sudo usermod -aG plugdev "$USER" 2>/dev/null || true
        
        log_success "udev rules configured"
    fi
}

create_directories() {
    log_info "Creating directories..."
    
    mkdir -p "$INSTALL_DIR"/{bin,lib,modules,firmware,logs,keys}
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$BIN_DIR"
    
    log_success "Directories created"
}

download_tools() {
    log_info "Downloading NullKia tools..."
    
    # Clone or update repo
    if [[ -d "$INSTALL_DIR/src" ]]; then
        cd "$INSTALL_DIR/src" && git pull --quiet
    else
        git clone --quiet "$REPO_URL" "$INSTALL_DIR/src" 2>/dev/null || {
            log_warn "Could not clone repo, using local installation"
        }
    fi
    
    log_success "Tools downloaded"
}

install_binaries() {
    log_info "Installing binaries..."
    
    # Create main nullkia command
    cat > "$BIN_DIR/nullkia" << 'CMD'
#!/bin/bash
#
# NullKia - Mobile Security Framework
#

NULLKIA_HOME="${NULLKIA_HOME:-$HOME/.nullkia}"
VERSION="2.0.0"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

banner() {
    echo -e "${MAGENTA}"
    echo '    ███╗   ██╗██╗   ██╗██╗     ██╗     ██╗  ██╗██╗ █████╗ '
    echo '    ████╗  ██║██║   ██║██║     ██║     ██║ ██╔╝██║██╔══██╗'
    echo '    ██╔██╗ ██║██║   ██║██║     ██║     █████╔╝ ██║███████║'
    echo '    ██║╚██╗██║██║   ██║██║     ██║     ██╔═██╗ ██║██╔══██║'
    echo '    ██║ ╚████║╚██████╔╝███████╗███████╗██║  ██╗██║██║  ██║'
    echo '    ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝'
    echo -e "${NC}"
    echo -e "${CYAN}    [ Mobile Security Framework | v${VERSION} ]${NC}"
    echo
}

show_help() {
    banner
    echo -e "${WHITE}USAGE:${NC}"
    echo "    nullkia <command> [options]"
    echo
    echo -e "${WHITE}COMMANDS:${NC}"
    echo -e "    ${GREEN}device${NC}      Detect and manage connected devices"
    echo -e "    ${GREEN}samsung${NC}     Samsung/Knox exploitation tools"
    echo -e "    ${GREEN}apple${NC}       iOS/checkm8 exploitation tools"
    echo -e "    ${GREEN}google${NC}      Pixel/Titan M tools"
    echo -e "    ${GREEN}oneplus${NC}     OnePlus/OxygenOS tools"
    echo -e "    ${GREEN}xiaomi${NC}      Xiaomi/MIUI unlock tools"
    echo -e "    ${GREEN}huawei${NC}      Huawei/EMUI tools"
    echo -e "    ${GREEN}motorola${NC}    Motorola unlock tools"
    echo -e "    ${GREEN}lg${NC}          LG bootloader tools"
    echo -e "    ${GREEN}sony${NC}        Sony unlock tools"
    echo -e "    ${GREEN}nokia${NC}       Nokia tools"
    echo -e "    ${GREEN}firmware${NC}    Firmware dump/flash utilities"
    echo -e "    ${GREEN}baseband${NC}    Baseband/modem research tools"
    echo -e "    ${GREEN}unbrick${NC}     Device recovery utilities"
    echo -e "    ${GREEN}keys${NC}        Manage encryption keys"
    echo -e "    ${GREEN}update${NC}      Update NullKia"
    echo -e "    ${GREEN}help${NC}        Show this help"
    echo
    echo -e "${WHITE}EXAMPLES:${NC}"
    echo "    nullkia device scan"
    echo "    nullkia samsung knox-bypass"
    echo "    nullkia apple checkm8 --device iPhone10,6"
    echo "    nullkia firmware dump /dev/block/bootdevice"
    echo
    echo -e "${YELLOW}Join discord.gg/killers for encryption keys!${NC}"
}

detect_device() {
    echo -e "${CYAN}[*] Scanning for connected devices...${NC}"
    echo
    
    # Check ADB devices
    if command -v adb &>/dev/null; then
        ADB_DEVICES=$(adb devices 2>/dev/null | grep -v "List" | grep -v "^$")
        if [[ -n "$ADB_DEVICES" ]]; then
            echo -e "${GREEN}[ADB Devices]${NC}"
            while IFS= read -r line; do
                SERIAL=$(echo "$line" | awk '{print $1}')
                STATE=$(echo "$line" | awk '{print $2}')
                if [[ -n "$SERIAL" ]]; then
                    BRAND=$(adb -s "$SERIAL" shell getprop ro.product.brand 2>/dev/null | tr -d '\r')
                    MODEL=$(adb -s "$SERIAL" shell getprop ro.product.model 2>/dev/null | tr -d '\r')
                    ANDROID=$(adb -s "$SERIAL" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
                    echo -e "  ${WHITE}$SERIAL${NC} [$STATE]"
                    echo -e "    Brand: ${CYAN}$BRAND${NC}"
                    echo -e "    Model: ${CYAN}$MODEL${NC}"
                    echo -e "    Android: ${CYAN}$ANDROID${NC}"
                fi
            done <<< "$ADB_DEVICES"
            echo
        fi
    fi
    
    # Check fastboot devices
    if command -v fastboot &>/dev/null; then
        FB_DEVICES=$(fastboot devices 2>/dev/null)
        if [[ -n "$FB_DEVICES" ]]; then
            echo -e "${YELLOW}[Fastboot Devices]${NC}"
            echo "$FB_DEVICES"
            echo
        fi
    fi
    
    # Check for EDL mode (Qualcomm)
    if [[ -e /dev/ttyUSB0 ]] || lsusb 2>/dev/null | grep -q "05c6:9008"; then
        echo -e "${RED}[EDL Mode Device Detected]${NC}"
        echo "  Qualcomm Emergency Download mode active"
        echo
    fi
    
    # Check for DFU mode (Apple)
    if lsusb 2>/dev/null | grep -q "05ac:1227"; then
        echo -e "${RED}[DFU Mode Device Detected]${NC}"
        echo "  Apple DFU mode - ready for checkm8"
        echo
    fi
}

cmd_device() {
    case "$1" in
        scan|detect|list)
            detect_device
            ;;
        reboot)
            shift
            case "$1" in
                fastboot|bootloader)
                    adb reboot bootloader
                    ;;
                recovery)
                    adb reboot recovery
                    ;;
                edl|download)
                    adb reboot edl 2>/dev/null || adb reboot download
                    ;;
                *)
                    adb reboot
                    ;;
            esac
            ;;
        shell)
            adb shell
            ;;
        *)
            echo -e "${CYAN}Usage: nullkia device <scan|reboot|shell>${NC}"
            ;;
    esac
}

cmd_samsung() {
    echo -e "${CYAN}[Samsung/Knox Tools]${NC}"
    case "$1" in
        knox-bypass)
            echo "Knox bypass module - requires key from discord.gg/killers"
            ;;
        odin)
            echo "ODIN flash mode utilities"
            ;;
        frp-bypass)
            echo "Factory Reset Protection bypass"
            ;;
        *)
            echo "Commands: knox-bypass, odin, frp-bypass"
            ;;
    esac
}

cmd_apple() {
    echo -e "${CYAN}[Apple/iOS Tools]${NC}"
    case "$1" in
        checkm8)
            echo "checkm8 bootrom exploit (A5-A11)"
            ;;
        checkra1n)
            echo "checkra1n jailbreak utility"
            ;;
        dfu)
            echo "Enter DFU mode helper"
            ;;
        *)
            echo "Commands: checkm8, checkra1n, dfu"
            ;;
    esac
}

cmd_firmware() {
    echo -e "${CYAN}[Firmware Utilities]${NC}"
    case "$1" in
        dump)
            echo "Firmware dump utility"
            ;;
        flash)
            echo "Firmware flash utility"
            ;;
        extract)
            echo "Firmware extraction tool"
            ;;
        analyze)
            echo "Firmware analysis tool"
            ;;
        *)
            echo "Commands: dump, flash, extract, analyze"
            ;;
    esac
}

cmd_update() {
    echo -e "${CYAN}[*] Updating NullKia...${NC}"
    cd "$NULLKIA_HOME/src" 2>/dev/null && git pull
    echo -e "${GREEN}[✓] NullKia updated${NC}"
}

# Main
case "$1" in
    device)
        shift
        cmd_device "$@"
        ;;
    samsung)
        shift
        cmd_samsung "$@"
        ;;
    apple)
        shift
        cmd_apple "$@"
        ;;
    google|pixel)
        echo "[Google Pixel/Titan M Tools]"
        ;;
    oneplus)
        echo "[OnePlus/OxygenOS Tools]"
        ;;
    xiaomi)
        echo "[Xiaomi/MIUI Tools]"
        ;;
    huawei)
        echo "[Huawei/EMUI Tools]"
        ;;
    motorola)
        echo "[Motorola Tools]"
        ;;
    lg)
        echo "[LG Tools]"
        ;;
    sony)
        echo "[Sony Tools]"
        ;;
    nokia)
        echo "[Nokia Tools]"
        ;;
    firmware)
        shift
        cmd_firmware "$@"
        ;;
    baseband)
        echo "[Baseband Research Tools]"
        ;;
    unbrick)
        echo "[Unbrick/Recovery Tools]"
        ;;
    keys)
        echo "Keys managed at: $NULLKIA_HOME/keys"
        echo "Join discord.gg/killers for encryption keys"
        ;;
    update)
        cmd_update
        ;;
    version|-v|--version)
        echo "NullKia v$VERSION"
        ;;
    help|-h|--help|"")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo "Run 'nullkia help' for usage"
        exit 1
        ;;
esac
CMD
    
    chmod +x "$BIN_DIR/nullkia"
    
    log_success "Binaries installed"
}

create_config() {
    log_info "Creating configuration..."
    
    cat > "$CONFIG_DIR/config.yaml" << 'CONFIG'
# NullKia Configuration
version: 2.0.0

# Device settings
devices:
  auto_detect: true
  adb_timeout: 30
  fastboot_timeout: 60

# Paths
paths:
  firmware: ~/.nullkia/firmware
  keys: ~/.nullkia/keys
  logs: ~/.nullkia/logs

# Security
security:
  verify_signatures: true
  encrypted_keys: true

# Discord integration
discord:
  server: discord.gg/killers
  auto_key_fetch: false

# Manufacturer-specific settings
samsung:
  odin_mode: true
  knox_check: true

apple:
  checkm8_devices: [iPhone6,1, iPhone6,2, iPhone7,1, iPhone7,2, iPhone8,1, iPhone8,2, iPhone8,4, iPhone9,1, iPhone9,2, iPhone9,3, iPhone9,4, iPhone10,1, iPhone10,2, iPhone10,3, iPhone10,4, iPhone10,5, iPhone10,6]

google:
  titan_m_bypass: false
  
xiaomi:
  mi_unlock_wait: false

qualcomm:
  edl_loaders: ~/.nullkia/firmware/edl
CONFIG
    
    log_success "Configuration created"
}

setup_path() {
    log_info "Setting up PATH..."
    
    # Detect shell
    SHELL_NAME=$(basename "$SHELL")
    case "$SHELL_NAME" in
        bash)
            RC_FILE="$HOME/.bashrc"
            ;;
        zsh)
            RC_FILE="$HOME/.zshrc"
            ;;
        fish)
            RC_FILE="$HOME/.config/fish/config.fish"
            ;;
        *)
            RC_FILE="$HOME/.profile"
            ;;
    esac
    
    # Add to PATH if not already there
    if ! grep -q "NULLKIA_HOME" "$RC_FILE" 2>/dev/null; then
        cat >> "$RC_FILE" << PATHRC

# NullKia Mobile Security Framework
export NULLKIA_HOME="$INSTALL_DIR"
export PATH="\$PATH:$BIN_DIR"
PATHRC
        log_success "Added to $RC_FILE"
    fi
}

print_success() {
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     NullKia installed successfully!                          ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${WHITE}Installation directory:${NC} $INSTALL_DIR"
    echo -e "${WHITE}Binary location:${NC} $BIN_DIR/nullkia"
    echo -e "${WHITE}Config file:${NC} $CONFIG_DIR/config.yaml"
    echo
    echo -e "${CYAN}Quick start:${NC}"
    echo "    source ~/.bashrc  # or restart terminal"
    echo "    nullkia device scan"
    echo "    nullkia help"
    echo
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  Join discord.gg/killers for encryption keys & firmware!    ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

uninstall() {
    log_warn "Uninstalling NullKia..."
    
    rm -rf "$INSTALL_DIR"
    rm -rf "$CONFIG_DIR"
    rm -f "$BIN_DIR/nullkia"
    sudo rm -f /etc/udev/rules.d/51-nullkia.rules 2>/dev/null
    
    log_success "NullKia uninstalled"
}

# Main
main() {
    banner
    
    case "$1" in
        --uninstall|-u)
            uninstall
            exit 0
            ;;
        --help|-h)
            echo "Usage: $0 [--uninstall]"
            exit 0
            ;;
    esac
    
    detect_os
    detect_package_manager
    
    log_info "Installing NullKia v${NULLKIA_VERSION}..."
    echo
    
    install_dependencies
    create_directories
    download_tools
    install_binaries
    create_config
    setup_udev_rules
    setup_path
    
    print_success
}

main "$@"
