---
title: "Install Arch Linux on Lenovo ThinkPad X1 Carbon 5th Generation"
date: 2019-01-03T14:38:04Z
language: en
categories: [
  "notes"
]
tags: [
  "arch",
  "x1carbon",
  "linux"
]
---

First, from Windows 10, set up fingerprint scannerm enroll fingers. Shut down.

Plug in power and ethernet cable and flash drive. Powere on, press Enter and F12, boot from USB flash drive.

Bear with ack of scaling on a HiDPI display

Test keyboard, set root password, enable SSHd, print ethernet's IP address
```
showkey --scancodes
whoami
passwd
systemctl start sshd
ip a
```

Connect from another machine:
```
ssh root@IPADDRESS
```

Ensure `$TERM` is set correctly:
```
TERM=xterm
```

Set keyboard layout
```
loadkeys us
```

Update the system clock
```
timedatectl set-ntp true
```

Verify Internet connection
```
ping archlinux.org
```

Ensure UEFI boot entries are clear
```
efibootmgr -v

# Boot0000* debian
# Boot0001* ubuntu
# Boot0002* Linux Boot Manager

efibootmgr -b 0000 -B
```

Identify storage device:
```
lsblk
```

Wipe flash drive (NVMe):
```
wipefs --all /dev/nvme0n1
```

Partion storage device drive, 2 partitions:
```
parted -s /dev/nvme0n1 mklabel gpt

parted -s /dev/nvme0n1 mkpart primary fat32 1MB 513MB
parted -s /dev/nvme0n1 set 1 esp on
parted -s /dev/nvme0n1 name 1 boot

parted -s /dev/nvme0n1 mkpart primary linux-swap 513MB 16897MB
parted -s /dev/nvme0n1 name 2 swap

parted -s /dev/nvme0n1 mkpart primary 16897MB 100%
parted -s /dev/nvme0n1 name 3 root

parted -s /dev/nvme0n1 unit s print
parted -s /dev/nvme0n1 unit MB print
```

Create the LUKS encrypted container
```
cryptsetup luksFormat --type luks2 /dev/nvme0n1p3
```

Open the LUKS encrypted container
```
cryptsetup open /dev/nvme0n1p3 root
ls -l /dev/mapper/root
```

Create `vfat` filesystem on ESP EFI boot partition
```
mkfs.vfat /dev/nvme0n1p1
```

Create `swap` filesystem on second partion
```
mkswap /dev/nvme0n1p2
swapon /dev/nvme0n1p2
```

Create `btrfs` filesystem on main partition
```
mkfs.btrfs -L root /dev/mapper/root
mount /dev/mapper/root /mnt -o defaults,noatime,autodefrag
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot -o defaults,noatime

btrfs subvolume create /mnt/home
mount /dev/mapper/root /mnt/home -o subvol=/home,defaults,noatime,autodefrag

mount -l | grep /mnt
```

Bootstrap Arch Linux
```
pacstrap /mnt base base-devel intel-ucode btrfs-progs sudo networkmanager iptables \
  terminus-font openssh neovim git xorg xorg-xinit xorg-xeyes cinnamon firefox lightdm
```

Filesystem table
```
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
```

Change root
```
arch-chroot /mnt
nvim /etc/fstab
```

Set clock
```
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc
systemctl enable systemd-timesyncd.service
```

Set locale, keymap and console font
```
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo 'KEYMAP=us' > /etc/vconsole.conf
echo 'FONT=ter-132n' >> /etc/vconsole.conf
locale-gen
```

SSD: enable Periodic TRIM
```
systemctl enable fstrim.timer
```
Set hostname
```
echo 'workbench' > /etc/hostname

cat > /etc/hosts <<- EOM
# Static table lookup for hostnames.
# See hosts(5) for details.
127.0.0.1	localhost
::1		localhost
127.0.1.1	workbench.localdomain	workbench
EOM
```

Revert to traditional network interface names
```
ln -s /dev/null /etc/systemd/network/99-default.link
```

Configure systemd-network manager
```
cat > /etc/systemd/network/20-wired.network <<- EOM
[Match]
Name=eth0

[Network]
DHCP=yes
EOM

cat > /etc/systemd/network/21-wireless_lan.network <<- EOM          
[Match]
Name=wlan0

[Network]
DHCP=yes
EOM

cat > /etc/systemd/network/21-wireless_wan.network <<- EOM
[Match]
Name=wwan0   

[Network]
DHCP=yes
EOM

systemctl disable systemd-networkd.service systemd-resolved.service
systemctl enable NetworkManager
```

Configure firewall
```
cat > /etc/iptables/iptables.rules <<- EOM
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
:TCP - [0:0]
:UDP - [0:0]
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -m conntrack --ctstate INVALID -j DROP
-A INPUT -p icmp -m icmp --icmp-type 8 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p udp -m conntrack --ctstate NEW -j UDP
-A INPUT -p tcp --tcp-flags FIN,SYN,RST,ACK SYN -m conntrack --ctstate NEW -j TCP
-A INPUT -p udp -j REJECT --reject-with icmp-port-unreachable
-A INPUT -p tcp -j REJECT --reject-with tcp-reset
-A INPUT -j REJECT --reject-with icmp-proto-unreachable
COMMIT
EOM

systemctl enable iptables
```

Disable IPv6 (temp)
```
echo 'ipv6.disable=1' > /etc/sysctl.d/99-disable_ipv6.conf
```

Configure bootloader: set pacman hook
```
mkdir /etc/pacman.d/hooks

cat > /etc/pacman.d/hooks/systemd-boot.hook <<- EOM
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating systemd-boot
When = PostTransaction
Exec = /usr/bin/bootctl update
EOM
```

```
blkid /dev/nvme0n1p3
```

Configure InitRamdriveFs: mkinitcpio. Change this line to:
`MODULES=(intel_agp i915)`
`HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt sd-lvm2 filesystems fsck)`
```
cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.orig

echo 'MODULES=(intel_agp i915)' > /etc/mkinitcpio.conf
echo 'HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt sd-lvm2 filesystems fsck)' >> /etc/mkinitcpio.conf
```

Generate `initramfs`
```
mkinitcpio -p linux
```

Ignore these warning:
```
==> WARNING: Possibly missing firmware for module: aic94xx
==> WARNING: Possibly missing firmware for module: wd719x
```

Configure bootloader: identify root partition's UUID and add entry
```
mkdir -p /boot/loader/entries

cat > /boot/loader/loader.conf <<- EOM
default  arch
# timeout  3
# console-mode auto
editor   no
EOM

cat > /boot/loader/entries/arch.conf <<- EOM
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options rd.luks.name=cdfe533a-fc9f-4b76-b00d-f604b9c96fa4=root root=/dev/mapper/root rw i915.fastboot=1 quiet systemd.show_status=false
EOM
```

Write bootloader
```
bootctl --path=/boot install
```

Enable udev suspend
```
cat > /etc/udev/rules.d/99-lowbat.rules <<- EOM
# Suspend the system when battery level drops to 5% or lower
SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-5]", RUN+="/usr/bin/systemctl hibernate"
EOM
```

User management
```
passwd root

useradd -m -G wheel waltlenu
echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel
passwd waltlenu
```
Exit chroot, unmount filesystems, reboot
```
exit 
umount -R /mnt
reboot
```

Ref.
https://wiki.archlinux.org/index.php/Lenovo_ThinkPad_X1_Carbon_(Gen_5)
