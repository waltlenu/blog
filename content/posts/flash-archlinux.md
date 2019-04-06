---
title: "Flash ArchLinux"
date: 2019-01-03T13:31:26Z
tags:
  - ArchLinux
  - Flash
  - ISO
  - Linux
---
Download:
```
wget http://mirror.rackspace.com/archlinux/iso/2019.01.01/archlinux-2019.01.01-x86_64.iso
wget http://mirror.rackspace.com/archlinux/iso/2019.01.01/archlinux-2019.01.01-x86_64.iso.sig
```

Verify download. From an existing Arch Linux installation run:
```
pacman-key -v archlinux-version-x86_64.iso.sig
```

Wipe flash drive:
```
sudo wipefs --all /dev/sda
```

Flash ISO file to storage device:
```
sudo dd bs=4M if=archlinux-2019.01.01-x86_64.iso of=/dev/sda status=progress oflag=sync
```
