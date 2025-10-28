# Required Packages

This file lists all packages required for the dotfiles setup.

## Core Tools

### Terminal & Shell
- **fish** - Friendly interactive shell
- **ghostty** - Modern, fast GPU-accelerated terminal emulator (primary)
- **tmux** - Terminal multiplexer for session management
- **starship** - Fast, customizable shell prompt

### Editor
- **neovim** - Hyperextensible Vim-based text editor
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

### Development
- **go** - Go programming language
- **python** - Python programming language

### Container & Orchestration
- **orbstack** - Fast, lightweight Docker & Kubernetes alternative for macOS

### Fonts
- **font-hack-nerd-font** - Patched font with icons for terminal use

## Installation Command

### Homebrew Formulae
```bash
brew install fish tmux neovim bat starship fd ripgrep fzf git-delta zoxide eza go lazygit luarocks python
```

### Homebrew Casks
```bash
brew install --cask ghostty orbstack
```

### Fonts
```bash
brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font
```

## Optional Dependencies

### Fish Shell Plugin Managers
- **oh-my-fish** - Framework for managing Fish shell configuration
- **fisher** - Plugin manager for Fish shell

### Tmux Plugin Manager
- **tpm** - Tmux Plugin Manager

### Node.js (via Fisher plugin)
- **nvm.fish** - Node Version Manager for Fish shell

## Package Sources by Config File

### From fish/config.fish
- bat, eza, lazygit, kubectl, python, neovim, fd, fzf, go

### From tmux/tmux.conf
- tmux, fish

### From ghostty/config
- fish, tmux

### From README.md
- fish, tmux, neovim, bat, starship, fd, ripgrep, fzf, git-delta, zoxide, eza, go, lazygit, orbstack, luarocks

### From nvim/lua/config/lazy.lua
- neovim, git, luarocks
