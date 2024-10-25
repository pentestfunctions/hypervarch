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

# Print summary
echo "Installing Arch Linux..."
echo "Username and password will be: robot"

# Run archinstall
archinstall --config hypervarch/user_configuration.json --creds hypervarch/user_credentials.json --silent
