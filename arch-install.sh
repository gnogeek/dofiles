#!/usr/bin/env -S bash -e

# Fixing annoying issue that breaks GitHub Actions
# shellcheck disable=SC2001

# Cleaning the TTY.
clear

# Cosmetics (colours for text).
BOLD='\e[1m'
BRED='\e[91m'
BBLUE='\e[34m'  
BGREEN='\e[92m'
BYELLOW='\e[93m'
RESET='\e[0m'

# Pretty print (function).
info_print () {
    echo -e "${BOLD}${BGREEN}[ ${BYELLOW}•${BGREEN} ] $1${RESET}"
}

# Pretty print for input (function).
input_print () {
    echo -ne "${BOLD}${BYELLOW}[ ${BGREEN}•${BYELLOW} ] $1${RESET}"
}

# Alert user of bad input (function).
error_print () {
    echo -e "${BOLD}${BRED}[ ${BBLUE}•${BRED} ] $1${RESET}"
}

# Setting up a password for the user account (function).
    input_print "Please enter name for a user account (enter empty to not create one): "
    read -r username
# Hostname Selection
    input_print "Please enter the hostname: "
    read -r hostname


# Enable error handling.
set -euxo pipefail

# Enable logging.
LOGFILE="install.log"
exec &> >(tee -a "$LOGFILE")

# Configuration options. All variables should be exported, so that they will be availabe in the arch-chroot.
#export KEYMAP="de-latin1"
export LANG="en_US.UTF-8"
export LOCALE="en_US.UTF-8 UTF-8"
export TIMEZONE="America/Santo_Domingo"
export COUNTRY="US"
export HOSTNAME=$hostname
export USERNAME=$username
export PASSWORD=$USERNAME # It is not recommended to set production passwords here.
export EFIPARTITION=/dev/sda1
export ROOTPARTITION=/dev/sda4
#export HOMEPARTITION=/dev/nvme0n1p5
#export EFIPARTITION=${DISK}p1
#export ROOTPARTITION=${DISK}p2
#export HOMEPARTITION=/dev/sda5
#export SWAPPARTITION=/dev/nvme0n1p5
export sv_opts="rw,noatime,compress-force=zstd:1,space_cache=v2"
export DISKID=$(lsblk $ROOTPARTITION -o partuuid -n)

# Find and set mirrors. This mirror list will be automatically copied into the installed system.
#pacman -Sy --needed --noconfirm reflector
#reflector --country $COUNTRY --age 20 --latest 15 --sort rate --protocol https --save /etc/pacman.d/mirrorlist

# Get the "/dev/..." name of the first partition, format it and mount.
mkfs.btrfs -f $ROOTPARTITION
#mkfs.vfat $EFIPARTITION
mount $ROOTPARTITION /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@tmp
umount /mnt
mount -o ${sv_opts},subvol=@ $ROOTPARTITION /mnt
mkdir -p /mnt/{home,.snapshots,var/cache,var/log,var/tmp,boot}
mount -o ${sv_opts},subvol=@home $ROOTPARTITION /mnt/home
mount -o ${sv_opts},subvol=@snapshots $ROOTPARTITION /mnt/.snapshots
mount -o ${sv_opts},subvol=@cache $ROOTPARTITION /mnt/var/cache
mount -o ${sv_opts},subvol=@log $ROOTPARTITION /mnt/var/log
mount -o ${sv_opts},subvol=@tmp $ROOTPARTITION /mnt/var/tmp
mount $EFIPARTITION /mnt/boot

sed -i '1iServer = http://192.168.100.225:7878/$repo/os/$arch' /etc/pacman.d/mirrorlist
# Install base files and update fstab.
pacstrap -K /mnt base linux linux-firmware intel-ucode btrfs-progs pacman-contrib
genfstab -U /mnt >> /mnt/etc/fstab

##
sed -i 's/subvolid=.*,//' /etc/fstab
# Extend logging to persistant storage.
cp "$LOGFILE" /mnt/root/
exec &> >(tee -a "$LOGFILE" | tee -a "/mnt/root/$LOGFILE")

# This function will be executed inside the arch-chroot.
archroot() {
  # Enable error handling again, as this is technically a new execution.
  set -euxo pipefail

  # Set and generate locales.
  echo "LANG=$LANG" >> /etc/locale.conf
  #echo "KEYMAP=$KEYMAP" >> /etc/vconsole.conf
  sed -i "/$LOCALE/s/^#//" /etc/locale.gen # Uncomment line with sed
  locale-gen

  # Set time zone and clock.
  ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
  hwclock --systohc

  # Set hostname.
  echo "$HOSTNAME" > /etc/hostname

  # This is optional.
  # mkinitcpio -P
  
  # Install boot loader.
  #pacman -S --needed --noconfirm refind
  #pacman -S --needed --noconfirm grub
  #grub-install $DISK
  #grub-mkconfig -o /boot/grub/grub.cfg

  # Install and enable network manager.
  pacman -S --needed --noconfirm networkmanager
  systemctl enable NetworkManager
  # Install other packages
  pacman -S --needed --noconfirm efibootmgr openssh xf86-video-intel wireless_tools wpa_supplicant dialog wget nano

  systemctl enable fstrim.timer
  # Install and configure sudo.
  pacman -S --needed --noconfirm sudo
  sed -i '/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^# //' /etc/sudoers # Uncomment line with sed

  # Create a new user and add it to the wheel group.
  useradd -m -G wheel $USERNAME
  echo $USERNAME:$PASSWORD | chpasswd
  passwd -e $USERNAME # Force user to change password at next login.
  passwd -dl root # Delete root password and lock root account.

  # Install git as prerequisite for the next steps.
  pacman -S --needed --noconfirm git base-devel cargo 

  # Install an AUR helper.
  cd /tmp
  sudo -u $USERNAME git clone https://aur.archlinux.org/yay.git
  cd yay
  sudo -u $USERNAME makepkg -sri --noconfirm
  cd .. && rm -R yay
  sed -i '/^#Color/s/#//' /etc/pacman.conf # Uncomment line with sed

    # Install some software.   
  # Install boot manager.   
 bootctl install
  tee -a /boot/loader/loader.conf <<EOF
default      arch.conf
timeout      0
editor       no
console-mode auto
EOF

##
  sed -i 's,#COMPRESSION="zstd",COMPRESSION="zstd",g' /etc/mkinitcpio.conf
  sed -i 's,MODULES=(),MODULES=(btrfs),g' /etc/mkinitcpio.conf
##
  tee -a /boot/loader/entries/arch.conf <<EOF
title Arch Linux  
linux /vmlinuz-linux  
initrd /intel-ucode.img  
initrd /initramfs-linux.img  
options root=PARTUUID=$DISKID rootfstype=btrfs rootflags=subvol=@ elevator=deadline add_efi_memmap rw quiet splash loglevel=3 vt.global_cursor_default=0 plymouth.ignore_serial_consoles vga=current rd.systemd.show_status=auto r.udev.log_priority=3 nowatchdog fbcon=nodefer i915.fastboot=1
EOF
#Make mkinitcpio
mkinitcpio -p linux

#Install timeshift
sudo -u $USERNAME yay -S --needed --noconfirm timeshift timeshift-autosnap

  tee -a /etc/udev/rules.d/backlight.rules <<EOF
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video $sys$devpath/brightness", RUN+="/bin/chmod g+w $sys$devpath/brightness"
EOF

    
  # Reconfigure sudo, so that a password is need to elevate privileges.
  sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/# //' /etc/sudoers # Uncomment line with sed
  sed -i '/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^/# /' /etc/sudoers # Comment line with sed
  echo "Finished archroot." 
}

# Export the function so that it is visible by bash inside arch-chroot.
export -f archroot
arch-chroot /mnt /bin/bash -c "archroot" || echo "arch-chroot returned: $?"

# Lazy unmount.
umount -l /mnt

cat << 'EOT'
******************************************************
* Finished. You can now reboot into your new system. *
******************************************************
EOT