#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DOTFILES_DIR="$HOME/.dotfiles"
REPO_URL="https://github.com/cupsadarius/dotfiles.git"

print_info() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only"
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║     Dotfiles Bootstrap Script              ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Check if dotfiles already exist
if [[ -d "$DOTFILES_DIR" ]]; then
    print_error "Dotfiles directory already exists at $DOTFILES_DIR"
    print_info "Remove it first or run install.sh directly from that directory"
    exit 1
fi

# Check for git
if ! command -v git &>/dev/null; then
    print_error "Git is not installed"
    print_info "Install Xcode Command Line Tools first:"
    print_info "  xcode-select --install"
    exit 1
fi

# Clone repository
print_info "Cloning dotfiles repository..."
if git clone --recursive "$REPO_URL" "$DOTFILES_DIR"; then
    print_success "Repository cloned successfully"
else
    print_error "Failed to clone repository"
    exit 1
fi

# Change to dotfiles directory
cd "$DOTFILES_DIR"

# Make install script executable
chmod +x install.sh

# Run installation
print_info "Starting installation..."
echo ""
./install.sh

echo ""
print_success "Bootstrap complete!"
