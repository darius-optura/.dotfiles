#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

THEME="${1:-catppuccin}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

print_info() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Normalize theme name
normalize_theme() {
    case "$1" in
        catppuccin|cat|mocha)
            echo "catppuccin"
            ;;
        rose-pine|rose|rosepine|rose_pine)
            echo "rose-pine"
            ;;
        gruvbox|gruvbox-dark|gruvbox_dark)
            echo "gruvbox"
            ;;
        *)
            print_error "Unknown theme: $1"
            echo "Available themes: catppuccin, rose-pine, gruvbox"
            exit 1
            ;;
    esac
}

# Update Fish theme
update_fish_theme() {
    local theme_file
    case "$THEME" in
        catppuccin)
            theme_file="Catppuccin Mocha"
            ;;
        rose-pine)
            theme_file="Rose Pine Moon"
            ;;
        gruvbox)
            theme_file="Gruvbox Dark"
            ;;
    esac

    if [[ -f "$CONFIG_DIR/fish/themes/$theme_file.theme" ]]; then
        fish -c "fish_config theme save '$theme_file'" 2>/dev/null || true
        print_success "Fish theme updated to $theme_file"
    else
        print_error "Fish theme file not found: $theme_file.theme"
    fi
}

# Update Ghostty theme
update_ghostty_theme() {
    local theme_conf
    case "$THEME" in
        catppuccin)
            theme_conf="Catppuccin Mocha"
            ;;
        rose-pine)
            theme_conf="Rose Pine Moon"
            ;;
        gruvbox)
            theme_conf="Gruvbox Dark Hard"
            ;;
    esac

    if [[ -f "$CONFIG_DIR/ghostty/config" ]]; then
        sed -i.bak "s/^theme = .*/theme = $theme_conf/" "$CONFIG_DIR/ghostty/config"
        rm -f "$CONFIG_DIR/ghostty/config.bak"
        print_success "Ghostty theme updated to $theme_conf"
    fi
}

# Update Alacritty theme (fallback terminal)
update_alacritty_theme() {
    local theme_file
    case "$THEME" in
        catppuccin)
            theme_file="catppuccin-mocha.toml"
            ;;
        rose-pine)
            theme_file="rose-pine-moon.toml"
            ;;
        gruvbox)
            # Use catppuccin as fallback if gruvbox not available
            theme_file="catppuccin-mocha.toml"
            print_info "Gruvbox not available for Alacritty, using Catppuccin Mocha"
            ;;
    esac

    if [[ -f "$CONFIG_DIR/alacritty/alacritty.toml" ]]; then
        # Update import line in alacritty.toml
        sed -i.bak "s|^import = \[.*\]|import = [\"~/.config/alacritty/$theme_file\"]|" "$CONFIG_DIR/alacritty/alacritty.toml"
        rm -f "$CONFIG_DIR/alacritty/alacritty.toml.bak"
        print_success "Alacritty theme updated to $theme_file"
    fi
}

# Update Kitty theme (fallback terminal)
update_kitty_theme() {
    local theme_file
    case "$THEME" in
        catppuccin)
            # Kitty would need catppuccin theme
            print_info "Kitty theme switching not configured (only has rose-pine-moon)"
            ;;
        rose-pine)
            theme_file="rose-pine-moon.conf"
            if [[ -f "$CONFIG_DIR/kitty/kitty.conf" ]]; then
                sed -i.bak "s|^include .*|include ~/.config/kitty/themes/$theme_file|" "$CONFIG_DIR/kitty/kitty.conf"
                rm -f "$CONFIG_DIR/kitty/kitty.conf.bak"
                print_success "Kitty theme updated to $theme_file"
            fi
            ;;
        gruvbox)
            print_info "Kitty theme switching not configured (only has rose-pine-moon)"
            ;;
    esac
}

# Update Tmux theme
update_tmux_theme() {
    local flavor
    case "$THEME" in
        catppuccin)
            flavor="mocha"
            ;;
        rose-pine)
            # Tmux uses catppuccin plugin, stick with mocha or add rose-pine plugin
            flavor="mocha"
            print_info "Rose Pine not configured for Tmux, keeping Catppuccin Mocha"
            ;;
        gruvbox)
            # Could switch to gruvbox tmux theme
            flavor="mocha"
            print_info "Gruvbox not configured for Tmux, keeping Catppuccin Mocha"
            ;;
    esac

    if [[ -f "$CONFIG_DIR/tmux/tmux.conf" ]]; then
        sed -i.bak "s/^set -g @catppuccin_flavor \".*\"/set -g @catppuccin_flavor \"$flavor\"/" "$CONFIG_DIR/tmux/tmux.conf"
        rm -f "$CONFIG_DIR/tmux/tmux.conf.bak"
        print_success "Tmux theme updated to Catppuccin $flavor"
        print_info "Reload tmux config with: tmux source ~/.config/tmux/tmux.conf"
    fi
}

# Update Bat theme
update_bat_theme() {
    local bat_theme
    case "$THEME" in
        catppuccin)
            bat_theme="Catppuccin Mocha"
            ;;
        rose-pine)
            bat_theme="Catppuccin Mocha"
            print_info "Rose Pine not available for bat, using Catppuccin Mocha"
            ;;
        gruvbox)
            bat_theme="gruvbox-dark"
            ;;
    esac

    if [[ -f "$CONFIG_DIR/fish/config.fish" ]]; then
        sed -i.bak "s/^export BAT_THEME=\".*\"/export BAT_THEME=\"$bat_theme\"/" "$CONFIG_DIR/fish/config.fish"
        rm -f "$CONFIG_DIR/fish/config.fish.bak"
        print_success "Bat theme updated to $bat_theme"
    fi
}

# Update Starship palette
update_starship_theme() {
    local palette
    case "$THEME" in
        catppuccin)
            palette="catppuccin_mocha"
            ;;
        rose-pine)
            palette="catppuccin_mocha"
            print_info "Rose Pine palette not configured for Starship, using Catppuccin Mocha"
            ;;
        gruvbox)
            palette="gruvbox_dark"
            ;;
    esac

    if [[ -f "$CONFIG_DIR/starship/starship.toml" ]]; then
        sed -i.bak "s/^palette = \".*\"/palette = \"$palette\"/" "$CONFIG_DIR/starship/starship.toml"
        rm -f "$CONFIG_DIR/starship/starship.toml.bak"
        print_success "Starship palette updated to $palette"
    fi
}

# Update Neovim colorscheme
update_neovim_theme() {
    local colorscheme
    local colorscheme_file="$CONFIG_DIR/nvim/lua/plugins/colorscheme.lua"
    local lazy_file="$CONFIG_DIR/nvim/lua/config/lazy.lua"

    case "$THEME" in
        catppuccin)
            colorscheme="catppuccin"
            ;;
        rose-pine)
            colorscheme="rose-pine"
            ;;
        gruvbox)
            colorscheme="gruvbox"
            ;;
    esac

    if [[ ! -f "$colorscheme_file" ]]; then
        print_error "Neovim colorscheme file not found"
        return
    fi

    print_info "Updating Neovim colorscheme to $colorscheme..."

    # First, comment out all vim.cmd("colorscheme ...") lines
    sed -i.bak 's/^[[:space:]]*vim\.cmd("colorscheme/      -- vim.cmd("colorscheme/g' "$colorscheme_file"

    # Then uncomment the line for the selected theme
    case "$THEME" in
        catppuccin)
            sed -i.bak 's/^[[:space:]]*-- vim\.cmd("colorscheme catppuccin")/      vim.cmd("colorscheme catppuccin")/g' "$colorscheme_file"
            ;;
        rose-pine)
            sed -i.bak 's/^[[:space:]]*-- vim\.cmd("colorscheme rose-pine")/      vim.cmd("colorscheme rose-pine")/g' "$colorscheme_file"
            ;;
        gruvbox)
            sed -i.bak 's/^[[:space:]]*-- vim\.cmd("colorscheme gruvbox")/      vim.cmd("colorscheme gruvbox")/g' "$colorscheme_file"
            ;;
    esac

    # Clean up backup file
    rm -f "$colorscheme_file.bak"

    # Update lazy.lua install colorscheme
    if [[ -f "$lazy_file" ]]; then
        sed -i.bak "s/install = { colorscheme = { \".*\" } }/install = { colorscheme = { \"$colorscheme\" } }/g" "$lazy_file"
        rm -f "$lazy_file.bak"
    fi

    print_success "Neovim colorscheme updated to $colorscheme"
    print_info "Restart Neovim to see changes"
}

# Update FZF theme
update_fzf_theme() {
    # Call the Fish function to update FZF colors
    print_info "Updating FZF theme..."

    # Update FZF theme using Fish function
    fish -c "set_fzf_theme $THEME" 2>/dev/null

    if [[ $? -eq 0 ]]; then
        print_success "FZF theme updated to $THEME"
    else
        print_error "Failed to update FZF theme"
    fi
}

# Save theme preference
save_theme_preference() {
    echo "$THEME" > "$HOME/.config/dotfiles-theme"
    print_success "Theme preference saved"
}

# Main
main() {
    THEME=$(normalize_theme "$THEME")

    echo ""
    echo "╔════════════════════════════════════════════╗"
    echo "║         Theme Switcher                     ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""
    print_info "Switching to theme: $THEME"
    echo ""

    update_fish_theme
    update_ghostty_theme
    update_alacritty_theme
    update_kitty_theme
    update_tmux_theme
    update_bat_theme
    update_starship_theme
    update_fzf_theme
    update_neovim_theme
    save_theme_preference

    echo ""
    print_success "Theme switch complete!"
    echo ""
    print_info "To apply changes:"
    echo "  • Restart your terminal or run: exec fish"
    echo "  • Reload tmux: tmux source ~/.config/tmux/tmux.conf"
    echo "  • FZF colors will apply immediately in new shell sessions"
    echo "  • Neovim: Restart Neovim to see the new colorscheme"
    echo ""
}

main "$@"
