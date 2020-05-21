+++
draft = false
title = "Install ArchLinux on Lenovo ThinkPad X1 Carbon 5th Generation"
date = "2019-01-03T14:38:04Z"
description = "install ArchLinux"
slug = ""
tags = ["arch", "linux", "x1carbon"]
categories = ["notes"]
externalLink = ""
series = []
+++
First, from Windows 10, set up the fingerprint scanner and enroll fingers. Linux driver does not support the process. Shut down.

Plug in power and Ethernet cable and flash drive. Power on, press Enter and F12, boot from USB flash drive.
Bear with the lack of scaling on a HiDPI display.

Test keyboard, set `root`'s password, enable `SSHd`, print ethernet's IP address:

```bash
showkey --scancodes
whoami
passwd
systemctl start sshd
ip a
```

Connect from another machine:

```bash
ssh root@IPADDRESS
```

Ensure `$TERM` is set correctly:

```bash
TERM=xterm
```

Set keyboard layout:

```bash
loadkeys us
```

Update the system clock:

```bash
timedatectl set-ntp true
```

Verify Internet connection:

```bash
ping archlinux.org
```

Ensure UEFI boot entries are clear:

```bash
efibootmgr -v

Boot0000* debian
Boot0001* ubuntu
Boot0002* Linux Boot Manager
```

Delete unnecessary boot entries:

```bash
efibootmgr -b 0000 -B
```

Identify storage device:

```bash
lsblk
```

Wipe flash drive (NVMe):

```bash
wipefs --all /dev/nvme0n1
```

Partion storage device drive, 2 partitions:

```bash
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

Create the LUKS encrypted container:

```bash
cryptsetup luksFormat --type luks2 /dev/nvme0n1p3
```

Open the LUKS encrypted container:

```bash
cryptsetup open /dev/nvme0n1p3 root
ls -l /dev/mapper/root
```

Create `vfat` filesystem on ESP EFI boot partition:

```bash
mkfs.vfat /dev/nvme0n1p1
```

Create `swap` filesystem on second partion:

```bash
mkswap /dev/nvme0n1p2
swapon /dev/nvme0n1p2
```

Create `btrfs` filesystem on main partition:

```bash
mkfs.btrfs -L root /dev/mapper/root
mount /dev/mapper/root /mnt -o defaults,noatime,autodefrag
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot -o defaults,noatime

btrfs subvolume create /mnt/home
mount /dev/mapper/root /mnt/home -o subvol=/home,defaults,noatime,autodefrag

mount -l | grep /mnt
```

Bootstrap Arch Linux:

```bash
pacstrap /mnt \
  base linux linux-firmware \
  intel-ucode mkinitcpio btrfs-progs lvm2 mdadm \
  sudo networkmanager iptables openssh \
  base-devel neovim git
```

Filesystem table:

```bash
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
```

Change root:

```bash
arch-chroot /mnt
nvim /etc/fstab
```

Set clock:

```bash
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc
systemctl enable systemd-timesyncd.service
```

Set locale, keymap and console font:

```bash
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo 'KEYMAP=us' > /etc/vconsole.conf
echo 'FONT=ter-132n' >> /etc/vconsole.conf
locale-gen
```

SSD: enable Periodic TRIM:

```bash
systemctl enable fstrim.timer
```

Set hostname:

```bash
echo 'workbench' > /etc/hostname

cat > /etc/hosts <<- EOM
# Static table lookup for hostnames.
# See hosts(5) for details.
127.0.0.1	localhost
::1		localhost
127.0.1.1	workbench.localdomain	workbench
EOM
```

Revert to traditional network interface names:

```bash
ln -s /dev/null /etc/systemd/network/99-default.link
```

Configure systemd-network manager:

```bash
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

Configure firewall:

```bash
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

Disable IPv6 (temp):

```bash
echo 'ipv6.disable=1' > /etc/sysctl.d/99-disable_ipv6.conf
```

Configure bootloader: set pacman hook:

```bash
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

```bash
blkid /dev/nvme0n1p3
```

Configure InitRamdriveFs: mkinitcpio. Change this line to:
`MODULES=(intel_agp i915)`
`HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt sd-lvm2 filesystems fsck)`

```bash
cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.orig

echo 'MODULES=(intel_agp i915)' > /etc/mkinitcpio.conf
echo 'HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt sd-lvm2 resume filesystems fsck)' >> /etc/mkinitcpio.conf
```

Generate `initramfs`:

```bash
mkinitcpio -p linux
```

Ignore these warnings:

```text
==> WARNING: Possibly missing firmware for module: aic94xx
==> WARNING: Possibly missing firmware for module: wd719x
```

Configure bootloader: identify root partition's UUID and add entry:

```bash
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

Write bootloader:

```bash
bootctl --path=/boot install
```

Enable udev suspend:

```bash
cat > /etc/udev/rules.d/99-lowbat.rules <<- EOM
# Suspend the system when battery level drops to 5% or lower
SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-5]", RUN+="/usr/bin/systemctl hibernate"
EOM
```

User management:

```bash
passwd root

useradd -m -G wheel waltlenu
echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel
passwd waltlenu
```

Exit chroot, unmount filesystems, reboot:

```bash
exit
umount -R /mnt
reboot
```

Login as normal user. Install AUR helper:

```bash
mkdir -p ~/src/tmp
cd ~/src/tmp
git clone https://aur.archlinux.org/yay-bin.git ~/src/tmp/yay-bin
cd ~/src/tmp/yay-bin
makepkg -si
rm -rf ~/src/tmp/yay-bin
```

Install required:

```bash
yay -Sy \
  base linux linux-firmware \
  intel-ucode mkinitcpio btrfs-progs lvm2 mdadm \
  sudo networkmanager iptables openssh \
  base-devel neovim git chezmoi
```

Reference wiki [page](https://wiki.archlinux.org/index.php/Lenovo_ThinkPad_X1_Carbon_(Gen_5)).
