# AGENTS.md - Dotfiles Repository

This is a personal dotfiles configuration repository for macOS development environments.
It manages configurations for Fish shell, Neovim, Ghostty terminal, herdr, Tmux, Claude Code, and other tools.

## Project Overview

- **Type**: Dotfiles/configuration repository
- **Platform**: macOS (Intel and Apple Silicon), partial Linux support
- **Languages**: Bash, Fish, Lua, TOML, YAML
- **Package Manager**: Homebrew (macOS and Linux); apt only for Linux prerequisites

## Build/Install Commands

```bash
# Show all available commands
make help

# Full installation (installs packages, creates symlinks)
make install

# Update all plugins and submodules
make update

# Verify installation health
make check

# Backup current configurations
make backup

# Restore from latest backup
make restore

# Remove symlinks and installed packages (interactive)
make uninstall

# Switch theme (catppuccin, rose-pine, gruvbox, cyberdream, optura)
make theme THEME=catppuccin VARIANT=dark
make theme THEME=rose-pine VARIANT=light
```

## Testing

This repository has no formal test framework. Use these verification methods:

```bash
# Verify installation health
make check

# Syntax check shell scripts
bash -n scripts/switch-theme.sh
bash -n install.sh

# Test theme switching
bash scripts/switch-theme.sh catppuccin dark

# Debug mode for shell scripts
bash -x scripts/switch-theme.sh catppuccin dark
```

## Code Style Guidelines

### General Rules (from .editorconfig)

- Charset: UTF-8
- Line endings: LF (Unix)
- Final newline: Always insert
- Trailing whitespace: Trim (except Markdown)

### Indentation by File Type

| File Type | Style | Size |
|-----------|-------|------|
| Default | spaces | 2 |
| Shell (*.sh, *.bash, *.zsh) | tabs | 4 |
| Fish (*.fish) | spaces | 4 |
| Lua (*.lua) | spaces | 2 |
| YAML, TOML, JSON, Markdown | spaces | 2 |
| Makefile | tabs | - |
| *.conf, tmux.conf | spaces | 2 |

### Shell Scripts (Bash)

```bash
#!/usr/bin/env bash
set -e  # Exit on error

# Use color constants for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Use functions for logical grouping
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Use local variables in functions
my_function() {
    local my_var="value"
}
```

- Use `#!/usr/bin/env bash` shebang
- Include `set -e` for error handling
- Use functions to organize code
- Add comments for complex logic
- Use colored output (GREEN for success, RED for errors, BLUE for info)

### Fish Shell

```fish
# Use 4-space indentation
if status is-interactive
    # Interactive session code
end

# Define functions in fish/functions/*.fish
function myfunction
    echo "Hello"
end

# Use set for variables
set --export MY_VAR "value"
```

### Lua (Neovim Configuration)

```lua
-- Use 2-space indentation
-- Comments with double dash
return {
  "plugin/name",
  dependencies = {
    "other/plugin",
  },
  config = function()
    -- Plugin configuration
  end,
}
```

- Leader key: Space (` `)
- Local leader: Space (` `)
- Plugin manager: lazy.nvim
- Plugins go in `nvim/lua/plugins/*.lua`
- Core config in `nvim/lua/config/` (options.lua, keymaps.lua, autocmd.lua)

### Naming Conventions

- **Shell scripts**: lowercase with hyphens (`switch-theme.sh`, `tmux-sessionizer`)
- **Fish functions**: lowercase with underscores (`set_fzf_theme.fish`)
- **Lua files**: lowercase (`colorscheme.lua`, `telescope.lua`)
- **Config files**: lowercase, often without extension (`config`, `tmux.conf`)

## Project Structure

```
~/.dotfiles/
├── bin/                     # Custom executable scripts (herdr-*, tmux-*, vmrss)
├── claude/                  # Claude Code config, installed into ~/.claude
│   ├── CLAUDE.md            # Global instructions (symlinked)
│   ├── commands/            # Slash commands (symlinked)
│   ├── hooks/               # Hook scripts (symlinked)
│   ├── skills/              # Skills (symlinked)
│   └── settings.json.template  # Rendered to ~/.claude/settings.json (__HOME__ substituted)
├── fish/                    # Fish shell configuration
│   ├── config.fish          # Main config
│   ├── functions/           # Fish functions (auto-loaded)
│   ├── completions/         # Shell completions
│   └── conf.d/              # Auto-loaded configs
├── nvim/                    # Neovim configuration
│   ├── init.lua             # Entry point
│   └── lua/
│       ├── config/          # Core settings
│       └── plugins/         # Plugin configurations
├── tmux/                    # Tmux configuration (fallback multiplexer)
│   ├── tmux.conf            # Main config
│   └── conf/                # Modular configs
├── ghostty/                 # Ghostty terminal config
├── herdr/                   # herdr config.toml (only this file is symlinked)
├── starship/                # Starship prompt config
├── btop/                    # btop config and themes
├── bat/                     # Bat themes
├── lazygit/                 # Lazygit config
├── scripts/                 # Utility scripts (switch-theme.sh, ghostty-shell, brew-heal.sh, ...)
├── themes/                  # Theme documentation
├── Makefile                 # Command shortcuts
├── install.sh               # Installation script
└── .editorconfig            # Editor formatting rules
```

## Error Handling

### Shell Scripts

```bash
set -e                    # Exit immediately on error
set -x                    # Debug: print commands (temporary)
command || true           # Allow command to fail
command || exit 1         # Explicit failure
```

### User Feedback

```bash
print_info "Starting..."     # Blue arrow: ==> message
print_success "Done"         # Green checkmark: ✓ message
print_error "Failed"         # Red X: ✗ message
```

## Theme System

Supports 5 themes with dark/light variants:
- catppuccin (default): Mocha (dark) / Latte (light)
- rose-pine: Moon (dark) / Dawn (light)
- gruvbox: Dark / Light
- cyberdream: Dark / Light
- optura: Dark / Light

Theme changes affect: Fish, Ghostty, Tmux, Herdr, Bat, Starship, FZF, Neovim, Claude Code,
macOS appearance. The choice is saved to `~/.config/dotfiles-theme`.

Herdr uses its built-in theme names for catppuccin, rose-pine and gruvbox. cyberdream and optura
have no built-in match, so `update_herdr_theme()` writes a full `[theme.custom]` palette on top of
the closest built-in base. The block sits under a marker at the end of `herdr/config.toml`.
Keep custom herdr config above that marker: the switcher drops everything below it.

Claude Code has no custom themes, so `update_claude_theme()` sets `dark-ansi` or `light-ansi` in
`~/.claude.json`, which follow the terminal palette.

## Terminal Workspace

- Ghostty runs `scripts/ghostty-shell`, which starts `herdr --session default` in Fish. herdr is
  the primary multiplexer; tmux is not started automatically and stays as a fallback.
- Ghostty `super+*` keybinds send `Ctrl+b`-prefixed keys that herdr handles (see `ghostty/config`
  and `herdr/config.toml`).
- Custom herdr bindings: `prefix+f` runs `herdr-sessionizer`, `prefix+w` opens the herdr-bar
  command bar (`herdr-switch` kept commented as the fallback), `prefix+g` opens Glance PR.
- Worktree fish functions: `hw [--review] <branch> [<base>]`, `hw-open [--review] <branch>`,
  `hw-rm [<branch>|<path>]`. Worktrees live in `<repo>/.claude/worktrees/<branch>`.

## Important Paths

- **Config directory**: `~/.config` (XDG_CONFIG_HOME)
- **Homebrew (Apple Silicon)**: `/opt/homebrew`
- **Homebrew (Intel)**: `/usr/local`
- **Local binaries**: `~/.local/bin`
- **Backup location**: `~/.dotfiles-backup-YYYYMMDD-HHMMSS`

## Key Bindings Reference

- **herdr prefix**: `Ctrl+b`
- **Tmux prefix**: `Ctrl+b`
- **Neovim leader**: `Space`

## Dependencies

Required commands (verified by `make check`):
fish, tmux, nvim, bat, starship, fd, rg, fzf, delta, zoxide, eza, lazygit, jq, gh, rtk, btop, herdr

Config symlinks checked: ghostty, fish, nvim, starship, tmux, bat, lazygit, btop, and
`herdr/config.toml`. Bin scripts checked: tmux-sessionizer, tmux-windowizer, herdr,
herdr-sessionizer, herdr-switch.
