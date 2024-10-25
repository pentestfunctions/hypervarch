#!/bin/bash

# Copy welcome message script and set permissions
cp /root/hypervarch/scripts/welcome_message.sh /usr/local/bin/
chmod +x /usr/local/bin/welcome_message.sh
chown robot:robot /usr/local/bin/welcome_message.sh

# Copy and configure systemd service
cp /root/hypervarch/scripts/welcome-message.service /etc/systemd/system/
systemctl enable welcome-message.service

# Create autostart directory if it doesn't exist
mkdir -p /home/robot/.config/autostart
chown robot:robot /home/robot/.config/autostart

# Create welcome message backup
cp /usr/local/bin/welcome_message.sh /home/robot/.welcome_message
chown robot:robot /home/robot/.welcome_message
