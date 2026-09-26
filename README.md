# dnfinit

A script that automates installing and configuring Fedora.

## Features

- `install_packages`: updates the system and installs the applications listed in `config/packages.cfg`

- `enable_flathub`: adds the Flathub repository (flatpak comes preinstalled on Fedora Workstation)

- `disable_tty1`: disables tty1, for SSH-only use

- `disable_sudopasswd`: disables the password prompt for sudo commands. **DO NOT USE IN PRODUCTION!**


- `configure_sshd`: creates an `sshd` file (`/etc/ssh/sshd_config.d/<user>.conf`) with the following:
  - Restricts access to the main user (UID 1000)
  - Disables X11 forwarding
  - Enforces `ed25519` keys only
  - Limits authentication attempts to 3
  - Restricts algorithms to modern recommendations:
    - **Kex**: `curve25519-sha256`
    - **Ciphers**: `aes256-gcm`, `aes256-ctr`, `aes192-ctr`, `aes128-gcm`, `aes128-ctr`
    - **MACs**: `hmac-sha2-512-etm`, `hmac-sha2-256-etm`

> **Warning**: `PasswordAuthentication` stays enabled by default. Remember to disable it in `/etc/ssh/sshd_config.d/<user>.conf` after setting up your SSH keys.

## Configuration

The `config/config.cfg` file lets you configure how the script runs to suit your preferences.
Comment out the functions you don't want to use. Example:

```txt
# dnfinit config

install_packages
enable_flathub

# disable_tty1
# disable_sudopasswd
# configure_sshd
```

Alongside the config file is `config/packages.cfg`, which lists the packages to install when `install_packages` is enabled.

Example:

```txt
# dnfinit packages list

colordiff
curl
duf
du-dust
fd-find
jetbrains-mono-nl-fonts
fzf
gnome-extensions-app
gnome-shell-extension-appindicator
gnome-shell-extension-dash-to-dock
gnome-tweaks
htop
ncdu
papirus-icon-theme
procs
ripgrep
rsync
tree
unzip
vim
zip
zoxide
```

## Usage

Once you've edited `config/config.cfg`, run the script with root privileges:

```bash
sudo ./dnfinit.sh
```
