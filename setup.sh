#!/usr/bin/env bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FLAKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

unset NIX_PATH
export NIX_PATH=""

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

check_connectivity() {
  print_info "Checking internet connectivity..."

  local test_urls=(
    "https://cache.nixos.org"
    "https://github.com"
    "https://nixos.org"
  )

  local connected=false
  for url in "${test_urls[@]}"; do
    if curl -Is --connect-timeout 5 "$url" >/dev/null 2>&1; then
      connected=true
      break
    fi
  done

  if [ "$connected" = false ]; then
    print_error "No internet connection detected!"
    print_warning "Please check your network connection and try again"
    return 1
  fi

  print_success "Internet connectivity confirmed"
  return 0
}

if [[ $EUID -eq 0 ]]; then
  print_error "This script should not be executed as root! Exiting..."
  exit 1
fi

if [[ ! "$(grep -i nixos </etc/os-release 2>/dev/null)" ]]; then
  print_error "This installation script only works on NixOS!"
  echo "Download an ISO at https://nixos.org/download/"
  exit 1
fi

cat <<"EOF"
╔═══════════════════════════════════════════════════════════╗
║                  NixOS Setup Automation                   ║
║                    Stellar Collision                      ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo

if ! check_connectivity; then
  exit 1
fi

currentUser=$(whoami)
print_info "Current user: $currentUser"

print_info "Updating user configuration..."

cp "${FLAKE_DIR}/flake.nix" "${FLAKE_DIR}/flake.nix.backup"

print_success "User configuration updated"

print_info "Configuring hardware..."

HARDWARE_CONFIG="${FLAKE_DIR}/system/flame/hardware-configuration.nix"

if [ -f "/etc/nixos/hardware-configuration.nix" ]; then
  print_info "Found existing hardware configuration"
  sudo cp "/etc/nixos/hardware-configuration.nix" "$HARDWARE_CONFIG"
  print_success "Hardware configuration copied"
else
  print_info "Generating new hardware configuration"
  sudo nixos-generate-config --show-hardware-config | sudo tee "$HARDWARE_CONFIG" >/dev/null
  print_success "Hardware configuration generated"
fi

print_info "Creating directory structure..."

mkdir -p ~/Pictures/Screenshots
mkdir -p ~/Documents
mkdir -p ~/Downloads
mkdir -p ~/.config

print_success "Directories created"

print_info "Ensuring Nix experimental features are enabled..."
mkdir -p ~/.config/nix
if [ ! -f ~/.config/nix/nix.conf ] || ! grep -q "experimental-features" ~/.config/nix/nix.conf; then
  cat >~/.config/nix/nix.conf <<'NIXCONF'
experimental-features = nix-command flakes
NIXCONF
  print_success "Experimental features enabled"
else
  print_info "Experimental features already configured"
fi

if [ -d "$FLAKE_DIR/.git" ]; then
  print_info "Adding changes to git..."
  cd "$FLAKE_DIR"
  git add -A

  print_info "Updating flake lock file..."
  if ! nix flake update --commit-lock-file 2>/dev/null && ! nix flake lock; then
    print_error "Failed to update flake lock. Check your internet connection."
    if [ -f "${FLAKE_DIR}/flake.nix.backup" ]; then
      mv "${FLAKE_DIR}/flake.nix.backup" "${FLAKE_DIR}/flake.nix"
    fi
    exit 1
  fi
  print_success "Flake lock updated"
  print_success "Changes added to git"
fi

echo
echo "User: $currentUser"
echo ""
echo
read -p "Proceed with installation? (y/n) [y]: " proceed
proceed=${proceed:-y}

if [[ ! $proceed =~ ^[Yy]$ ]]; then
  print_warning "Installation cancelled"
  if [ -f "${FLAKE_DIR}/flake.nix.backup" ]; then
    mv "${FLAKE_DIR}/flake.nix.backup" "${FLAKE_DIR}/flake.nix"
  fi
  exit 0
fi

echo
print_info "Building NixOS configuration..."
print_warning "This may take a while..."
echo

if sudo nixos-rebuild switch --flake "${FLAKE_DIR}#flame" --option pure-eval false; then
  echo
  print_success "═══════════════════════════════════════════════════════════"
  print_success "  Installation completed successfully!"
  print_success "═══════════════════════════════════════════════════════════"

  echo
  print_warning "Important: Please reboot your system to apply all changes"
  echo
  echo "After reboot:"
  echo "  - Your home directory will be: /home/$currentUser"
  echo "  - Config location: ${FLAKE_DIR}"
  echo ""
  echo
  read -p "Reboot now? (y/n) [n]: " reboot_now
  if [[ $reboot_now =~ ^[Yy]$ ]]; then
    print_info "Rebooting..."
    sudo reboot
  else
    print_info "Remember to reboot manually!"
  fi
else
  echo
  print_error "═══════════════════════════════════════════════════════════"
  print_error "  Installation failed!"
  print_error "═══════════════════════════════════════════════════════════"
  echo
  print_info "Your system should still be in a recoverable state"
  echo
  print_info "Restoring backup configuration..."
  if [ -f "${FLAKE_DIR}/flake.nix.backup" ]; then
    mv "${FLAKE_DIR}/flake.nix.backup" "${FLAKE_DIR}/flake.nix"
    print_success "Backup restored"
  fi
  echo
  print_info "Check the error messages above for details"
  print_info "Common issues:"
  print_info "  1. Network connectivity problems"
  print_info "  2. Missing dependencies in cache"
  print_info "  3. Syntax errors in configuration"
  echo
  print_info "You can try running the installation again"
  exit 1
fi

rm -f "${FLAKE_DIR}/flake.nix.backup"
