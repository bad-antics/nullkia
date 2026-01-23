#!/bin/bash
# NullKia One-Line Installer
# curl -sL https://raw.githubusercontent.com/bad-antics/nullkia/main/get-nullkia.sh | bash
set -e
echo -e "\033[35m"
echo '    ███╗   ██╗██╗   ██╗██╗     ██╗     ██╗  ██╗██╗ █████╗ '
echo '    ████╗  ██║██║   ██║██║     ██║     ██║ ██╔╝██║██╔══██╗'
echo '    ██╔██╗ ██║██║   ██║██║     ██║     █████╔╝ ██║███████║'
echo '    ██║╚██╗██║██║   ██║██║     ██║     ██╔═██╗ ██║██╔══██║'
echo '    ██║ ╚████║╚██████╔╝███████╗███████╗██║  ██╗██║██║  ██║'
echo '    ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝'
echo -e "\033[0m"
echo -e "\033[36m[*] Installing NullKia...\033[0m"
TMPDIR=$(mktemp -d)
cd "$TMPDIR"
git clone --depth 1 https://github.com/bad-antics/nullkia.git
cd nullkia
chmod +x install.sh
./install.sh
rm -rf "$TMPDIR"
