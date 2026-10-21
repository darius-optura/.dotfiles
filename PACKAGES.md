# Required Packages

This file lists all packages required for the dotfiles setup. `install.sh` is the source of truth.

## Core Tools

### Terminal & Shell
- **fish** - Friendly interactive shell
- **ghostty** - Modern, fast GPU-accelerated terminal emulator (primary, macOS only)
- **herdr** - Agent multiplexer for workspaces and git worktrees (primary multiplexer)
- **tmux** - Terminal multiplexer (fallback)
- **starship** - Fast, customizable shell prompt

### Editor
- **neovim** - Hyperextensible Vim-based text editor
- **tree-sitter-cli** - Tree-sitter CLI (for Neovim parsers)
- **luarocks** - Lua package manager (for Neovim plugins)

### CLI Utilities
- **bat** - Cat clone with syntax highlighting and Git integration
- **eza** - Modern replacement for ls with colors and Git status
- **fd** - Fast and user-friendly alternative to find
- **ripgrep** - Extremely fast grep alternative
- **fzf** - Command-line fuzzy finder
- **git-delta** - Syntax-highlighting pager for git, diff, and grep
- **zoxide** - Smarter cd command that learns your habits
- **lazygit** - Terminal UI for git commands
- **jq** - JSON processor (used by the herdr scripts, hw functions and Claude Code hooks)
- **gh** - GitHub CLI
- **rtk** - CLI proxy that cuts LLM token use (Claude Code Bash hook)
- **btop** - System monitor

### Development
- **go** - Go programming language
- **python** - Python programming language

### Container & Orchestration
- **orbstack** - Fast, lightweight Docker & Kubernetes alternative for macOS

### Fonts
- **font-hack-nerd-font** - Patched font with icons for terminal use

## Installation Command

### Homebrew Formulae (all platforms)
```bash
brew install fish tmux neovim bat starship fd ripgrep fzf git-delta zoxide eza go lazygit tree-sitter-cli luarocks python jq gh rtk btop
```

### Homebrew Casks (macOS only)
```bash
brew install --cask ghostty orbstack
```

### Fonts
```bash
# macOS
brew install --cask font-hack-nerd-font
```

On Linux, `install.sh` downloads `Hack.zip` from the nerd-fonts releases into
`~/.local/share/fonts` and runs `fc-cache`.

### herdr

herdr is not installed with Homebrew (Homebrew only bottles it for Apple Silicon). `install.sh`
downloads the release binary `herdr-<os>-<arch>` from
`https://github.com/ogulcancelik/herdr/releases/latest` into `~/.local/bin/herdr`.
`herdr update` keeps it current.

The herdr config uses two plugins that `install.sh` does not install:
- **herdr-bar** - command bar on `prefix+w` (`herdr plugin install jeffarese/herdr-bar --yes`)
- **glance.pr** - Glance PR pane on `prefix+g`

### Linux (Debian/Ubuntu)

`install.sh` installs these apt packages first, then installs Homebrew on Linux and uses the same
formulae list:
```bash
sudo apt-get install -y build-essential curl git procps file
```

Ghostty is not available via Homebrew on Linux; build it from source
(https://ghostty.org/docs/install/build).

## Optional Dependencies

### Fish Shell Plugin Managers
- **oh-my-fish** - Framework for managing Fish shell configuration
- **fisher** - Plugin manager for Fish shell. `scripts/fisher-sync.sh` installs the plugins listed
  in `fish/fish_plugins`: fisher, nvm.fish, catppuccin/fish

### Tmux Plugin Manager
- **tpm** - Tmux Plugin Manager

### Node.js (via Fisher plugin)
- **nvm.fish** - Node Version Manager for Fish shell. `install.sh` installs Node.js LTS with it and
  sets it as the default version

## Package Sources by Config File

### From fish/config.fish
- bat, eza, lazygit, kubectl, python, neovim, fd, fzf, go

### From tmux/tmux.conf
- tmux, fish

### From ghostty/config and scripts/ghostty-shell
- fish, herdr

### From herdr/config.toml and bin/herdr-*
- herdr, fish, fzf, jq

### From claude/settings.json.template
- rtk, jq

### From nvim/lua/config/lazy.lua
- neovim, git, luarocks
