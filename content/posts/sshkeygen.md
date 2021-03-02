+++
draft = false
date = 2021-03-02T00:06:02Z
title = "OpenSSH Ed25519"
slug = ""
tags = ["OpenSSH", "linux"]
categories = ["notes"]
+++
EdDSA implementation using the [Twisted Edwards](https://en.wikipedia.org/wiki/Twisted_Edwards_curve) curve. It’s using elliptic curve cryptography that offers a better security with faster performance compared to DSA or ECDSA.


```bash
ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -C "user@domain.tld"
```

Fallback on [RSA](https://en.wikipedia.org/wiki/RSA_(cryptosystem)) 4096 bit key for outdated SSH servers:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "user@domain.tld"
```

Copy public key to remote host:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519 user@host
```

Add to SSH Agent:

```bash
eval "$(ssh-agent -s)"

ssh-add ~/.ssh/id_ed25519
ssh-add ~/.ssh/id_rsa
```

Edit OpenSSH client configuration, `~/.ssh/config`:

```
Host *
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519
  IdentityFile ~/.ssh/id_rsa
  # Forward ssh agent to the remote machine.
  ForwardAgent yes
  # Automatically add all common hosts to the host file as they are connected to.
  StrictHostKeyChecking yes
```

Run `ssh-agent` through SystemD:

```bash
mkdir -p ~/.config/systemd/user

cat <<EOF > ~/.config/systemd/user/ssh-agent.service
[Unit]
Description=SSH key agent

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
# DISPLAY required for ssh-askpass to work
Environment=DISPLAY=:0
ExecStart=/usr/bin/ssh-agent -D -a $SSH_AUTH_SOCK

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now ssh-agent.service
```

Add to the shell environment:

```bash
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
```
