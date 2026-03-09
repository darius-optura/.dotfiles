#!/usr/bin/env bash

set -e

# =============================================================================
# Dotfiles Installation Script
# Supports: macOS (ARM/Intel), Linux (Debian/Ubuntu)
# Uses Homebrew on all platforms for unified package management
# =============================================================================

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
BACKUP_DIR=""

# Manifest file for tracking installations
MANIFEST_FILE="$DOTFILES_DIR/.install-manifest.json"

# OS and architecture detection
OS=""
ARCH=""
HOMEBREW_PREFIX=""

# Command line flags
DRY_RUN=false
FORCE=false
UNINSTALL=false

# Arrays for tracking (populated from manifest or during install)
declare -a INSTALLED_FORMULAE=()
declare -a INSTALLED_CASKS=()
declare -a INSTALLED_MANUAL=()
declare -a PREEXISTING_FORMULAE=()
declare -a PREEXISTING_CASKS=()
declare -a INSTALLED_SYMLINKS=()
declare -a INSTALLED_BIN_SCRIPTS=()

# =============================================================================
# Output Functions
# =============================================================================

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

# =============================================================================
# Usage and Help
# =============================================================================

show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Dotfiles installation script for macOS and Linux (Debian/Ubuntu).

OPTIONS:
    --help          Show this help message
    --uninstall     Remove installed packages and symlinks
    --dry-run       Show what would be done without making changes
    --force         Force reinstall even if already installed

EXAMPLES:
    $(basename "$0")              # Full installation
    $(basename "$0") --uninstall  # Interactive uninstall
    $(basename "$0") --dry-run    # Preview installation

EOF
    exit 0
}

# =============================================================================
# Manifest Management
# =============================================================================

init_manifest() {
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would create installation manifest"
        return
    fi

    if [[ ! -f "$MANIFEST_FILE" ]]; then
        print_info "Creating installation manifest..."
        cat > "$MANIFEST_FILE" << EOF
{
  "version": 1,
  "installed_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "updated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "platform": {
    "os": "$OS",
    "arch": "$ARCH"
  },
  "packages": {
    "formulae": [],
    "casks": [],
    "manual": []
  },
  "pre_existing": {
    "formulae": [],
    "casks": []
  },
  "symlinks": [],
  "bin_scripts": [],
  "plugins": {
    "omf": false,
    "fisher": false,
    "tpm": false
  }
}
EOF
        print_success "Manifest created at $MANIFEST_FILE"
    fi
}

load_manifest() {
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        print_warning "No manifest found at $MANIFEST_FILE"
        return 1
    fi

    print_info "Loading installation manifest..."

    # Parse JSON arrays using grep and sed (portable approach)
    # Extract formulae array
    local formulae_line
    formulae_line=$(grep -A 100 '"packages"' "$MANIFEST_FILE" | grep -A 1 '"formulae"' | tail -1 | tr -d '[]," ')
    if [[ -n "$formulae_line" ]]; then
        IFS=',' read -ra INSTALLED_FORMULAE <<< "$(grep -A 100 '"packages"' "$MANIFEST_FILE" | grep -A 1 '"formulae"' | tail -1 | tr -d '[] "' | tr ',' ' ')"
    fi

    # Extract casks array
    local casks_line
    casks_line=$(grep -A 100 '"packages"' "$MANIFEST_FILE" | grep -A 1 '"casks"' | tail -1 | tr -d '[]," ')
    if [[ -n "$casks_line" ]]; then
        IFS=',' read -ra INSTALLED_CASKS <<< "$(grep -A 100 '"packages"' "$MANIFEST_FILE" | grep -A 1 '"casks"' | tail -1 | tr -d '[] "' | tr ',' ' ')"
    fi

    # Extract manual array
    local manual_line
    manual_line=$(grep -A 100 '"packages"' "$MANIFEST_FILE" | grep -A 1 '"manual"' | tail -1 | tr -d '[]," ')
    if [[ -n "$manual_line" ]]; then
        IFS=',' read -ra INSTALLED_MANUAL <<< "$(grep -A 100 '"packages"' "$MANIFEST_FILE" | grep -A 1 '"manual"' | tail -1 | tr -d '[] "' | tr ',' ' ')"
    fi

    # Extract pre-existing formulae
    local preexisting_formulae_line
    preexisting_formulae_line=$(grep -A 100 '"pre_existing"' "$MANIFEST_FILE" | grep -A 1 '"formulae"' | tail -1 | tr -d '[]," ')
    if [[ -n "$preexisting_formulae_line" ]]; then
        IFS=',' read -ra PREEXISTING_FORMULAE <<< "$(grep -A 100 '"pre_existing"' "$MANIFEST_FILE" | grep -A 1 '"formulae"' | tail -1 | tr -d '[] "' | tr ',' ' ')"
    fi

    # Extract symlinks
    local symlinks_line
    symlinks_line=$(grep -A 1 '"symlinks"' "$MANIFEST_FILE" | tail -1 | tr -d '[]," ')
    if [[ -n "$symlinks_line" ]]; then
        IFS=',' read -ra INSTALLED_SYMLINKS <<< "$(grep -A 1 '"symlinks"' "$MANIFEST_FILE" | tail -1 | tr -d '[] "' | tr ',' ' ')"
    fi

    # Extract bin_scripts
    local bin_scripts_line
    bin_scripts_line=$(grep -A 1 '"bin_scripts"' "$MANIFEST_FILE" | tail -1 | tr -d '[]," ')
    if [[ -n "$bin_scripts_line" ]]; then
        IFS=',' read -ra INSTALLED_BIN_SCRIPTS <<< "$(grep -A 1 '"bin_scripts"' "$MANIFEST_FILE" | tail -1 | tr -d '[] "' | tr ',' ' ')"
    fi

    print_success "Manifest loaded"
    return 0
}

save_manifest() {
    print_info "Saving installation manifest..."

    # Convert arrays to JSON format
    local formulae_json
    formulae_json=$(printf '%s\n' "${INSTALLED_FORMULAE[@]}" | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')
    [[ -z "$formulae_json" ]] && formulae_json=""

    local casks_json
    casks_json=$(printf '%s\n' "${INSTALLED_CASKS[@]}" | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')
    [[ -z "$casks_json" ]] && casks_json=""

    local manual_json
    manual_json=$(printf '%s\n' "${INSTALLED_MANUAL[@]}" | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')
    [[ -z "$manual_json" ]] && manual_json=""

    local preexisting_formulae_json
    preexisting_formulae_json=$(printf '%s\n' "${PREEXISTING_FORMULAE[@]}" | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')
    [[ -z "$preexisting_formulae_json" ]] && preexisting_formulae_json=""

    local preexisting_casks_json
    preexisting_casks_json=$(printf '%s\n' "${PREEXISTING_CASKS[@]}" | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')
    [[ -z "$preexisting_casks_json" ]] && preexisting_casks_json=""

    local symlinks_json
    symlinks_json=$(printf '%s\n' "${INSTALLED_SYMLINKS[@]}" | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')
    [[ -z "$symlinks_json" ]] && symlinks_json=""

    local bin_scripts_json
    bin_scripts_json=$(printf '%s\n' "${INSTALLED_BIN_SCRIPTS[@]}" | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')
    [[ -z "$bin_scripts_json" ]] && bin_scripts_json=""

    # Check plugin status
    local omf_installed=false
    local fisher_installed=false
    local tpm_installed=false
    [[ -d "$HOME/.local/share/omf" ]] && omf_installed=true
    fish -c "type -q fisher" 2>/dev/null && fisher_installed=true
    [[ -d "$HOME/.tmux/plugins/tpm" ]] && tpm_installed=true

    cat > "$MANIFEST_FILE" << EOF
{
  "version": 1,
  "installed_at": "$(grep '"installed_at"' "$MANIFEST_FILE" 2>/dev/null | cut -d'"' -f4 || date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "updated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "platform": {
    "os": "$OS",
    "arch": "$ARCH"
  },
  "packages": {
    "formulae": [$formulae_json],
    "casks": [$casks_json],
    "manual": [$manual_json]
  },
  "pre_existing": {
    "formulae": [$preexisting_formulae_json],
    "casks": [$preexisting_casks_json]
  },
  "symlinks": [$symlinks_json],
  "bin_scripts": [$bin_scripts_json],
  "plugins": {
    "omf": $omf_installed,
    "fisher": $fisher_installed,
    "tpm": $tpm_installed
  }
}
EOF
    print_success "Manifest saved"
}

record_package() {
    local type="$1"
    local package="$2"

    case "$type" in
        formulae)
            INSTALLED_FORMULAE+=("$package")
            ;;
        casks)
            INSTALLED_CASKS+=("$package")
            ;;
        manual)
            INSTALLED_MANUAL+=("$package")
            ;;
    esac
}

record_preexisting() {
    local type="$1"
    local package="$2"

    case "$type" in
        formulae)
            PREEXISTING_FORMULAE+=("$package")
            ;;
        casks)
            PREEXISTING_CASKS+=("$package")
            ;;
    esac
}

record_symlink() {
    local name="$1"
    INSTALLED_SYMLINKS+=("$name")
}

record_bin_script() {
    local name="$1"
    INSTALLED_BIN_SCRIPTS+=("$name")
}

# =============================================================================
# Platform Detection
# =============================================================================

detect_platform() {
    ARCH=$(uname -m)

    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        if [[ "$ARCH" == "arm64" ]]; then
            print_info "Detected macOS (Apple Silicon)"
            HOMEBREW_PREFIX="/opt/homebrew"
        else
            print_info "Detected macOS (Intel)"
            HOMEBREW_PREFIX="/usr/local"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
        if [[ -f /etc/debian_version ]]; then
            print_info "Detected Debian/Ubuntu Linux ($ARCH)"
        else
            print_warning "Non-Debian Linux detected. Installation may require adjustments."
        fi
    else
        print_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
}

# =============================================================================
# Homebrew Installation
# =============================================================================

install_homebrew() {
    if command -v brew &>/dev/null; then
        print_success "Homebrew already installed"
        # Ensure brew is in PATH
        eval "$("$(command -v brew)" shellenv)"
        return
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would install Homebrew"
        return
    fi

    print_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH based on platform
    if [[ "$OS" == "macos" ]]; then
        if [[ -f "${HOMEBREW_PREFIX}/bin/brew" ]]; then
            eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv)"
        fi
    elif [[ "$OS" == "linux" ]]; then
        if [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [[ -f "$HOME/.linuxbrew/bin/brew" ]]; then
            eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
            HOMEBREW_PREFIX="$HOME/.linuxbrew"
        fi
    fi

    if command -v brew &>/dev/null; then
        print_success "Homebrew installed successfully"
    else
        print_error "Homebrew installation failed"
        exit 1
    fi
}

# =============================================================================
# Linux Prerequisites (minimal apt packages for Homebrew)
# =============================================================================

install_linux_prerequisites() {
    if [[ "$OS" != "linux" ]]; then
        return
    fi

    print_info "Installing Linux prerequisites for Homebrew..."

    local prereqs=("build-essential" "curl" "git" "procps" "file")

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would install apt packages: ${prereqs[*]}"
        return
    fi

    sudo apt-get update
    for pkg in "${prereqs[@]}"; do
        if dpkg -l "$pkg" &>/dev/null 2>&1; then
            print_warning "$pkg already installed (system)"
        else
            sudo apt-get install -y "$pkg" && print_success "Installed $pkg (apt)"
        fi
    done
}

# =============================================================================
# Package Installation (Unified Homebrew)
# =============================================================================

install_packages() {
    print_info "Installing packages via Homebrew..."

    # Core packages (all platforms)
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

    # macOS-only: add opencode from tap
    if [[ "$OS" == "macos" ]]; then
        packages+=("anomalyco/tap/opencode")
    fi

    for package in "${packages[@]}"; do
        local pkg_name
        pkg_name=$(basename "$package")  # Handle tap/package format

        if [[ "$DRY_RUN" == true ]]; then
            if brew list "$pkg_name" &>/dev/null 2>&1; then
                print_info "[DRY-RUN] $pkg_name already installed (would mark pre-existing)"
            else
                print_info "[DRY-RUN] Would install $pkg_name"
            fi
            continue
        fi

        if brew list "$pkg_name" &>/dev/null 2>&1; then
            if [[ "$FORCE" == true ]]; then
                brew reinstall "$package" && print_success "Reinstalled $pkg_name"
                record_package "formulae" "$pkg_name"
            else
                print_warning "$pkg_name already installed"
                record_preexisting "formulae" "$pkg_name"
            fi
        else
            brew install "$package" && print_success "Installed $pkg_name"
            record_package "formulae" "$pkg_name"
        fi
    done

    # macOS-only: Casks (GUI applications)
    if [[ "$OS" == "macos" ]]; then
        print_info "Installing macOS applications (casks)..."

        local casks=(
            "ghostty"
            "orbstack"
        )

        for cask in "${casks[@]}"; do
            if [[ "$DRY_RUN" == true ]]; then
                if brew list --cask "$cask" &>/dev/null 2>&1; then
                    print_info "[DRY-RUN] $cask already installed (would mark pre-existing)"
                else
                    print_info "[DRY-RUN] Would install cask $cask"
                fi
                continue
            fi

            if brew list --cask "$cask" &>/dev/null 2>&1; then
                if [[ "$FORCE" == true ]]; then
                    brew reinstall --cask "$cask" && print_success "Reinstalled $cask"
                    record_package "casks" "$cask"
                else
                    print_warning "$cask already installed"
                    record_preexisting "casks" "$cask"
                fi
            else
                brew install --cask "$cask" && print_success "Installed $cask"
                record_package "casks" "$cask"
            fi
        done

        # Install Nerd Font via cask
        install_nerd_font_macos
    fi

    # Linux-only: Install opencode from GitHub releases
    if [[ "$OS" == "linux" ]]; then
        install_opencode_linux
        install_nerd_font_linux

        # Note about Ghostty
        print_warning "Ghostty is not available via Homebrew on Linux."
        print_info "To install Ghostty on Linux, build from source: https://ghostty.org/docs/install/build"
    fi
}

# =============================================================================
# Nerd Font Installation
# =============================================================================

install_nerd_font_macos() {
    print_info "Installing Hack Nerd Font..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would install font-hack-nerd-font"
        return
    fi

    if brew list --cask font-hack-nerd-font &>/dev/null 2>&1; then
        print_warning "Hack Nerd Font already installed"
        record_preexisting "casks" "font-hack-nerd-font"
    else
        brew install --cask font-hack-nerd-font && print_success "Installed Hack Nerd Font"
        record_package "casks" "font-hack-nerd-font"
    fi
}

install_nerd_font_linux() {
    print_info "Installing Hack Nerd Font..."

    local font_dir="$HOME/.local/share/fonts"
    mkdir -p "$font_dir"

    if [[ -f "$font_dir/HackNerdFont-Regular.ttf" ]]; then
        print_warning "Hack Nerd Font already installed"
        return
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would download Hack Nerd Font to $font_dir"
        return
    fi

    print_info "Downloading Hack Nerd Font..."
    curl -fLo "$font_dir/Hack.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip
    unzip -o "$font_dir/Hack.zip" -d "$font_dir"
    rm "$font_dir/Hack.zip"
    fc-cache -fv &>/dev/null || true
    print_success "Installed Hack Nerd Font"
    record_package "manual" "hack-nerd-font"
}

# =============================================================================
# OpenCode Installation (Linux - from GitHub releases)
# =============================================================================

install_opencode_linux() {
    if [[ "$OS" != "linux" ]]; then
        return
    fi

    print_info "Installing OpenCode from GitHub releases..."

    if command -v opencode &>/dev/null; then
        if [[ "$FORCE" == true ]]; then
            print_info "Reinstalling OpenCode..."
        else
            print_warning "OpenCode already installed"
            record_preexisting "formulae" "opencode"
            return
        fi
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would download and install OpenCode"
        return
    fi

    # Determine architecture
    local oc_arch=""
    case "$ARCH" in
        x86_64|amd64)
            oc_arch="x64"
            ;;
        aarch64|arm64)
            oc_arch="arm64"
            ;;
        *)
            print_error "Unsupported architecture for OpenCode: $ARCH"
            return
            ;;
    esac

    # Get latest version
    local version
    version=$(curl -sL "https://api.github.com/repos/anomalyco/opencode/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -z "$version" ]]; then
        print_error "Failed to fetch OpenCode version"
        return
    fi

    print_info "Downloading OpenCode $version for linux-$oc_arch..."

    local download_url="https://github.com/anomalyco/opencode/releases/download/${version}/opencode-linux-${oc_arch}.tar.gz"
    local tmp_dir
    tmp_dir=$(mktemp -d)

    curl -fLo "$tmp_dir/opencode.tar.gz" "$download_url"
    tar -xzf "$tmp_dir/opencode.tar.gz" -C "$tmp_dir"

    # Install to ~/.local/bin
    mkdir -p "$LOCAL_BIN_DIR"
    mv "$tmp_dir/opencode" "$LOCAL_BIN_DIR/opencode"
    chmod +x "$LOCAL_BIN_DIR/opencode"

    rm -rf "$tmp_dir"

    print_success "Installed OpenCode $version"
    record_package "manual" "opencode"
}

# =============================================================================
# Backup Existing Configs
# =============================================================================

backup_existing() {
    print_info "Checking for existing configurations to backup..."

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
        "opencode"
    )

    local backed_up=false

    for config in "${configs[@]}"; do
        if [[ -e "$CONFIG_DIR/$config" && ! -L "$CONFIG_DIR/$config" ]]; then
            if [[ -z "$BACKUP_DIR" ]]; then
                BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
            fi

            if [[ "$DRY_RUN" == true ]]; then
                print_info "[DRY-RUN] Would backup $config to $BACKUP_DIR"
            else
                mkdir -p "$BACKUP_DIR"
                mv "$CONFIG_DIR/$config" "$BACKUP_DIR/"
                print_success "Backed up $config to $BACKUP_DIR"
            fi
            backed_up=true
        fi
    done

    # Backup bin scripts
    for script in "tmux-sessionizer" "tmux-windowizer"; do
        if [[ -e "$LOCAL_BIN_DIR/$script" && ! -L "$LOCAL_BIN_DIR/$script" ]]; then
            if [[ -z "$BACKUP_DIR" ]]; then
                BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
            fi

            if [[ "$DRY_RUN" == true ]]; then
                print_info "[DRY-RUN] Would backup $script to $BACKUP_DIR/bin"
            else
                mkdir -p "$BACKUP_DIR/bin"
                mv "$LOCAL_BIN_DIR/$script" "$BACKUP_DIR/bin/"
                print_success "Backed up $script to $BACKUP_DIR/bin"
            fi
            backed_up=true
        fi
    done

    if [[ "$backed_up" == false ]]; then
        print_info "No existing configurations to backup"
    fi
}

# =============================================================================
# Create Directories
# =============================================================================

create_directories() {
    print_info "Creating necessary directories..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would create directories"
        return
    fi

    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOCAL_BIN_DIR"
    mkdir -p "$CONFIG_DIR/tmux-sessionizer"
    print_success "Directories created"
}

# =============================================================================
# Symlink Configurations
# =============================================================================

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
        "opencode"
    )

    for config in "${configs[@]}"; do
        # Skip ghostty symlink on Linux (not available)
        if [[ "$OS" == "linux" && "$config" == "ghostty" ]]; then
            continue
        fi

        if [[ "$DRY_RUN" == true ]]; then
            if [[ -L "$CONFIG_DIR/$config" ]]; then
                print_info "[DRY-RUN] $config already symlinked"
            else
                print_info "[DRY-RUN] Would symlink $config"
            fi
            continue
        fi

        if [[ -L "$CONFIG_DIR/$config" ]]; then
            print_warning "$config already symlinked"
        else
            ln -sf "$DOTFILES_DIR/$config" "$CONFIG_DIR/$config"
            print_success "Symlinked $config"
        fi
        record_symlink "$config"
    done

    # Bin scripts
    local bin_scripts=("tmux-sessionizer" "tmux-windowizer")

    for script in "${bin_scripts[@]}"; do
        if [[ "$DRY_RUN" == true ]]; then
            if [[ -L "$LOCAL_BIN_DIR/$script" ]]; then
                print_info "[DRY-RUN] $script already symlinked"
            else
                print_info "[DRY-RUN] Would symlink $script"
            fi
            continue
        fi

        if [[ -L "$LOCAL_BIN_DIR/$script" ]]; then
            print_warning "$script already symlinked"
        else
            ln -sf "$DOTFILES_DIR/bin/$script" "$LOCAL_BIN_DIR/$script"
            chmod +x "$DOTFILES_DIR/bin/$script"
            print_success "Symlinked $script"
        fi
        record_bin_script "$script"
    done

    # Create tmux-sessionizer config if it doesn't exist
    if [[ ! -f "$CONFIG_DIR/tmux-sessionizer/config" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would create tmux-sessionizer config"
        else
            if [[ -f "$DOTFILES_DIR/tmux-sessionizer/config.example" ]]; then
                cp "$DOTFILES_DIR/tmux-sessionizer/config.example" "$CONFIG_DIR/tmux-sessionizer/config"
                print_success "Created tmux-sessionizer config"
                print_warning "Edit $CONFIG_DIR/tmux-sessionizer/config to customize your project paths"
            fi
        fi
    fi
}

# =============================================================================
# Fish Shell Setup
# =============================================================================

install_fish_plugins() {
    print_info "Setting up Fish shell..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would set up Fish shell and plugins"
        return
    fi

    # Set Fish as default shell
    local fish_path
    fish_path=$(command -v fish)

    if ! grep -q "$fish_path" /etc/shells 2>/dev/null; then
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
        curl -fsSL https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish --init-command "set -g OMF_INSTALL_NONINTERACTIVE 1"
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

    # Add Homebrew to fish config on Linux
    if [[ "$OS" == "linux" ]]; then
        local fish_config="$CONFIG_DIR/fish/conf.d/homebrew.fish"
        if [[ ! -f "$fish_config" ]]; then
            mkdir -p "$CONFIG_DIR/fish/conf.d"
            cat > "$fish_config" << 'EOF'
# Homebrew (Linuxbrew) configuration
if test -d /home/linuxbrew/.linuxbrew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
else if test -d $HOME/.linuxbrew
    eval ($HOME/.linuxbrew/bin/brew shellenv)
end
EOF
            print_success "Added Homebrew to Fish config"
        fi
    fi
}

# =============================================================================
# Node.js Installation
# =============================================================================

install_node() {
    print_info "Installing Node.js..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would install Node.js via nvm"
        return
    fi

    # Check if nvm.fish is available
    if ! fish -c "type -q nvm" 2>/dev/null; then
        print_warning "nvm.fish not available yet, Node.js installation will be skipped"
        print_info "After restarting your shell, run: nvm install lts"
        return
    fi

    # Install latest LTS version of Node
    print_info "Installing Node.js LTS version..."
    fish -c "nvm install lts" 2>/dev/null || {
        print_warning "Could not install Node.js automatically"
        print_info "After restarting your shell, run: nvm install lts"
        return
    }

    # Set LTS as default
    fish -c "nvm use lts" 2>/dev/null || true

    print_success "Node.js LTS installed"
}

# =============================================================================
# Tmux Plugin Manager
# =============================================================================

install_tpm() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"

    if [[ "$DRY_RUN" == true ]]; then
        if [[ -d "$tpm_dir" ]]; then
            print_info "[DRY-RUN] TPM already installed"
        else
            print_info "[DRY-RUN] Would install TPM"
        fi
        return
    fi

    if [[ -d "$tpm_dir" ]]; then
        print_warning "TPM already installed"
    else
        print_info "Installing Tmux Plugin Manager..."
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
        print_success "TPM installed"
        print_info "Press prefix + I in tmux to install plugins"
    fi
}

# =============================================================================
# Bat Cache
# =============================================================================

build_bat_cache() {
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would build bat theme cache"
        return
    fi

    print_info "Building bat theme cache..."
    bat cache --build &>/dev/null || true
    print_success "Bat cache built"
}

# =============================================================================
# Uninstall Functions
# =============================================================================

prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response

    if [[ "$default" == "y" ]]; then
        read -rp "$prompt [Y/n] " response
        response=${response:-y}
    else
        read -rp "$prompt [y/N] " response
        response=${response:-n}
    fi

    [[ "$response" =~ ^[Yy]$ ]]
}

uninstall_symlinks() {
    print_info "Removing symlinks..."

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
        "opencode"
    )

    for config in "${configs[@]}"; do
        if [[ -L "$CONFIG_DIR/$config" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                print_info "[DRY-RUN] Would remove $config symlink"
            else
                rm "$CONFIG_DIR/$config"
                print_success "Removed $config symlink"
            fi
        fi
    done

    # Bin scripts
    for script in "tmux-sessionizer" "tmux-windowizer"; do
        if [[ -L "$LOCAL_BIN_DIR/$script" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                print_info "[DRY-RUN] Would remove $script symlink"
            else
                rm "$LOCAL_BIN_DIR/$script"
                print_success "Removed $script symlink"
            fi
        fi
    done
}

uninstall_packages() {
    if [[ ${#INSTALLED_FORMULAE[@]} -eq 0 && ${#INSTALLED_CASKS[@]} -eq 0 && ${#INSTALLED_MANUAL[@]} -eq 0 ]]; then
        print_info "No packages were installed by this script"
        return
    fi

    # Uninstall formulae
    if [[ ${#INSTALLED_FORMULAE[@]} -gt 0 ]]; then
        echo ""
        print_info "The following packages were installed by this script:"
        echo "   ${INSTALLED_FORMULAE[*]}"
        echo ""

        for pkg in "${INSTALLED_FORMULAE[@]}"; do
            if [[ -z "$pkg" ]]; then
                continue
            fi

            if [[ "$DRY_RUN" == true ]]; then
                print_info "[DRY-RUN] Would prompt to remove $pkg"
                continue
            fi

            if prompt_yes_no "Remove $pkg?"; then
                brew uninstall "$pkg" 2>/dev/null && print_success "Uninstalled $pkg" || print_warning "Failed to uninstall $pkg"
            else
                print_info "Keeping $pkg"
            fi
        done
    fi

    # Uninstall casks (macOS only)
    if [[ ${#INSTALLED_CASKS[@]} -gt 0 ]]; then
        echo ""
        print_info "The following casks were installed by this script:"
        echo "   ${INSTALLED_CASKS[*]}"
        echo ""

        for cask in "${INSTALLED_CASKS[@]}"; do
            if [[ -z "$cask" ]]; then
                continue
            fi

            if [[ "$DRY_RUN" == true ]]; then
                print_info "[DRY-RUN] Would prompt to remove cask $cask"
                continue
            fi

            if prompt_yes_no "Remove $cask?"; then
                brew uninstall --cask "$cask" 2>/dev/null && print_success "Uninstalled $cask" || print_warning "Failed to uninstall $cask"
            else
                print_info "Keeping $cask"
            fi
        done
    fi

    # Uninstall manual packages
    if [[ ${#INSTALLED_MANUAL[@]} -gt 0 ]]; then
        echo ""
        print_info "The following packages were manually installed:"
        echo "   ${INSTALLED_MANUAL[*]}"
        echo ""

        for pkg in "${INSTALLED_MANUAL[@]}"; do
            if [[ -z "$pkg" ]]; then
                continue
            fi

            if [[ "$DRY_RUN" == true ]]; then
                print_info "[DRY-RUN] Would prompt to remove $pkg"
                continue
            fi

            case "$pkg" in
                opencode)
                    if prompt_yes_no "Remove opencode from $LOCAL_BIN_DIR?"; then
                        rm -f "$LOCAL_BIN_DIR/opencode"
                        print_success "Removed opencode"
                    else
                        print_info "Keeping opencode"
                    fi
                    ;;
                hack-nerd-font)
                    if prompt_yes_no "Remove Hack Nerd Font?"; then
                        rm -f "$HOME/.local/share/fonts/Hack"*.ttf
                        fc-cache -fv &>/dev/null || true
                        print_success "Removed Hack Nerd Font"
                    else
                        print_info "Keeping Hack Nerd Font"
                    fi
                    ;;
            esac
        done
    fi

    # Show pre-existing packages
    if [[ ${#PREEXISTING_FORMULAE[@]} -gt 0 ]]; then
        echo ""
        print_info "The following packages were pre-existing (not touching):"
        echo "   ${PREEXISTING_FORMULAE[*]}"
    fi
}

uninstall_all() {
    echo ""
    echo "╔════════════════════════════════════════════╗"
    echo "║     Dotfiles Uninstall                     ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""

    # Load manifest
    if ! load_manifest; then
        print_error "No installation manifest found. Cannot determine what was installed."
        print_info "You can manually remove symlinks with: make uninstall (from Makefile)"
        exit 1
    fi

    # Remove symlinks first
    uninstall_symlinks

    # Uninstall packages (with prompts)
    uninstall_packages

    # Remove manifest
    if [[ "$DRY_RUN" != true ]]; then
        if prompt_yes_no "Remove installation manifest?"; then
            rm -f "$MANIFEST_FILE"
            print_success "Removed manifest"
        fi
    fi

    echo ""
    print_success "Uninstall complete!"
    echo ""
    print_info "To restore your previous configs, run: make restore"
}

# =============================================================================
# Main Installation
# =============================================================================

main() {
    echo ""
    echo "╔════════════════════════════════════════════╗"
    echo "║     Dotfiles Installation Script           ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        print_warning "Running in DRY-RUN mode - no changes will be made"
        echo ""
    fi

    detect_platform
    init_manifest

    # Linux: Install prerequisites via apt first
    install_linux_prerequisites

    # Install Homebrew (all platforms)
    install_homebrew

    # Install packages
    install_packages

    # Config management
    backup_existing
    create_directories
    symlink_configs

    # Shell and plugins
    install_fish_plugins
    install_node
    install_tpm
    build_bat_cache

    # Save manifest
    if [[ "$DRY_RUN" != true ]]; then
        save_manifest
    fi

    echo ""
    print_success "Installation complete!"
    echo ""
    print_info "Next steps:"
    echo "  1. Restart your terminal or run: exec fish"
    echo "  2. If Node.js wasn't installed automatically, run: nvm install lts"
    echo "  3. Open tmux and press prefix + I to install plugins"
    echo "  4. Edit $CONFIG_DIR/tmux-sessionizer/config to add your project paths"
    echo "  5. Run 'make theme THEME=<name>' to switch themes (catppuccin, rose-pine, gruvbox)"
    echo ""

    if [[ -n "$BACKUP_DIR" && -d "$BACKUP_DIR" ]]; then
        print_warning "Previous configs backed up to: $BACKUP_DIR"
    fi
}

# =============================================================================
# Entry Point
# =============================================================================

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_usage
            ;;
        --uninstall)
            UNINSTALL=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            ;;
    esac
done

# Detect platform first (needed for both install and uninstall)
detect_platform

# Dispatch
if [[ "$UNINSTALL" == true ]]; then
    uninstall_all
else
    main
fi
