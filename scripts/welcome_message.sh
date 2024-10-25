#!/bin/bash

# Colors for formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

clear
echo -e "${BOLD}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║                  ${GREEN}Welcome to Your Arch Linux System${NC}                 ${BOLD}║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${BLUE}Important Things to Know:${NC}"
echo -e "${BOLD}1. Hyper-V Integration:${NC}"
echo "   • Using Hyper-V viewer? Copy-paste will not work by default"
echo "   • For full functionality, use Remote Desktop (RDP) instead"
echo "   • RDP Command: mstsc.exe /v:your-ip-address"

echo -e "\n${BOLD}2. System Configuration:${NC}"
echo "   • Wallpaper and themes are not yet configured"
echo "   • Basic system tools are installed, but you might need more"
echo "   • Package manager command: pacman -S package-name"

echo -e "\n${BOLD}3. Getting Started:${NC}"
echo "   • Update system: sudo pacman -Syu"
echo "   • Install common tools: sudo pacman -S base-devel"
echo "   • Access AUR helper: yay -S package-name"

echo -e "\n${BOLD}4. Useful Commands:${NC}"
echo "   • Check IP: ip addr"
echo "   • System info: neofetch"
echo "   • Disk usage: df -h"

echo -e "\n${BOLD}5. Login Information:${NC}"
echo "   • You're using Ly as your display manager"
echo "   • Your username is: robot"
echo "   • Your password is: robot"
echo "   • Caps Lock will affect your password"

echo -e "\n${RED}Note:${NC} This message will only show once on first boot."
echo -e "You can view it again by running: cat ~/.welcome_message\n"

# Remove autostart entry
rm -f ~/.config/autostart/welcome.desktop 2>/dev/null

echo -e "${GREEN}Press Enter to start using your system...${NC}"
read
