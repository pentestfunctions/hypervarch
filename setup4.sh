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
    return 0
}

# Install required packages
pacman -Sy --noconfirm  || { echo "Failed to run pacman -Sy"; exit 1; }
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

# Create a temporary modified configuration
jq --arg user "$USERNAME" --arg pass "$PASSWORD" '
    .["!users"][0].username = $user |
    .["!users"][0]["!password"] = $pass |
    .["!root-password"] = $pass
' hypervarch/user_configuration.json > temp_config.json || { echo "Failed to modify configuration"; exit 1; }

# Move the temporary config to replace the original
mv temp_config.json hypervarch/user_configuration.json

# Print summary (optional)
echo "Configuration complete!"
echo "Username: $USERNAME"
echo "Installing system..."

# Run archinstall
archinstall --config hypervarch/user_configuration.json --creds hypervarch/user_credentials.json --silent

# Create a welcome message script
cat > hypervarch/welcome_message.sh << 'EOL'
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
echo "   • Using Hyper-V viewer? Copy-paste won't work by default"
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

echo -e "\n${RED}Note:${NC} This message will only show once on first boot."
echo -e "You can view it again by running: cat ~/.welcome_message\n"

# Save this message for future reference
cp $0 ~/.welcome_message

# Remove from startup
rm ~/.config/autostart/welcome.desktop 2>/dev/null || true

echo -e "${GREEN}Press Enter to start using your system...${NC}"
read

EOL

# Create autostart directory and desktop file for welcome message
mkdir -p hypervarch/autostart
cat > hypervarch/autostart/welcome.desktop << EOL
[Desktop Entry]
Type=Application
Name=Welcome Message
Exec=/usr/local/bin/welcome_message.sh
Terminal=true
X-GNOME-Autostart-enabled=true
EOL

# Add installation of welcome message to the post-install commands
cat >> hypervarch/user_configuration.json << EOL
{
    "custom-commands": [
        "chmod +x /usr/local/bin/welcome_message.sh",
        "mkdir -p /home/$USERNAME/.config/autostart",
        "cp /usr/local/bin/welcome_message.sh /home/$USERNAME/.config/autostart/welcome.desktop",
        "chown -R $USERNAME:$USERNAME /home/$USERNAME/.config"
    ]
}
EOL

# Make the welcome script executable
chmod +x hypervarch/welcome_message.sh

# Create a temporary modified configuration
jq --arg user "$USERNAME" --arg pass "$PASSWORD" '
    .["!users"][0].username = $user |
    .["!users"][0]["!password"] = $pass |
    .["!root-password"] = $pass
' hypervarch/user_configuration.json > temp_config.json || { echo "Failed to modify configuration"; exit 1; }

# Move the temporary config to replace the original
mv temp_config.json hypervarch/user_configuration.json

# Copy welcome script to the right location
mkdir -p /usr/local/bin/
cp hypervarch/welcome_message.sh /usr/local/bin/
cp hypervarch/autostart/welcome.desktop /etc/xdg/autostart/

# Rest of the installation script...
archinstall --config hypervarch/user_configuration.json --creds hypervarch/user_credentials.json --silent
