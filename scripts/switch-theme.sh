#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

THEME="${1:-catppuccin}"
VARIANT="${2:-dark}"
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
        catppuccin|cat|mocha|latte)
            echo "catppuccin"
            ;;
        rose-pine|rose|rosepine|rose_pine|moon|dawn)
            echo "rose-pine"
            ;;
        gruvbox|gruvbox-dark|gruvbox_dark|gruvbox-light|gruvbox_light)
            echo "gruvbox"
            ;;
        cyberdream|cyber)
            echo "cyberdream"
            ;;
        optura|opt)
            echo "optura"
            ;;
        *)
            print_error "Unknown theme: $1"
            echo "Available themes: catppuccin, rose-pine, gruvbox, cyberdream, optura"
            exit 1
            ;;
    esac
}

# Normalize variant
normalize_variant() {
    case "$1" in
        dark|d)
            echo "dark"
            ;;
        light|l)
            echo "light"
            ;;
        *)
            print_error "Unknown variant: $1"
            echo "Available variants: dark, light"
            exit 1
            ;;
    esac
}

# Update Fish theme
update_fish_theme() {
    local theme_file
    case "$THEME" in
        catppuccin)
            if [[ "$VARIANT" == "light" ]]; then
                theme_file="Catppuccin Latte"
            else
                theme_file="Catppuccin Mocha"
            fi
            ;;
        rose-pine)
            if [[ "$VARIANT" == "light" ]]; then
                theme_file="Rose Pine Dawn"
            else
                theme_file="Rose Pine Moon"
            fi
            ;;
        gruvbox)
            if [[ "$VARIANT" == "light" ]]; then
                theme_file="Gruvbox Light"
            else
                theme_file="Gruvbox Dark"
            fi
            ;;
        cyberdream)
            if [[ "$VARIANT" == "light" ]]; then
                theme_file="cyberdream-light"
            else
                theme_file="cyberdream"
            fi
            ;;
        optura)
            if [[ "$VARIANT" == "light" ]]; then
                theme_file="optura-light"
            else
                theme_file="optura"
            fi
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
            if [[ "$VARIANT" == "light" ]]; then
                theme_conf="Catppuccin Latte"
            else
                theme_conf="Catppuccin Mocha"
            fi
            ;;
        rose-pine)
            if [[ "$VARIANT" == "light" ]]; then
                theme_conf="Rose Pine Dawn"
            else
                theme_conf="Rose Pine Moon"
            fi
            ;;
        gruvbox)
            if [[ "$VARIANT" == "light" ]]; then
                theme_conf="Gruvbox Light"
            else
                theme_conf="Gruvbox Dark Hard"
            fi
            ;;
        cyberdream)
            if [[ "$VARIANT" == "light" ]]; then
                theme_conf="cyberdream-light"
            else
                theme_conf="cyberdream"
            fi
            ;;
        optura)
            if [[ "$VARIANT" == "light" ]]; then
                theme_conf="optura-light"
            else
                theme_conf="optura"
            fi
            ;;
    esac

    local opacity
    if [[ "$VARIANT" == "light" ]]; then
        opacity="1"
    else
        opacity="0.7"
    fi

    if [[ -f "$CONFIG_DIR/ghostty/config" ]]; then
        sed -i.bak "s/^theme = .*/theme = $theme_conf/" "$CONFIG_DIR/ghostty/config"
        sed -i.bak "s/^background-opacity = .*/background-opacity = $opacity/" "$CONFIG_DIR/ghostty/config"
        rm -f "$CONFIG_DIR/ghostty/config.bak"
        print_success "Ghostty theme updated to $theme_conf (opacity: $opacity)"
    fi
}

# Update Tmux theme
update_tmux_theme() {
    local theme_file
    case "$THEME" in
        catppuccin)
            if [[ "$VARIANT" == "light" ]]; then
                theme_file="catppuccin-latte.conf"
            else
                theme_file="catppuccin.conf"
            fi
            ;;
        rose-pine)
            if [[ "$VARIANT" == "light" ]]; then
                theme_file="rose-pine-dawn.conf"
            else
                theme_file="rose-pine.conf"
            fi
            ;;
        gruvbox)
            if [[ "$VARIANT" == "light" ]]; then
                theme_file="gruvbox-light.conf"
            else
                theme_file="gruvbox.conf"
            fi
            ;;
        cyberdream)
            if [[ "$VARIANT" == "light" ]]; then
                theme_file="cyberdream-light.conf"
            else
                theme_file="cyberdream.conf"
            fi
            ;;
        optura)
            if [[ "$VARIANT" == "light" ]]; then
                theme_file="optura-light.conf"
            else
                theme_file="optura.conf"
            fi
            ;;
    esac

    if [[ -f "$CONFIG_DIR/tmux/tmux.conf" ]]; then
        # Replace the theme source line with the selected theme
        sed -i.bak "s|^source-file ~/.config/tmux/themes/.*\.conf|source-file ~/.config/tmux/themes/$theme_file|" "$CONFIG_DIR/tmux/tmux.conf"
        rm -f "$CONFIG_DIR/tmux/tmux.conf.bak"
        print_success "Tmux theme updated to $THEME ($VARIANT)"
        print_info "Reload tmux config with: tmux source ~/.config/tmux/tmux.conf"
    fi
}

# Update Bat theme
update_bat_theme() {
    local bat_theme
    case "$THEME" in
        catppuccin)
            if [[ "$VARIANT" == "light" ]]; then
                bat_theme="Catppuccin Latte"
            else
                bat_theme="Catppuccin Mocha"
            fi
            ;;
        rose-pine)
            if [[ "$VARIANT" == "light" ]]; then
                bat_theme="Catppuccin Latte"
                print_info "Rose Pine Dawn not available for bat, using Catppuccin Latte"
            else
                bat_theme="Catppuccin Mocha"
                print_info "Rose Pine not available for bat, using Catppuccin Mocha"
            fi
            ;;
        gruvbox)
            if [[ "$VARIANT" == "light" ]]; then
                bat_theme="gruvbox-light"
            else
                bat_theme="gruvbox-dark"
            fi
            ;;
        cyberdream)
            if [[ "$VARIANT" == "light" ]]; then
                bat_theme="Catppuccin Latte"
                print_info "Cyberdream light not available for bat, using Catppuccin Latte"
            else
                bat_theme="cyberdream"
            fi
            ;;
        optura)
            if [[ "$VARIANT" == "light" ]]; then
                bat_theme="optura-light"
            else
                bat_theme="optura"
            fi
            # Ensure bat sees the new tmTheme files in its cache
            if command -v bat >/dev/null 2>&1; then
                bat cache --build >/dev/null 2>&1 || true
            fi
            ;;
    esac

    if [[ -f "$CONFIG_DIR/fish/config.fish" ]]; then
        sed -i.bak "s/^export BAT_THEME=\".*\"/export BAT_THEME=\"$bat_theme\"/" "$CONFIG_DIR/fish/config.fish"
        rm -f "$CONFIG_DIR/fish/config.fish.bak"
        print_success "Bat theme updated to $bat_theme"
    fi
}

# Update Starship theme
update_starship_theme() {
    local preset_file

    if [[ "$VARIANT" == "light" ]]; then
        preset_file="$CONFIG_DIR/starship/presets/$THEME-light.toml"
        # Fall back to dark if light doesn't exist
        if [[ ! -f "$preset_file" ]]; then
            preset_file="$CONFIG_DIR/starship/presets/$THEME.toml"
            print_info "No light Starship preset for $THEME, using dark"
        fi
    else
        preset_file="$CONFIG_DIR/starship/presets/$THEME.toml"
    fi

    if [[ ! -f "$preset_file" ]]; then
        print_error "Starship preset not found: $preset_file"
        return
    fi

    # Copy the preset over the active config
    cp "$preset_file" "$CONFIG_DIR/starship/starship.toml"
    print_success "Starship theme updated to $THEME ($VARIANT)"
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
        cyberdream)
            colorscheme="cyberdream"
            ;;
        optura)
            colorscheme="optura"
            ;;
    esac

    if [[ ! -f "$colorscheme_file" ]]; then
        print_error "Neovim colorscheme file not found"
        return
    fi

    print_info "Updating Neovim colorscheme to $colorscheme ($VARIANT)..."

    # Update variant/flavour settings based on theme and variant
    case "$THEME" in
        catppuccin)
            if [[ "$VARIANT" == "light" ]]; then
                sed -i.bak 's/flavour = "mocha"/flavour = "latte"/g' "$colorscheme_file"
                sed -i.bak 's/flavour = "frappe"/flavour = "latte"/g' "$colorscheme_file"
                sed -i.bak 's/flavour = "macchiato"/flavour = "latte"/g' "$colorscheme_file"
            else
                sed -i.bak 's/flavour = "latte"/flavour = "mocha"/g' "$colorscheme_file"
                sed -i.bak 's/flavour = "frappe"/flavour = "mocha"/g' "$colorscheme_file"
                sed -i.bak 's/flavour = "macchiato"/flavour = "mocha"/g' "$colorscheme_file"
            fi
            ;;
        rose-pine)
            if [[ "$VARIANT" == "light" ]]; then
                sed -i.bak 's/variant = "moon"/variant = "dawn"/g' "$colorscheme_file"
                sed -i.bak 's/variant = "main"/variant = "dawn"/g' "$colorscheme_file"
                sed -i.bak 's/dark_variant = "moon"/dark_variant = "dawn"/g' "$colorscheme_file"
                sed -i.bak 's/dark_variant = "main"/dark_variant = "dawn"/g' "$colorscheme_file"
            else
                sed -i.bak 's/variant = "dawn"/variant = "moon"/g' "$colorscheme_file"
                sed -i.bak 's/dark_variant = "dawn"/dark_variant = "moon"/g' "$colorscheme_file"
            fi
            ;;
        cyberdream)
            if [[ "$VARIANT" == "light" ]]; then
                # Add variant = "light" to cyberdream setup if not present
                if ! grep -q 'variant = "light"' "$colorscheme_file"; then
                    sed -i.bak 's/require("cyberdream").setup({/require("cyberdream").setup({\n        variant = "light",/g' "$colorscheme_file"
                fi
            else
                # Remove variant = "light" if present
                sed -i.bak '/variant = "light",/d' "$colorscheme_file"
            fi
            ;;
        optura)
            if [[ "$VARIANT" == "light" ]]; then
                sed -i.bak 's/vim\.g\.optura_variant = "dark"/vim.g.optura_variant = "light"/g' "$colorscheme_file"
            else
                sed -i.bak 's/vim\.g\.optura_variant = "light"/vim.g.optura_variant = "dark"/g' "$colorscheme_file"
            fi
            ;;
    esac

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
        cyberdream)
            sed -i.bak 's/^[[:space:]]*-- vim\.cmd("colorscheme cyberdream")/      vim.cmd("colorscheme cyberdream")/g' "$colorscheme_file"
            ;;
        optura)
            sed -i.bak 's/^[[:space:]]*-- vim\.cmd("colorscheme optura")/      vim.cmd("colorscheme optura")/g' "$colorscheme_file"
            ;;
    esac

    # Clean up backup file
    rm -f "$colorscheme_file.bak"

    # Update lazy.lua install colorscheme
    if [[ -f "$lazy_file" ]]; then
        sed -i.bak "s/install = { colorscheme = { \".*\" } }/install = { colorscheme = { \"$colorscheme\" } }/g" "$lazy_file"
        rm -f "$lazy_file.bak"
    fi

    print_success "Neovim colorscheme updated to $colorscheme ($VARIANT)"
    print_info "Restart Neovim to see changes"
}

# Update macOS system appearance
update_macos_theme() {
    if [[ "$VARIANT" == "light" ]]; then
        osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to false'
        print_success "macOS appearance set to Light"
    else
        osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to true'
        print_success "macOS appearance set to Dark"
    fi
}

# Update FZF theme
update_fzf_theme() {
    # Call the Fish function to update FZF colors
    print_info "Updating FZF theme..."

    # Update FZF theme using Fish function
    fish -c "set_fzf_theme $THEME $VARIANT" 2>/dev/null

    if [[ $? -eq 0 ]]; then
        print_success "FZF theme updated to $THEME ($VARIANT)"
    else
        print_error "Failed to update FZF theme"
    fi
}

# Update OpenCode theme
update_opencode_theme() {
    local opencode_config="$CONFIG_DIR/opencode/opencode.json"

    if [[ -f "$opencode_config" ]]; then
        sed -i.bak "s/\"theme\": \".*\"/\"theme\": \"$THEME\"/" "$opencode_config"
        rm -f "$opencode_config.bak"
        print_success "OpenCode theme updated to $THEME"
    fi
}

# Update Claude Code theme
# Claude Code has no custom theme system — only built-in names. The `-ansi`
# variants inherit the terminal's ANSI palette, so any of our terminal themes
# (catppuccin, optura, etc.) become the Claude Code palette automatically.
update_claude_theme() {
    local claude_config="$HOME/.claude.json"

    if ! command -v jq >/dev/null 2>&1; then
        print_error "jq not found — skipping Claude Code theme"
        return
    fi

    if [[ ! -f "$claude_config" ]]; then
        return
    fi

    local claude_theme
    if [[ "$VARIANT" == "light" ]]; then
        claude_theme="light-ansi"
    else
        claude_theme="dark-ansi"
    fi

    local tmp
    tmp=$(mktemp)
    if jq --arg t "$claude_theme" '.theme = $t' "$claude_config" > "$tmp"; then
        mv "$tmp" "$claude_config"
        print_success "Claude Code theme updated to $claude_theme"
    else
        rm -f "$tmp"
        print_error "Failed to update Claude Code theme"
    fi
}

# Update Herdr theme
# herdr ships built-in themes for catppuccin, rose-pine and gruvbox (both
# variants), so those map straight to a name. cyberdream and optura have no
# built-in equivalent, so every color token is overridden in [theme.custom]
# on top of the closest built-in base.
# The [theme] block is regenerated below the marker at the end of config.toml.
update_herdr_theme() {
    local herdr_config="$CONFIG_DIR/herdr/config.toml"

    if [[ ! -f "$herdr_config" ]]; then
        return
    fi

    local base custom=""

    case "$THEME-$VARIANT" in
        catppuccin-dark)
            base="catppuccin"
            ;;
        catppuccin-light)
            base="catppuccin-latte"
            ;;
        rose-pine-dark)
            base="rose-pine"
            ;;
        rose-pine-light)
            base="rose-pine-dawn"
            ;;
        gruvbox-dark)
            base="gruvbox"
            ;;
        gruvbox-light)
            base="gruvbox-light"
            ;;
        cyberdream-dark)
            base="catppuccin"
            custom=$(cat <<'EOF'
accent = "#5ef1ff"
panel_bg = "#16181a"
sidebar_bg = "#16181a"
active_row_bg = "#1e2124"
selection_bg = "#3c4048"
surface0 = "#1e2124"
surface1 = "#3c4048"
surface_dim = "#1e2124"
overlay0 = "#3c4048"
overlay1 = "#7b8496"
text = "#ffffff"
subtext0 = "#7b8496"
mauve = "#ff5ef1"
green = "#5eff6c"
yellow = "#f1ff5e"
red = "#ff6e5e"
blue = "#5ea1ff"
teal = "#5ef1ff"
peach = "#ffbd5e"
EOF
)
            ;;
        cyberdream-light)
            base="catppuccin-latte"
            custom=$(cat <<'EOF'
accent = "#008c99"
panel_bg = "#ffffff"
sidebar_bg = "#ffffff"
active_row_bg = "#eaeaea"
selection_bg = "#acacac"
surface0 = "#eaeaea"
surface1 = "#acacac"
surface_dim = "#eaeaea"
overlay0 = "#acacac"
overlay1 = "#7b8496"
text = "#16181a"
subtext0 = "#7b8496"
mauve = "#d100bf"
green = "#008b0c"
yellow = "#997b00"
red = "#d11500"
blue = "#0057d1"
teal = "#008c99"
peach = "#d17c00"
EOF
)
            ;;
        optura-dark)
            base="catppuccin"
            custom=$(cat <<'EOF'
accent = "#d0ae50"
panel_bg = "#1a1616"
sidebar_bg = "#1a1616"
active_row_bg = "#211d1c"
selection_bg = "#420d41"
surface0 = "#262320"
surface1 = "#332d2b"
surface_dim = "#211d1c"
overlay0 = "#3d3634"
overlay1 = "#7a756a"
text = "#f0eee4"
subtext0 = "#a9a396"
mauve = "#a86ab8"
green = "#61c2ab"
yellow = "#e6c876"
red = "#c8595a"
blue = "#d9ecf7"
teal = "#7ed3c0"
peach = "#d0ae50"
EOF
)
            ;;
        optura-light)
            base="catppuccin-latte"
            custom=$(cat <<'EOF'
accent = "#8b6914"
panel_bg = "#f0eee4"
sidebar_bg = "#f0eee4"
active_row_bg = "#e8e4dc"
selection_bg = "#d9ecf7"
surface0 = "#e8e4dc"
surface1 = "#d6d0c2"
surface_dim = "#e8e4dc"
overlay0 = "#a9a396"
overlay1 = "#7a756a"
text = "#1a1616"
subtext0 = "#56524a"
mauve = "#7e3d8a"
green = "#2a7d6a"
yellow = "#8b6914"
red = "#a33b3b"
blue = "#202e42"
teal = "#2a7d6a"
peach = "#d0ae50"
EOF
)
            ;;
        *)
            print_error "No Herdr theme mapping for $THEME ($VARIANT)"
            return
            ;;
    esac

    local marker="# BEGIN theme — managed by scripts/switch-theme.sh"
    local tmp
    tmp=$(mktemp)

    awk -v m="$marker" '$0 == m { exit } { print }' "$herdr_config" > "$tmp"
    {
        echo "$marker"
        echo "[theme]"
        echo "name = \"$base\""
        echo "auto_switch = false"
        if [[ -n "$custom" ]]; then
            echo ""
            echo "[theme.custom]"
            echo "$custom"
        fi
    } >> "$tmp"

    # cat, not mv: config.toml is a symlink into the dotfiles repo.
    cat "$tmp" > "$herdr_config"
    rm -f "$tmp"

    if [[ -n "$custom" ]]; then
        print_success "Herdr theme updated to $THEME ($VARIANT) via $base + custom colors"
    else
        print_success "Herdr theme updated to $base"
    fi

    if command -v herdr >/dev/null 2>&1; then
        # reload-config answers with JSON: status "applied", or "partial" plus a
        # diagnostics list when it drops a key it does not know.
        local reload
        if reload=$(herdr server reload-config 2>/dev/null); then
            if [[ "$reload" == *'"status":"applied"'* ]]; then
                print_success "Herdr server reloaded config"
            else
                print_error "Herdr reload incomplete: $reload"
            fi
        else
            print_info "Herdr not running — theme applies on next launch"
        fi
    fi
}

# Save theme preference
save_theme_preference() {
    echo "$THEME $VARIANT" > "$HOME/.config/dotfiles-theme"
    print_success "Theme preference saved ($THEME $VARIANT)"
}

# Main
main() {
    THEME=$(normalize_theme "$THEME")
    VARIANT=$(normalize_variant "$VARIANT")

    echo ""
    echo "╔════════════════════════════════════════════╗"
    echo "║         Theme Switcher                     ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""
    print_info "Switching to theme: $THEME ($VARIANT)"
    echo ""

    update_macos_theme
    update_fish_theme
    update_ghostty_theme
    update_tmux_theme
    update_herdr_theme
    update_bat_theme
    update_starship_theme
    update_fzf_theme
    update_neovim_theme
    update_opencode_theme
    update_claude_theme
    save_theme_preference

    echo ""
    print_success "Theme switch complete!"
    echo ""
    print_info "To apply changes:"
    echo "  • Restart your terminal or run: exec fish"
    echo "  • Reload tmux: tmux source ~/.config/tmux/tmux.conf"
    echo "  • Herdr: reloaded live if running, else applies on next launch"
    echo "  • FZF colors will apply immediately in new shell sessions"
    echo "  • Neovim: Restart Neovim to see the new colorscheme"
    echo "  • OpenCode: Theme will apply on next launch"
    echo ""
}

main "$@"
