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
yay -S hyprland nano openssh pacman-contrib sddm-git waybar-hyprland-git

#Bar Tools
yay -S rofi swayidle swaylock-effects swww  waybar-updates 
#Install Fonts
yay -S adobe-source-code-pro-fonts ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-common ttf-jetbrains-mono  

#Installaudio components 
yay -S pipewire wireplumber pavucontrol pipewire-audio pipewire-pulse pipewire-alsa

#Bluetooth components 
yay -S bluez bluez-utils blueman 

#File manager
yay -S thunar gvfs thunar-archive-plugin file-roler thunar-media-tags-plugin thunar-volman thunar-shares-plugin tumbler gvfs-mtp 

#Other packages
yay -S gnome-keyring jq polkit-kde-agent qt6-base qt5-base xdg-desktop-portal-hyprland

#Screenshot
yay -S lua maim slurp wl-clipboard




#Copy fonts
