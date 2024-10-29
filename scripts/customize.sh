#!/bin/bash

initial_dir=$(pwd)

# Setting a new wallpaper for Xfce
install_wallpaper_settings() {
    cd "$initial_dir"
    mkdir -p ~/Pictures
    sudo cp resources/background.png ~/Pictures/background.png
    sudo cp resources/background.bmp /etc/background.bmp
    xfconf-query -c xfce4-desktop -l -v | grep image-path | grep -oE '^/[^ ]+' | xargs -I % xfconf-query -c xfce4-desktop -p % -s ~/Pictures/background.png
    xfconf-query -c xfce4-desktop -l -v | grep last-image | grep -oE '^/[^ ]+' | xargs -I % xfconf-query -c xfce4-desktop -p % -s ~/Pictures/background.png
}

add_panel_items() {
    local panel_id=$(xfconf-query -c xfce4-panel -l -v 2>/dev/null | grep "applicationsmenu" | awk '{print $1}')
    if ! xfconf-query -c xfce4-panel -p $panel_id -l 2>/dev/null | grep -q "whiskermenu"; then
        xfconf-query -c xfce4-panel -p $panel_id -n -t string -s "whiskermenu" 2>/dev/null
        xfce4-panel -r
    fi
    echo -e "\033[0;32mWhiskermenu setup completed\033[0m"
}

install_wallpaper_settings
add_panel_items
