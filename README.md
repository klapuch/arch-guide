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
- `/boot` -> `512MB`
- `/var` -> `20GB`
- `/home` -> the rest

___

#### LVM on LUKS
- run `cfdisk` and create two partitions - one for "system" and second for `/boot`
- check disks with `lsblk`
- `cryptsetup luksFormat /dev/sda1` -- for system partition
- `cryptsetup -y -v luksFormat --type luks1 /dev/sda2` -- for `/boot` partition
- `cryptsetup open /dev/sda1 cryptlvm`
- `cryptsetup open /dev/sda2 cryptboot`
- `mkfs.fat -F32 /dev/mapper/cryptboot`
- `pvcreate /dev/mapper/cryptlvm`
- `vgcreate grp /dev/mapper/cryptlvm`
- `lvcreate -L 40G grp -n root`
- `lvcreate -L 20G grp -n var`
- `lvcreate -l 100%FREE grp -n home`
- `mount /dev/grp/root /mnt`
- `mkdir /mnt/home`
- `mount /dev/grp/home /mnt/home`
- `mkdir /mnt/var`
- `mount /dev/grp/var /mnt/var`
- `mount /dev/mapper/cryptboot /mnt/boot`

##### Configuration
- `pacstrap /mnt base linux-lts linux-firmware vim dhcp dhcpcd iwd net-tools base-devel lvm2 mkinitcpio grub efibootmgr intel-ucode`
- edit `/mnt/etc/mkinitcpio.conf` and it's `HOOKS` to include `HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)`
- get UUID of devices with `ls -la /dev/disk/by-id`
- edit `/mnt/etc/default/grub` and add `cryptdevice=UUID=**device-UUID**:cryptlvm root=/dev/grp/root`
- `genfstab -U /mnt >> /mnt/etc/fstab`
- ? consider to add `noatime` ?


###### Chroot

```
arch-chroot /mnt
```

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

###### GRUB 
- `mkdir /boot/efi`
- `grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi`

Enable early microcode loading: `vim /etc/deafult/grub`
```
CONFIG_BLK_DEV_INITRD=Y
CONFIG_MICROCODE=y
CONFIG_MICROCODE_INTEL=Y
# CONFIG_MICROCODE_AMD=y
```

- `grub-mkconfig -o /boot/grub/grub.cfg`
- check microcode -- `vim /boot/grub/grub.cfg` -- find `initrd	/boot/cpu_manufacturer-ucode.img /boot/initramfs-linux.img`

#### Reboot
- `umount -R /mnt`
- `reboot`

#### Post-installation

##### User

- `useradd -m -G wheel dom`
- `visudo` -- uncomment `%wheel`

##### AUR
- `sudo pacman -S git`
- `cd /opt`
- `sudo git clone https://aur.archlinux.org/yay-git.git`
- `sudo chown -R dom:dom yay-git`
- `cd yay-git`
- `makepkg -si`
- upgrade `sudo yay -Syu`

##### Display manager
- `yay -S ly`
- `sudo systemctl enable ly.service`
- `reboot`

##### Display server
- `sudo pacman -S xorg xorg-server xfce4 xfce4-goodies`
- `vim /etc/X11/xinit/xinitrc` -- append `exec startxfce4`
- `vim /etc/X11/Xwrapper.config` -- `needs_root_rights = no`
- `reboot`

Check is running Xorg rootless: `ps -o user $(pgrep Xorg)`

##### DNS

###### dnsmasq
- `sudo pacman -S dnsmasq`
- `sudo systemctl enable dnsmasq`
- check if running `journalctl -u dnsmasq.service`
- `sudo vim /etc/dnsmasq.conf` -- `listen-address=::1,127.0.0.1`
- `sudo vim /etc/dnsmasq.conf` -- `cache-size=1000`

`sudo vim /etc/resolv.conf`
```
nameserver ::1
nameserver 127.0.0.1
options trust-ad
```

- `sudo chattr -i /etc/resolv.conf`

`sudo vim /etc/dnsmasq.conf`
```
[...]
no-resolv

server=8.8.8.8
```

Enable DNSSEC

`sudo vim /etc/resolv.conf`
```
conf-file=/usr/share/dnsmasq/trust-anchors.conf
dnssec
```

##### Firewall

- `sudo pacman -S nftables`
- `sudo systemctl enable nftables`
- list rules `sudo nft list ruleset`
- `sudo vim /etc/nftables.conf` -- add `drop` to `forward` and `input`
- `sudo systemctl restart nftables`
- list new rules `sudo nft list ruleset`
- `reboot` and check activation etc..

##### Swap config
- `sudo dd if=/dev/zero of=/swapfile bs=1M count=8000 status=progress`
- `sudo chmod 600 /swapfile`
- `sudo mkswap /swapfile`
- `sudo swapon /swapfile`

`sudo vim /etc/fstab`
```
/swapfile none swap defaults 0 0
```

##### Firejail
- `sudo pacman -S firejail`
- `ln -s /usr/bin/firejail /usr/bin/firefox`
- see if running via firejail `firejail --list`

##### AppArmor
- `sudo vim /etc/default/grub` -> `apparmor=1 lsm=lockdown,yama,apparmor` to `GRUB_CMDLINE_LINUX_DEFAULT`
- check if enabled `aa-enabled`
- check loaded status `aa-status`git
