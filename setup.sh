#!/bin/bash
set -e  # Exit on any error

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update package database and install required packages
pacman -Sy --noconfirm || { echo "Failed to update package database"; exit 1; }
pacman -S --needed --noconfirm jq git || { echo "Failed to install required packages"; exit 1; }

# Verify the repository exists in the expected location
if [ ! -d "/root/hypervarch" ]; then
    echo "Repository not found in /root/hypervarch"
    echo "Cloning repository..."
    git clone https://github.com/pentestfunctions/hypervarch.git /root/hypervarch || { echo "Failed to clone repository"; exit 1; }
fi

# Print installation summary
echo "=== Installation Summary ==="
echo "• Installing Arch Linux with custom configuration"
echo "• Files will be copied from: /root/hypervarch"
echo "• Username and password will be: robot"
echo "=========================="

# Run archinstall
echo "Starting installation..."
archinstall --config /root/hypervarch/user_configuration.json \
           --creds /root/hypervarch/user_credentials.json \
           --silent || { echo "Installation failed"; exit 1; }

# Verify the files were copied correctly
echo "Verifying installation..."
if [ -f "/mnt/usr/local/bin/welcome_message.sh" ] && \
   [ -f "/mnt/etc/systemd/system/first-boot.service" ]; then
    echo "Files copied successfully!"
else
    echo "Warning: Some files may not have been copied correctly"
    ls -l /mnt/usr/local/bin/welcome_message.sh
    ls -l /mnt/etc/systemd/system/first-boot.service
fi

echo "Installation completed!"
chroot /mnt/archinstall rm /usr/share/wayland-sessions/gnome-wayland.desktop
/sbin/reboot -f
