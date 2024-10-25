#!/bin/bash
set -e  # Exit on any error

# Function to clean up on exit
cleanup() {
    rm -f temp_config.json 2>/dev/null
}
trap cleanup EXIT

# Function to validate username
validate_username() {
    local username="$1"
    # Check if username is valid (starts with letter, contains only letters, numbers, underscores, and hyphens)
    if ! [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        echo "Invalid username. Username must:"
        echo "- Start with a lowercase letter or underscore"
        echo "- Contain only lowercase letters, numbers, underscores, or hyphens"
        echo "- Not contain spaces or special characters"
        return 1
    fi
    # Check length (between 1 and 32 characters)
    if [ ${#username} -gt 32 ] || [ ${#username} -lt 1 ]; then
        echo "Username must be between 1 and 32 characters long"
        return 1
    fi
    return 0
}

# Function to validate password
validate_password() {
    local password="$1"
    # Check password length (minimum 8 characters)
    if [ ${#password} -lt 8 ]; then
        echo "Password must be at least 8 characters long"
        return 1
    fi
    # Check if password contains at least one number
    if ! [[ "$password" =~ [0-9] ]]; then
        echo "Password must contain at least one number"
        return 1
    fi
    # Check if password contains at least one uppercase letter
    if ! [[ "$password" =~ [A-Z] ]]; then
        echo "Password must contain at least one uppercase letter"
        return 1
    fi
    # Check if password contains at least one lowercase letter
    if ! [[ "$password" =~ [a-z] ]]; then
        echo "Password must contain at least one lowercase letter"
        return 1
    fi
    # Check if password contains at least one special character
    if ! [[ "$password" =~ [!@#\$%^&*()_+\-=\[\]{};:,.<>?] ]]; then
        echo "Password must contain at least one special character (!@#$%^&*()_+-=[]{};:,.<>?)"
        return 1
    fi
    return 0
}

# Install required packages
pacman -S git jq --noconfirm || { echo "Failed to install required packages"; exit 1; }

# Clone the repository
git clone https://github.com/pentestfunctions/hypervarch.git || { echo "Failed to clone repository"; exit 1; }

# Username prompt loop
while true; do
    read -p "Enter desired username: " USERNAME
    if validate_username "$USERNAME"; then
        break
    fi
    echo "Please try again."
done

# Password prompt loop
while true; do
    read -s -p "Enter password: " PASSWORD
    echo
    read -s -p "Confirm password: " PASSWORD2
    echo
    
    # Check if passwords match
    if [ "$PASSWORD" != "$PASSWORD2" ]; then
        echo "Passwords do not match. Please try again."
        continue
    fi
    
    if validate_password "$PASSWORD"; then
        break
    fi
    echo "Please try again."
done

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
echo "   • Type your username exactly as you created it"
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
Environment=XAUTHORITY=/home/__USER__/.Xauthority
ExecStart=/usr/local/bin/welcome_message.sh
User=__USER__

[Install]
WantedBy=multi-user.target
EOL

# Create post-installation script
cat > hypervarch/scripts/post_install.sh << 'EOL'
#!/bin/bash

# Replace placeholder in service file
sed -i "s/__USER__/${1}/g" /etc/systemd/system/welcome-message.service

# Enable the service
systemctl enable welcome-message.service

# Make welcome message executable
chmod +x /usr/local/bin/welcome_message.sh

# Set proper ownership
chown ${1}:${1} /usr/local/bin/welcome_message.sh
EOL

chmod +x hypervarch/scripts/post_install.sh
chmod +x hypervarch/scripts/welcome_message.sh

# Create temporary configuration with post-install commands
jq --arg user "$USERNAME" --arg pass "$PASSWORD" \
'.["!users"][0].username = $user | 
 .["!users"][0]["!password"] = $pass | 
 .["!root-password"] = $pass |
 .custom-commands = [
    "cp /root/hypervarch/scripts/welcome_message.sh /usr/local/bin/",
    "cp /root/hypervarch/scripts/welcome-message.service /etc/systemd/system/",
    "bash /root/hypervarch/scripts/post_install.sh \"" + $user + "\""
 ]' hypervarch/user_configuration.json > temp_config.json || { echo "Failed to modify configuration"; exit 1; }

# Move the temporary config to replace the original
mv temp_config.json hypervarch/user_configuration.json

# Print summary
echo "Configuration complete!"
echo "Username: $USERNAME"
echo "Installing system..."

# Run archinstall
archinstall --config hypervarch/user_configuration.json --creds hypervarch/user_credentials.json --silent
