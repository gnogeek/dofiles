#!/usr/bin/env bash

## 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

##Create dirs
    for DIR in hypr kitty rofi swaylock Thunar viewnior waybar xfce4 
    do 
        DIRPATH=~/.config/$DIR
        if [ -d "$DIRPATH" ]; then 
            echo -e "$CAT - Config for $DIR located, backing up."
            mv $DIRPATH $DIRPATH-back &>> $INSTLOG
            echo -e "$COK - Backed up $DIR to $DIRPATH-back."
        fi

        # make new empty folders
        mkdir -p $DIRPATH &>> $INSTLOG
    done


cp -r .config/ $HOME/.config/

#Main Packages
yay -S --noconfirm hyprland nano openssh pacman-contrib sddm-git waybar-hyprland-git

#Bar Tools
yay -S --noconfirm rofi swayidle swaylock-effects swww  waybar-updates 
#Install Fonts
yay -S --noconfirm adobe-source-code-pro-fonts ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-common ttf-jetbrains-mono  

#Installaudio components 
yay -S --noconfirm pipewire wireplumber pavucontrol pipewire-audio pipewire-pulse pipewire-alsa

#Bluetooth components 
yay -S --noconfirm bluez bluez-utils blueman 

#File manager
yay -S --noconfirm thunar gvfs thunar-archive-plugin file-roller thunar-media-tags-plugin thunar-volman thunar-shares-plugin tumbler gvfs-mtp 

#Other packages
yay -S --noconfirm gnome-keyring jq polkit-kde-agent qt6-base qt5-base xdg-desktop-portal-hyprland

#Screenshot
yay -S --noconfirm lua maim slurp wl-clipboard

sudo systemctl enable --now sddm 


#Copy fonts
