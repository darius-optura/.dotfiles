#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Dotfiles directory
DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL_BIN_DIR="$HOME/.local/bin"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if running on macOS
check_os() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only"
        exit 1
    fi
}

# Detect Mac architecture
detect_arch() {
    if [[ $(uname -m) == "arm64" ]]; then
        print_info "Detected Apple Silicon Mac"
        HOMEBREW_PREFIX="/opt/homebrew"
    else
        print_info "Detected Intel Mac"
        HOMEBREW_PREFIX="/usr/local"
    fi
}

# Check and install Homebrew
install_homebrew() {
    if command -v brew &>/dev/null; then
        print_success "Homebrew already installed"
        return
    fi

    print_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH
    if [[ -f "${HOMEBREW_PREFIX}/bin/brew" ]]; then
        eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv)"
        print_success "Homebrew installed successfully"
    else
        print_error "Homebrew installation failed"
        exit 1
    fi
}

# Install required packages
install_packages() {
    print_info "Installing required packages..."

    local packages=(
        "fish"
        "tmux"
        "neovim"
        "bat"
        "starship"
        "fd"
        "ripgrep"
        "fzf"
        "git-delta"
        "zoxide"
        "eza"
        "go"
        "lazygit"
        "luarocks"
        "python"
    )

    local casks=(
        "ghostty"
        "orbstack"
    )

    print_info "Installing formulae..."
    for package in "${packages[@]}"; do
        if brew list "$package" &>/dev/null; then
            print_warning "$package already installed"
        else
            brew install "$package" && print_success "Installed $package"
        fi
    done

    print_info "Installing casks..."
    for cask in "${casks[@]}"; do
        if brew list --cask "$cask" &>/dev/null; then
            print_warning "$cask already installed"
        else
            brew install --cask "$cask" && print_success "Installed $cask"
        fi
    done

    # Install Nerd Font
    print_info "Installing Hack Nerd Font..."
    brew tap homebrew/cask-fonts 2>/dev/null || true
    if brew list --cask font-hack-nerd-font &>/dev/null; then
        print_warning "Hack Nerd Font already installed"
    else
        brew install --cask font-hack-nerd-font && print_success "Installed Hack Nerd Font"
    fi
}

# Backup existing configs
backup_existing() {
    print_info "Backing up existing configurations..."

    local configs=(
        "ghostty"
        "fish"
        "nvim"
        "starship"
        "tmux"
        "bat"
        "lazygit"
        "tmux-sessionizer"
        "alacritty"
        "kitty"
    )

    local backed_up=false

    for config in "${configs[@]}"; do
        if [[ -e "$CONFIG_DIR/$config" && ! -L "$CONFIG_DIR/$config" ]]; then
            mkdir -p "$BACKUP_DIR"
            mv "$CONFIG_DIR/$config" "$BACKUP_DIR/"
            print_success "Backed up $config to $BACKUP_DIR"
            backed_up=true
        fi
    done

    # Backup bin scripts
    if [[ -e "$LOCAL_BIN_DIR/tmux-sessionizer" && ! -L "$LOCAL_BIN_DIR/tmux-sessionizer" ]]; then
        mkdir -p "$BACKUP_DIR/bin"
        mv "$LOCAL_BIN_DIR/tmux-sessionizer" "$BACKUP_DIR/bin/"
        print_success "Backed up tmux-sessionizer to $BACKUP_DIR/bin"
        backed_up=true
    fi

    if [[ -e "$LOCAL_BIN_DIR/tmux-windowizer" && ! -L "$LOCAL_BIN_DIR/tmux-windowizer" ]]; then
        mkdir -p "$BACKUP_DIR/bin"
        mv "$LOCAL_BIN_DIR/tmux-windowizer" "$BACKUP_DIR/bin/"
        print_success "Backed up tmux-windowizer to $BACKUP_DIR/bin"
        backed_up=true
    fi

    if [[ "$backed_up" == false ]]; then
        print_info "No existing configurations to backup"
    fi
}

# Create necessary directories
create_directories() {
    print_info "Creating necessary directories..."
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOCAL_BIN_DIR"
    mkdir -p "$CONFIG_DIR/tmux-sessionizer"
    print_success "Directories created"
}

# Symlink configuration files
symlink_configs() {
    print_info "Creating symlinks..."

    # Config directories
    local configs=(
        "ghostty"
        "fish"
        "nvim"
        "starship"
        "tmux"
        "bat"
        "lazygit"
        "alacritty"
        "kitty"
    )

    for config in "${configs[@]}"; do
        if [[ -L "$CONFIG_DIR/$config" ]]; then
            print_warning "$config already symlinked"
        else
            ln -sf "$DOTFILES_DIR/$config" "$CONFIG_DIR/$config"
            print_success "Symlinked $config"
        fi
    done

    # Bin scripts
    if [[ -L "$LOCAL_BIN_DIR/tmux-sessionizer" ]]; then
        print_warning "tmux-sessionizer already symlinked"
    else
        ln -sf "$DOTFILES_DIR/bin/tmux-sessionizer" "$LOCAL_BIN_DIR/tmux-sessionizer"
        chmod +x "$DOTFILES_DIR/bin/tmux-sessionizer"
        print_success "Symlinked tmux-sessionizer"
    fi

    if [[ -L "$LOCAL_BIN_DIR/tmux-windowizer" ]]; then
        print_warning "tmux-windowizer already symlinked"
    else
        ln -sf "$DOTFILES_DIR/bin/tmux-windowizer" "$LOCAL_BIN_DIR/tmux-windowizer"
        chmod +x "$DOTFILES_DIR/bin/tmux-windowizer"
        print_success "Symlinked tmux-windowizer"
    fi

    # Create tmux-sessionizer config if it doesn't exist
    if [[ ! -f "$CONFIG_DIR/tmux-sessionizer/config" ]]; then
        cp "$DOTFILES_DIR/tmux-sessionizer/config.example" "$CONFIG_DIR/tmux-sessionizer/config"
        print_success "Created tmux-sessionizer config"
        print_warning "Edit $CONFIG_DIR/tmux-sessionizer/config to customize your project paths"
    fi
}

# Install Fish shell plugins
install_fish_plugins() {
    print_info "Setting up Fish shell..."

    # Set Fish as default shell
    local fish_path
    fish_path=$(command -v fish)

    if ! grep -q "$fish_path" /etc/shells; then
        print_info "Adding Fish to /etc/shells..."
        echo "$fish_path" | sudo tee -a /etc/shells
    fi

    if [[ "$SHELL" != "$fish_path" ]]; then
        print_info "Setting Fish as default shell..."
        chsh -s "$fish_path"
        print_success "Fish set as default shell (restart terminal to take effect)"
    fi

    # Install oh-my-fish
    if [[ ! -d "$HOME/.local/share/omf" ]]; then
        print_info "Installing oh-my-fish..."
        curl -fsSL https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
        print_success "oh-my-fish installed"
    else
        print_warning "oh-my-fish already installed"
    fi

    # Install fisher
    print_info "Installing fisher..."
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher" 2>/dev/null || true

    # Install fish plugins
    print_info "Installing fish plugins..."
    fish -c "fisher install jorgebucaran/nvm.fish" 2>/dev/null || true
    print_success "Fish plugins installed"
}

# Install Tmux Plugin Manager
install_tpm() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"

    if [[ -d "$tpm_dir" ]]; then
        print_warning "TPM already installed"
    else
        print_info "Installing Tmux Plugin Manager..."
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
        print_success "TPM installed"
        print_info "Press prefix + I in tmux to install plugins"
    fi
}

# Build bat cache
build_bat_cache() {
    print_info "Building bat theme cache..."
    bat cache --build &>/dev/null
    print_success "Bat cache built"
}

# Main installation
main() {
    echo ""
    echo "╔════════════════════════════════════════════╗"
    echo "║     Dotfiles Installation Script           ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""

    check_os
    detect_arch
    install_homebrew
    install_packages
    backup_existing
    create_directories
    symlink_configs
    install_fish_plugins
    install_tpm
    build_bat_cache

    echo ""
    print_success "Installation complete!"
    echo ""
    print_info "Next steps:"
    echo "  1. Restart your terminal or run: exec fish"
    echo "  2. Open tmux and press prefix + I to install plugins"
    echo "  3. Edit $CONFIG_DIR/tmux-sessionizer/config to add your project paths"
    echo "  4. Run 'make theme THEME=<name>' to switch themes (catppuccin, rose-pine, gruvbox)"
    echo ""

    if [[ -d "$BACKUP_DIR" ]]; then
        print_warning "Previous configs backed up to: $BACKUP_DIR"
    fi
}

main "$@"
