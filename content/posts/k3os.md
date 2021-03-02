+++
draft = false
date = 2021-03-02T22:55:24Z
title = "K3OS install"
slug = ""
tags = ["k3os", "kubernetes"]
categories = ["notes"]
series = ["kubernetes"]
+++
Download the [k3os](https://k3os.io) image from [GitHub](https://github.com/rancher/k3os/releases/tag/v0.11.1), flash it, [install](https://github.com/rancher/k3os#installation) it.

Runtime configuration file `/var/lib/rancher/k3os/config.yaml`:

MD5 password:

```bash
K3OS_PASSWD=$(openssl passwd -1)
```

SSH public key:

```bash
K3OS_PUBKEY=$(cat ~/.ssh/id_ed25519.pub)
```

```bash
cat <<EOF > k3os_conf.yaml
ssh_authorized_keys:
- $K3OS_PUBKEY

k3os:
  password: $K3OS_PASSWD
EOF
```

Upload config to remote host:

```bash
scp k3os_conf.yaml user@host:/tmp/k3os_conf.yaml
# rm k3os_conf.yaml
ssh user@host sudo chown root:root /tmp/k3os_conf.yaml
ssh user@host sudo chmod 600 /tmp/k3os_conf.yaml
ssh user@host sudo mkdir -p /var/lib/rancher/k3os
ssh user@host sudo mv /tmp/k3os_conf.yaml /var/lib/rancher/k3os/config.yaml
```

Run manual upgrades:

```bash
#export K3OS_VERSION=v0.11.1
ssh user@host sudo /usr/share/rancher/k3os/scripts/k3os-upgrade-rootfs
ssh user@host sudo /usr/share/rancher/k3os/scripts/k3os-upgrade-kernel
```

Reboot:

```bash
ssh user@host sudo reboot
```
