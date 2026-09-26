#!/bin/bash

# Colored messages
error() { echo -e "\033[0;31m❯ $*\033[0m"; }
message() { echo -e "\033[0;36m──────────\033[0m\n\033[0;32m❱ $*\033[0m"; }
warning() { echo -e "\033[0;33m❱ $*\033[0m\n\033[0;36m──────────\033[0m"; }

# Check OS
if ! command -v dnf >/dev/null; then
  error "This script requires dnf (Fedora)"
  exit 1
fi

# Check root privileges
if [[ "$EUID" -ne 0 ]]; then
  error "Root privileges required"
  exit 1
fi

# Functions
install_packages() {
  warning "Updating packages"
  dnf -y upgrade || { error "Error while updating packages"; }
  if [[ -f "$list" ]]; then
    warning "Installing packages"
    grep -v -e '#' -e '^$' "$list" | xargs dnf -y install || {
      error "Error while installing packages"
    }
    message "Package installation complete"
    echo
  fi
}

enable_flathub() {
  warning "Enabling Flathub..."
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || {
    error "Error while enabling Flathub"
  }
  message "Flathub enabled"
  echo
}

disable_tty1() {
  warning "Disabling tty1..."
  systemctl disable getty@tty1 || {
    error "Error while disabling tty1"
  }
  message "tty1 disabled"
  echo
}

disable_sudopasswd() {
  warning "Disabling password for sudo users..."
  echo "%wheel ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/010_nopasswd || {
    error "Error while configuring sudo"
  }
  chmod 440 /etc/sudoers.d/010_nopasswd || {
    error "Error while setting sudo permissions"
  }
  message "sudo password disabled"
  echo
}

configure_sshd() {
  if [[ ! -d /etc/ssh/sshd_config.d ]]; then
    error "SSH is not installed"
    return 1
  fi
  warning "Securing SSH"
  user=$(id -un 1000)
  tee "/etc/ssh/sshd_config.d/$user.conf" <<EOF
# Secure Config
X11Forwarding no
AllowUsers $user
HostKey /etc/ssh/ssh_host_ed25519_key
PasswordAuthentication yes
KbdInteractiveAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
Ciphers aes256-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-gcm@openssh.com,aes128-ctr
EOF
  systemctl restart sshd || {
    error "Error while restarting SSH"
    exit 1
  }
  message "SSH secured. Edit /etc/ssh/sshd_config.d/$user.conf to disable password login after importing your ed25519 key"
  echo
}

# Execution
dir="$(dirname "$0")/config"
cfg="$dir/config.cfg"
list="$dir/packages.cfg"
if [[ ! -f "$cfg" ]] || [[ ! -f "$list" ]]; then
  error "File $cfg or $list not found"
  exit 1
fi
echo
while read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue
  if declare -f "$line" >/dev/null; then
    "$line"
  else
    error "No function matches parameter $line"
    exit 1
  fi
done <"$cfg"
