# Arch Linux guide

## Installation

### Pre-condition checks and settings

- verify UEFI mode `ls /sys/firmware/efi/efivars`
- check network `ip link`
- check network with ping `ping archlinux.org`
- update the system clock `timedatectl set-ntp true`
- check service status `timedatectl status`

### Partition

#### Layout
- Disk size: `512GB`
- RAM size: `16GB`

___

- `/` -> `40GB` -- includes swap file
- `/data` -> `150GB`
- `/boot` -> `512MB`
- `/var` -> `20GB`
- `/home` -> the rest

___

#### LVM on LUKS
- run `cfdisk /dev/nvmen01` and create two partitions - one for "system" and second for `/boot`
- check disks with `lsblk`
- `mkfs.fat -F32 /dev/nvmen01p1`
- `cryptsetup luksFormat /dev/nvmen01p2` -- for system partition
- `cryptsetup open /dev/nvmen01p2 cryptlvm`
- `pvcreate /dev/mapper/cryptlvm`
- `vgcreate grp /dev/mapper/cryptlvm`
- `lvcreate -L 40G grp -n root`
- `lvcreate -L 150G grp -n data`
- `lvcreate -L 20G grp -n var`
- `lvcreate -l 100%FREE grp -n home`
- `mkfs.ext4 /dev/mapper/grp-home`
- `mkfs.ext4 /dev/mapper/grp-var`
- `mkfs.ext4 /dev/mapper/grp-data`
- `mkfs.ext4 /dev/mapper/grp-root`
- `mount /dev/mapper/grp-root /mnt`
- `mkdir /mnt/home`
- `mount /dev/mapper/grp-home /mnt/home`
- `mkdir /mnt/data`
- `mount /dev/mapper/grp-data /mnt/data`
- `mkdir /mnt/var`
- `mount /dev/mapper/grp-var /mnt/var`
- `mkdir /mnt/boot`
- `mount /dev/nvmen01p1 /mnt/boot`

##### Configuration
- `pacstrap /mnt base linux linux-firmware vim dhcpcd iwd net-tools base-devel lvm2 mkinitcpio intel-ucode`
- edit `/mnt/etc/mkinitcpio.conf` and it's `HOOKS` to include `HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)`
- `genfstab -U /mnt >> /mnt/etc/fstab`
- add `noatime` to all
- add `nodev` to all except `/`
- add `nosuid` to all except `/` and `/data`
- add `noexec` to `/boot`

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
- get UUID of devices with `blkid /dev/nvme*`

create/edit `/boot/loader/entries/arch.conf`
```
title 		Arch Linux
linux 		/vmlinuz-linux
inird 		/intel-ucode.img
inird 		/initramfs-linux.img
options 	cryptdevice=UUID=YOUR_UUID:grp root=/dev/mapper/grp-root apparmor=1 lsm=lockdown,yama,apparmor rw
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

#### DHCP
- enable DHCP `sudo systemctl enable dhcpcd`
- start DHCP `sudo systemctl start dhcpcd`

##### User

- `useradd -m -G wheel dom`
- `passwd dom`
- `export EDITOR=vim`
- `visudo` -- uncomment `%wheel`

##### AUR
- `sudo pacman -S git`
- `cd /opt`
- `sudo git clone https://aur.archlinux.org/yay-git.git`
- `sudo chown -R dom:dom yay-git`
- `cd yay-git`
- `makepkg -si`
- upgrade `yay -Syu`

##### Display manager
- `yay -S ly`
- `sudo systemctl enable ly`
- `reboot`

##### Display server
- `sudo pacman -S xorg xorg-server xfce4 xfce4-goodies`
- `vim /etc/X11/xinit/xinitrc` -- append `exec startxfce4`
- `vim /etc/X11/Xwrapper.config` -- `needs_root_rights = no`
- `reboot`

Check is running Xorg rootless: `ps -o user $(pgrep Xorg)`


##### Firewall

- `sudo pacman -S nftables`
- `sudo systemctl enable nftables`
- `sudo systemctl start nftables`
- list rules `sudo nft list ruleset`
- `sudo vim /etc/nftables.conf` -- add `drop` to `forward` and `input`
- `sudo vim /etc/nftables.conf` -- remove the SSH allowed access
- `sudo systemctl restart nftables`
- list new rules `sudo nft list ruleset`

##### Packages
- `sudo pacman -S extra/imagemagick unzip pacman-contrib perl-image-exiftool perl-rename ntfs-3g tree mc bash-completion cronie php ruby pavucontrol apparmor strace dnsmasq gnome-keyring dnsutils vlc curl wget git tig firefox chromium lxc detox htop redshift thunderbird keepass filezilla networkmanager networkmanager-openvpn network-manager-applet gnupg pcsclite ccid hopenpgp-tools yubikey-personalization openssh tmux guake gnome-disk-utility neofetch yubikey-manager qbittorrent unrar baobab youtube-dl recode parallel zip rsync redis intellij-idea-community-edition`
- `yay -S phpstorm phpstorm-jre docker docker-compose sublime-text-3 dropbox postman-bin hub brave-bin pspg ncspot`
- `sudo usermod -aG docker $(whoami)`
- `sudo systemctl enable cronie`
- `sudo systemctl start cronie`
- `sudo systemctl enable paccache.timer`
- `sudo systemctl start paccache.timer`
- `sudo vim /etc/pacman.conf` -- uncomment `VerbosePkgLists`

##### Network
- `echo 'nameserver 1.1.1.1' >> /etc/resolv.conf`
- `echo 'nameserver 8.8.8.8' >> /etc/resolv.conf`
- Remove unused nameservers
- `sudo chattr +i /etc/resolv.conf`
- `sudo systemctl disable systemd-networkd`
- `sudo systemctl disable dhcpcd`
- `sudo systemctl enable NetworkManager`
- `sudo systemctl start NetworkManager`

##### Swap config
- `sudo dd if=/dev/zero of=/swapfile bs=1M count=6000 status=progress`
- `sudo chmod 600 /swapfile`
- `sudo mkswap /swapfile`
- `sudo swapon /swapfile`
- `echo '/swapfile none swap defaults 0 0' >> /etc/fstab`

##### RNGD
- `sudo pacman -S rng-tools`
- `sudo systemctl enable rngd`
- `sudo systemctl start rngd`
- check `cat /proc/sys/kernel/random/entropy_avail`

##### AppArmor
- check if enabled `aa-enabled`
- check loaded status `aa-status`
- `sudo systemctl enable apparmor`
- `sudo systemctl start apparmor`

##### Firejail
- `sudo pacman -S firejail`
- `sudo aa-enforce firejail-default`
- `ln -s /usr/bin/firejail /usr/local/bin/firefox`
- see if running via firejail `firejail --list`	


##### Fonts
- `sudo pacman -S ttf-dejavu ttf-liberation noto-fonts`
```
sudo ln -s /etc/fonts/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d
sudo ln -s /etc/fonts/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d
sudo ln -s /etc/fonts/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d
```

- `vim /etc/profile.d/freetype2.sh` and uncomment last line

##### Umask
- `sudo vim /etc/profile`
- `umask 022`

##### PAM
- `sudo vim /etc/pam.d/passwd`
- add `rounds=65536`
- `sudo su`
- `passwd`
- `passwd dom`
- `sudo vim /etc/security/faillock.conf` -- set `deny` to `20`

##### Sound
- `sudo pacman -S pulseaudio`
- `pulseaudio --check`
- `pulseaudio -D`

##### XFCE
- add `xfce4-popup-whiskermenu` to keyboard-shortcuts

##### Utils
- `sudo systemctl enable fstrim.timer`
- `sudo systemctl start fstrim.timer`