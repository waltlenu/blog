+++
draft = false
title = "Flash Arch Linux"
date = "2019-01-03T13:31:26Z"
description = "set favicons"
slug = ""
tags = ["flash", "iso", "linux"]
categories = ["notes"]
series = []
+++
Download:

```bash
wget http://mirror.rackspace.com/archlinux/iso/2019.01.01/archlinux-2019.01.01-x86_64.iso
wget http://mirror.rackspace.com/archlinux/iso/2019.01.01/archlinux-2019.01.01-x86_64.iso.sig
```

Verify download. From an existing Arch Linux installation run:

```bash
pacman-key -v archlinux-version-x86_64.iso.sig
```

Wipe flash drive:

```bash
sudo wipefs --all /dev/sda
```

Flash ISO file to storage device:

```bash
sudo dd bs=4M if=archlinux-2019.01.01-x86_64.iso of=/dev/sda status=progress oflag=sync
```
