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
- RAM size: `16GB` or `32GB`

___

- `/` -> `40GB` -- includes swap file
- `/data` -> `200GB`
- `/boot` -> `512MB`
- `/var` -> `30GB`
- `/home` -> the rest

___

#### LVM on LUKS
- run `cfdisk /dev/nvmen01` and create two partitions - one for `/boot` as `EFI` and second for "system"
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
- `mkdir /mnt/data`
- `mkdir /mnt/var`
- `mkdir /mnt/boot`
- `mount /dev/mapper/grp-home /mnt/home`
- `mount /dev/mapper/grp-data /mnt/data`
- `mount /dev/mapper/grp-var /mnt/var`
- `mount /dev/nvmen01p1 /mnt/boot`

##### Configuration
- `pacman -Syu archlinux-keyring`
- `pacstrap /mnt archlinux-keyring dhcpcd base linux linux-firmware vim iwd net-tools base-devel lvm2 mkinitcpio`
- for Intel append `intel-ucode` or `amd-ucode`
- edit `/mnt/etc/mkinitcpio.conf` and it's `HOOKS` to include `HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)`
- optionally edit `/mnt/etc/mkinitcpio.conf` and it's `MODULES` to include `MODULES=(nvme)`
- `genfstab -U /mnt >> /mnt/etc/fstab`
- change `relatime` to `noatime` to all
- add `nodev` to all except `/`
- add `nosuid` to all except `/` and `/data`
- add `noexec` to `/boot`

###### Chroot

```
arch-chroot /mnt
```
git@github.com:klapuch/arch-guide.git
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
- `sudo pacman -S gnome`
- `sudo systemctl enable gdm`
- `sudo systemctl start gdm`


##### Firewall

- `sudo pacman -S nftables`
- `sudo systemctl enable nftables`
- `sudo systemctl start nftables`
- list rules `sudo nft list ruleset`
- `sudo vim /etc/nftables.conf` -- add `drop` to `forward` instead of any content inside `{}`
- `sudo vim /etc/nftables.conf` -- remove the SSH allowed access
- `sudo systemctl restart nftables`
- list new rules `sudo nft list ruleset`

##### Packages
- `sudo pacman -S archlinux-keyring bluez bluez-utils extra/imagemagick unzip pacman-contrib perl-image-exiftool perl-rename ntfs-3g tree mc bash-completion cronie php ruby pavucontrol apparmor strace dnsmasq dnsutils vlc curl wget git tig firefox firefox-developer-edition chromium lxc detox htop redshift thunderbird keepass filezilla networkmanager gnupg pcsclite ccid hopenpgp-tools yubikey-personalization openssh tmux guake neofetch yubikey-manager qbittorrent unrar baobab recode parallel zip rsync redis usbutils gnome-tweak-tools lxc postgresql nfs-utils`
- `yay -S intellij-idea-ultimate-edition intellij-idea-ultimate-edition-jre docker docker-compose sublime-text-4 dropbox postman-bin hub brave-bin pspg tor-browser downgrade minq-ananicy-git`
- `sudo usermod -aG docker $(whoami)`
- `sudo systemctl enable cronie`
- `sudo systemctl start cronie`
- `sudo systemctl enable paccache.timer`
- `sudo systemctl start paccache.timer`
- `sudo vim /etc/pacman.conf` -- uncomment `VerbosePkgLists`

##### Ananicy
- `sudo systemctl enable ananicy.service`
- `sudo systemctl start ananicy.service`

##### Docker
Set directory to store docker files to `/data/docker`:
- `sudo mkdir /data/docker && echo '{"data-root": "/data/docker"}' | sudo tee /etc/docker/daemon.json`

##### Network
- `sudo systemctl disable systemd-networkd`
- `sudo systemctl disable dhcpcd`
- `sudo systemctl enable NetworkManager`
- `sudo systemctl start NetworkManager`

##### Swap config
- `sudo dd if=/dev/zero of=/swapfile bs=1M count=6000 status=progress`
- `sudo chmod 600 /swapfile`
- `sudo mkswap /swapfile`
- `sudo swapon /swapfile`
- `echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab`

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

##### Utils
- `sudo systemctl enable fstrim.timer`
- `sudo systemctl start fstrim.timer`
