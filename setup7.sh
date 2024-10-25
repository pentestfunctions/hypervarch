#!/bin/bash
set -e  # Exit on any error

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update package database first
pacman -Sy

# Install required packages
pacman -S git jq --noconfirm || { echo "Failed to install required packages"; exit 1; }

# Clone the repository
git clone https://github.com/pentestfunctions/hypervarch.git || { echo "Failed to clone repository"; exit 1; }

# Create the welcome message script
mkdir -p hypervarch/scripts
cat > hypervarch/scripts/welcome_message.sh << 'EOL'
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

# Save this message for future reference
cp "$0" ~/.welcome_message

# Remove autostart entry
rm -f ~/.config/autostart/welcome.desktop 2>/dev/null

echo -e "${GREEN}Press Enter to start using your system...${NC}"
read

EOL

# Create systemd service for first boot
cat > hypervarch/scripts/welcome-message.service << 'EOL'
[Unit]
Description=First Boot Welcome Message
After=display-manager.service

[Service]
Type=oneshot
RemainAfterExit=no
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/robot/.Xauthority
ExecStart=/usr/local/bin/welcome_message.sh
User=robot

[Install]
WantedBy=multi-user.target
EOL

# Create post-installation script
cat > hypervarch/scripts/post_install.sh << 'EOL'
#!/bin/bash

# Enable the service
systemctl enable welcome-message.service

# Make welcome message executable
chmod +x /usr/local/bin/welcome_message.sh

# Set proper ownership
chown robot:robot /usr/local/bin/welcome_message.sh
EOL

chmod +x hypervarch/scripts/post_install.sh
chmod +x hypervarch/scripts/welcome_message.sh

# Create temporary configuration with post-install commands
jq '.custom-commands = [
    "cp /root/hypervarch/scripts/welcome_message.sh /usr/local/bin/",
    "cp /root/hypervarch/scripts/welcome-message.service /etc/systemd/system/",
    "bash /root/hypervarch/scripts/post_install.sh"
]' hypervarch/user_configuration.json > temp_config.json || { echo "Failed to modify configuration"; exit 1; }

# Move the temporary config to replace the original
mv temp_config.json hypervarch/user_configuration.json

# Print summary
echo "Installing Arch Linux..."
echo "Username and password will be: robot"

# Run archinstall
archinstall --config hypervarch/user_configuration.json --creds hypervarch/user_credentials.json --silent
