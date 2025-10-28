# Theme Management

This dotfiles setup supports quick theme switching across all applications.

## Supported Themes

Currently supported themes:
- **Catppuccin Mocha** - Soothing pastel theme for cozy coding
- **Rose Pine Moon** - Low-contrast theme with a subtle palette
- **Gruvbox Dark** - Retro groove color scheme with warm tones

## Switching Themes

To switch themes, use the Makefile command:

```bash
make theme THEME=catppuccin
make theme THEME=rose-pine
make theme THEME=gruvbox
```

Or run the script directly:

```bash
./scripts/switch-theme.sh catppuccin
./scripts/switch-theme.sh rose-pine
./scripts/switch-theme.sh gruvbox
```

## What Gets Updated

When you switch themes, the following configurations are updated:

1. **Fish Shell** - Terminal color scheme
2. **Ghostty** - Terminal emulator theme
3. **Alacritty** - Fallback terminal theme
4. **Kitty** - Fallback terminal theme
5. **Tmux** - Status bar and pane colors
6. **Bat** - Syntax highlighting theme
7. **Starship** - Prompt color palette
8. **FZF** - Fuzzy finder colors (automatically via Fish function)
9. **Neovim** - Editor colorscheme (automatically via sed)

## Adding a New Theme

To add support for a new theme, follow these steps:

### 1. Add Theme Files

Create theme files for each application in their respective config directories:

```bash
# Fish theme
~/.config/fish/themes/YourTheme.theme

# Ghostty theme
~/.config/ghostty/themes/yourtheme.conf

# Alacritty theme
~/.config/alacritty/yourtheme.toml

# Kitty theme
~/.config/kitty/themes/yourtheme.conf

# Tmux theme (if using catppuccin plugin)
~/.config/tmux/themes/yourtheme.conf

# Neovim colorscheme
# Install via your plugin manager
```

### 2. Update Theme Switcher Script

Edit `scripts/switch-theme.sh` and add your theme to each function:

```bash
# In normalize_theme()
yourtheme|your-theme)
    echo "yourtheme"
    ;;

# In update_fish_theme()
yourtheme)
    theme_file="YourTheme"
    ;;

# In update_ghostty_theme()
yourtheme)
    theme_conf="yourtheme.conf"
    ;;

# ... repeat for all other update functions including:
# - update_alacritty_theme() - updates import line in alacritty.toml
# - update_kitty_theme() - updates include line in kitty.conf
# - update_tmux_theme() - replaces source-file line in tmux.conf
# - update_bat_theme() - updates BAT_THEME in fish/config.fish
# - update_starship_theme() - copies preset file to starship.toml
# - update_fzf_theme() - calls Fish function to update FZF colors
# - update_neovim_theme() - comments/uncomments vim.cmd in colorscheme.lua
```

### 3. Test Your Theme

```bash
make theme THEME=yourtheme
```

Verify that all applications have updated correctly.

## Theme File Examples

### Fish Theme

Fish themes use a specific format. Generate a theme:

```fish
# Set your desired colors, then:
fish_config theme save "YourTheme"
```

Or manually create: `~/.config/fish/themes/YourTheme.theme`

```fish
# YourTheme color scheme
fish_color_normal: RRGGBB
fish_color_command: RRGGBB
fish_color_param: RRGGBB
# ... etc
```

### Ghostty Theme

Create `~/.config/ghostty/themes/yourtheme.conf`:

```conf
background = #1e1e2e
foreground = #cdd6f4
cursor-color = #f5e0dc

palette = 0=#45475a
palette = 1=#f38ba8
palette = 2=#a6e3a1
# ... etc (16 colors total)
```

### Alacritty Theme

Create `~/.config/alacritty/yourtheme.toml`:

```toml
[colors.primary]
background = "#1e1e2e"
foreground = "#cdd6f4"

[colors.normal]
black = "#45475a"
red = "#f38ba8"
green = "#a6e3a1"
# ... etc
```

### Tmux Theme

Create a complete theme config file in `~/.config/tmux/themes/yourtheme.conf`:

```tmux
# Your Theme Configuration

# If using a plugin, add to conf/plugins.conf:
# set -g @plugin 'author/tmux-yourtheme'

# Plugin settings
set -g @yourtheme_variant 'dark'

# Status bar configuration
set -g status-right-length 100
set -g status-left-length 100
set-option -g status-position top
# ... etc
```

**Important:** Add the theme plugin to `~/.config/tmux/conf/plugins.conf`:
```tmux
set -g @plugin 'author/tmux-yourtheme'
```

Then run `prefix + I` in tmux to install the plugin.

The theme switcher will update the `source-file` line in `tmux.conf` to load your theme.

### Starship Preset

Create a complete Starship preset file in `~/.config/starship/presets/yourtheme.toml`:

```toml
# Get editor completions based on the config schema
"$schema" = 'https://starship.rs/config-schema.json'

scan_timeout = 30
command_timeout = 3600
add_newline = true

# Your custom format string
format = """
$username\
$directory\
$git_branch\
$git_status\
# ... etc
"""

# Set the palette
palette = "yourtheme"

# Module configurations
[directory]
truncation_length = 4
style = "bold lavender"

# ... more module configs

# Palette definition
[palettes.yourtheme]
color_fg0 = '#cdd6f4'
color_bg1 = '#1e1e2e'
color_blue = '#89b4fa'
# ... etc
```

The theme switcher copies the entire preset file to `starship.toml`, so each preset should be a complete, standalone configuration.

### FZF Theme

Add a new case to `~/.config/fish/functions/set_fzf_theme.fish`:

```fish
case yourtheme
    # Your Theme FZF Colors
    set -Ux FZF_DEFAULT_OPTS "\
--color=fg:#foreground,header:#color1,info:#color2,pointer:#color3 \
--color=marker:#color4,fg+:#foreground,prompt:#color2,hl+:#color1 \
--color=selected-bg:#bg_highlight \
--color=border:#border,label:#foreground"
```

The FZF theme is automatically applied when you switch themes. You can also manually test it:
```bash
set_fzf_theme yourtheme
```

## Theme Resources

Find pre-made themes at:

- **Catppuccin**: https://github.com/catppuccin/catppuccin
- **Rose Pine**: https://github.com/rose-pine/rose-pine-theme
- **Gruvbox**: https://github.com/morhetz/gruvbox
- **Tokyo Night**: https://github.com/tokyo-night/tokyo-night-vscode-theme
- **Nord**: https://www.nordtheme.com/
- **Dracula**: https://draculatheme.com/

## Troubleshooting

### Theme not applying to terminal

Restart your terminal or run:
```bash
exec fish
```

### Tmux colors not updating

Reload tmux configuration:
```bash
tmux source ~/.config/tmux/tmux.conf
```

Or press: `prefix + r` (if you have the binding)

### Neovim colorscheme not changing

Neovim colorschemes need to be installed and configured separately. Update your colorscheme in:
- `~/.config/nvim/lua/plugins/colorscheme.lua`

### Bat theme not working

Rebuild the bat cache:
```bash
bat cache --build
```

## Contributing

If you add support for a new theme, please consider contributing back:

1. Test the theme across all applications
2. Update this README with the new theme
3. Submit a pull request with your changes

Thank you for improving these dotfiles!
