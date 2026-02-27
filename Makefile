# NullKia Makefile
# Cross-platform build system

VERSION := 2.0.0
PREFIX := $(HOME)/.nullkia
BIN_DIR := $(HOME)/.local/bin

.PHONY: all install uninstall linux macos windows android termux clean help

all: help

help:
@echo ""
@echo "  ███╗   ██╗██╗   ██╗██╗     ██╗     ██╗  ██╗██╗ █████╗ "
@echo "  ████╗  ██║██║   ██║██║     ██║     ██║ ██╔╝██║██╔══██╗"
@echo "  ██╔██╗ ██║██║   ██║██║     ██║     █████╔╝ ██║███████║"
@echo "  ██║╚██╗██║██║   ██║██║     ██║     ██╔═██╗ ██║██╔══██║"
@echo "  ██║ ╚████║╚██████╔╝███████╗███████╗██║  ██╗██║██║  ██║"
@echo "  ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝"
@echo ""
@echo "  NullKia v$(VERSION) - Mobile Security Framework"
@echo ""
@echo "  Usage: make <target>"
@echo ""
@echo "  Targets:"
@echo "    install    - Install on Linux/macOS"
@echo "    linux      - Install on Linux"
@echo "    macos      - Install on macOS"
@echo "    termux     - Install on Android (Termux)"
@echo "    uninstall  - Remove NullKia"
@echo "    clean      - Clean build artifacts"
@echo ""
@echo "  Join x.com/AnonAntics for keys!"
@echo ""

install: linux

linux:
@echo "[*] Installing NullKia for Linux..."
@./install.sh

macos:
@echo "[*] Installing NullKia for macOS..."
@./install.sh

termux:
@echo "[*] Installing NullKia for Termux..."
@pkg install -y git curl wget android-tools
@mkdir -p $(PREFIX)/{bin,lib,modules,firmware,logs,keys}
@mkdir -p $(BIN_DIR)
@cp -r . $(PREFIX)/src
@chmod +x install.sh
@./install.sh

uninstall:
@echo "[*] Uninstalling NullKia..."
@rm -rf $(PREFIX)
@rm -f $(BIN_DIR)/nullkia
@echo "[✓] NullKia uninstalled"

clean:
@echo "[*] Cleaning..."
@rm -rf build/
@echo "[✓] Clean complete"
