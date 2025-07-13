# Arch Linux guide

## Installation

### Pre-condition checks and settings

- verify UEFI mode `ls /sys/firmware/efi/efivars`
- check network `ip link`
- check network with ping `ping archlinux.org`
- update the system clock `timedatectl set-ntp true`
- check service status `timedatectl status`

### Partition

#### BTRFS on LUKS
- run `cfdisk /dev/nvmen01` and create two partitions - one for `/boot` as `EFI` and second for "system"
- check disks with `lsblk`
- `mkfs.fat -F32 /dev/nvmen01p1`
- `cryptsetup luksFormat /dev/nvmen01p2` -- for system partition
- `cryptsetup open /dev/nvmen01p2 cryptroot`
- `mkfs.btrfs /dev/mapper/cryptroot`
- `mount /dev/mapper/cryptroot /mnt`
- `btrfs subvolume create /mnt/@`
- `btrfs subvolume create /mnt/@home`
- `btrfs subvolume create /mnt/@log`
- `btrfs subvolume create /mnt/@cache`
- `btrfs subvolume create /mnt/@archive`
- `btrfs subvolume create /mnt/@data`
- `umount /mnt`
- `mount -o noatime,compress=zstd,subvol=@ /dev/mapper/cryptroot /mnt`
- `mkdir -p /mnt/{boot,home,var/log,var/cache,archive,data}`
- `mount -o noatime,nosuid,nodev,compress=zstd,subvol=@home /dev/mapper/cryptroot /mnt/home`
- `mount -o noatime,nosuid,nodev,compress=zstd,subvol=@cache /dev/mapper/cryptroot /mnt/var/cache`
- `mount -o noatime,nosuid,nodev,compress=zstd:5,subvol=@log /dev/mapper/cryptroot /mnt/var/log`
- `mount -o noatime,nosuid,nodev,noexec,compress=zstd:8,subvol=@archive /dev/mapper/cryptroot /mnt/archive`
- `mount -o noatime,nodev,noexec,compress=zstd,subvol=@data /dev/mapper/cryptroot /mnt/data`
- `mount /dev/nvmen01p1 /mnt/boot`

##### Configuration
- `pacstrap /mnt archlinux-keyring dhcpcd base linux linux-firmware vim iwd net-tools base-devel mkinitcpio btrfs-progs nvidia`
- for Intel append `intel-ucode` or `amd-ucode`
- edit `/mnt/etc/mkinitcpio.conf` and it's `HOOKS` to include `HOOKS=(... block encrypt filesystems fsck)`
- optionally edit `/mnt/etc/mkinitcpio.conf` and it's `MODULES` to include `MODULES=(nvme nvidia)`
- `genfstab -U /mnt >> /mnt/etc/fstab`

###### Chroot

```
arch-chroot /mnt
```

###### Boot

edit boot entry `/boot/loader/loader.conf`
```
default 	arch.conf
timeout 	4
editor 		0
```

- `bootctl install`
- get UUID of devices with `blkid /dev/nvme*` for `LUKS` partition

create/edit `/boot/loader/entries/arch.conf`
```
title 		Arch Linux
linux 		/vmlinuz-linux
initrd 		/intel-ucode.img  # or amd-ucode.img
initrd 		/initramfs-linux.img
options 	cryptdevice=UUID=YOUR_UUID:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ lsm=landlock,lockdown,yama,integrity,apparmor,bpf rw
```
- update `bootctl update`

###### Time zone
- `ln -sf /usr/share/zoneinfo/Europe/Prague /etc/localtime`
- `hwclock --systohc`

###### Localization
- `vim /etc/locale.gen` -- uncomment `CS` and `US` with `UTF-8`
- `locale-gen`
- set default language `/etc/locale.conf` with `LANG=en_US.UTF-8`

###### Network
- `sudo systemctl enable dhcpcd`
- `sudo systemctl start dhcpcd`
- `echo 'dell' >> /etc/hostname`
- `echo '127.0.0.1 localhost' >> /etc/hosts`
- `echo '::1 localhost' >> /etc/hosts`
- `echo '127.0.1.1 dell' >> /etc/hosts`

###### Initramfs
- `mkinitcpio -P`

###### Root password
- `passwd`

#### Reboot
- `umount -R /mnt`
- `reboot`

#### Post-installation

##### Network
- `echo 'nameserver 1.1.1.1' > /etc/resolv.conf`
- `echo 'nameserver 8.8.8.8' >> /etc/resolv.conf`
- `chattr +i /etc/resolv.conf`

##### User

- `useradd -m -G wheel dom`
- `passwd dom`
- `export EDITOR=vim`
- `visudo` -- uncomment `%wheel`
- reboot and log in as `dom`

##### AUR
- `sudo pacman -S git`
- `cd /opt`
- `sudo git clone https://aur.archlinux.org/yay-git.git`
- `sudo chown -R dom:dom yay-git`
- `cd yay-git`
- `makepkg -si`
- upgrade `yay -Syu`

##### Display server
- `sudo pacman -S hyprland sddm`
- `sudo systemctl enable hyprland`
- `sudo systemctl enable sddm`


##### Firewall

- `sudo pacman -S nftables`
- `sudo systemctl enable nftables`
- `sudo systemctl start nftables`
- `sudo vim /etc/nftables.conf` -- add `drop` to `forward` instead of any content inside `{}`
- `sudo systemctl restart nftables`

##### Packages
- `sudo pacman -S archlinux-keyring hypridle hyprshot hyprlock libnotify mako less nautilus tree mc php pavucontrol apparmor strace dnsmasq dnsutils vlc curl wget git tig firefox firefox-developer-edition chromium lxc htop thunderbird keepassxc gnupg openssh tmux kitty redis lxc postgresql`
- `yay -S intellij-idea-ultimate-edition docker docker-compose sublime-text-4 dropbox postman-bin hub-bin pspg downgrade`
- `sudo usermod -aG docker $(whoami)`
- `sudo systemctl enable paccache.timer`
- `sudo systemctl start paccache.timer`
- `sudo vim /etc/pacman.conf` -- uncomment `VerbosePkgLists`

##### Docker
Set directory to store docker files to `/data/docker`:
- `sudo mkdir /data/docker && echo '{"data-root": "/data/docker"}' | sudo tee /etc/docker/daemon.json`


##### Network

- `sudo systemctl disable systemd-networkd`
- `sudo systemctl disable dhcpcd`
- `sudo systemctl enable NetworkManager`
- `sudo systemctl start NetworkManager`

##### AppArmor
- check if enabled `aa-enabled`
- check loaded status `aa-status`
- `sudo systemctl enable apparmor`
- `sudo systemctl start apparmor`


##### Fonts
- `sudo pacman -S ttf-dejavu ttf-liberation noto-fonts`
```
sudo ln -s /etc/fonts/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d
sudo ln -s /etc/fonts/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d
sudo ln -s /etc/fonts/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d
```

##### PAM
- `sudo su`
- `passwd`
- `passwd dom`
- `sudo vim /etc/security/faillock.conf` -- set `deny` to `20`

##### Utils
- `sudo systemctl enable fstrim.timer`
- `sudo systemctl start fstrim.timer`
