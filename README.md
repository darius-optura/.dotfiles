# Dotfiles

Modern macOS development environment configuration with automated setup and theme switching.

## Features

- **Automated Installation** - Single command setup with `make install`
- **Theme Switching** - Quick theme changes across all applications
- **Architecture Support** - Works on both Intel and Apple Silicon Macs
- **Backup System** - Automatic backup of existing configurations
- **Health Checks** - Verify installation with `make check`

## Tech Stack

### Core Tools
- **[Ghostty](https://ghostty.org/)** - Primary terminal emulator
- **[Fish Shell](https://fishshell.com/)** - Friendly interactive shell
- **[Tmux](https://github.com/tmux/tmux)** - Terminal multiplexer
- **[Neovim](https://neovim.io/)** - Hyperextensible text editor
- **[Starship](https://starship.rs/)** - Cross-shell prompt

### CLI Utilities
- **[bat](https://github.com/sharkdp/bat)** - Cat with syntax highlighting
- **[eza](https://github.com/eza-community/eza)** - Modern ls replacement
- **[fd](https://github.com/sharkdp/fd)** - Fast find alternative
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** - Fast grep tool
- **[fzf](https://github.com/junegunn/fzf)** - Fuzzy finder
- **[git-delta](https://github.com/dandavison/delta)** - Better git diffs
- **[zoxide](https://github.com/ajeetdsouza/zoxide)** - Smarter cd
- **[lazygit](https://github.com/jesseduffield/lazygit)** - Terminal UI for git

### Additional Tools
- **[OrbStack](https://orbstack.dev/)** - Docker & Kubernetes for macOS
- **Go, Python, Luarocks** - Development runtimes

## Quick Start

### Bootstrap Installation (Recommended)

Install everything with a single command:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/cupsadarius/dotfiles/master/bootstrap.sh)"
```

### Manual Installation

```bash
# Clone repository with submodules
git clone --recursive https://github.com/cupsadarius/dotfiles.git ~/.dotfiles

# Run installation
cd ~/.dotfiles
make install
```

That's it! The script will:
1. Install Homebrew (if needed)
2. Install all required packages
3. Backup existing configs
4. Create symlinks
5. Set up Fish shell, oh-my-fish, fisher, and TPM

## Theme Management

Switch themes across all applications with one command:

```bash
make theme THEME=catppuccin    # Cozy pastel theme
make theme THEME=rose-pine     # Low-contrast theme
make theme THEME=gruvbox       # Retro warm colors
```

See [themes/README.md](themes/README.md) for more details on adding custom themes.

## Available Commands

```bash
make help         # Show all available commands
make install      # Full installation
make update       # Update all plugins and submodules
make backup       # Backup current configurations
make restore      # Restore from latest backup
make uninstall    # Remove symlinks
make theme        # Switch theme (THEME=catppuccin|rose-pine|gruvbox)
make check        # Verify installation health
```

## Project Structure

```
~/.dotfiles/
├── alacritty/          # Alacritty config (fallback terminal)
├── bat/                # Bat themes
├── bin/                # Custom scripts
│   ├── tmux-sessionizer
│   ├── tmux-windowizer
│   └── vmrss
├── btop/               # System monitor config
├── fastfetch/          # System info tool config
├── fish/               # Fish shell config
├── ghostty/            # Ghostty terminal config
├── k9s/                # Kubernetes TUI config
├── kitty/              # Kitty config (fallback terminal)
├── lazygit/            # Lazygit config
├── nvim/               # Neovim configuration
├── starship/           # Starship prompt config
├── tmux/               # Tmux configuration
├── tmux-sessionizer/   # Tmux sessionizer config
├── scripts/            # Utility scripts
├── themes/             # Theme documentation
├── install.sh          # Main installation script
├── bootstrap.sh        # Bootstrap script
├── Makefile            # Command shortcuts
└── PACKAGES.md         # Package documentation
```

## Configuration

### Tmux Sessionizer

The tmux-sessionizer helps you quickly switch between projects. Configure your project paths:

```bash
# Edit the config file
nvim ~/.config/tmux-sessionizer/config

# Add your project directories (one per line)
~/Work/project1
~/Work/project2
~/Incubator/experiments
```

Then use `prefix + f` (default: `Ctrl+b f` or `Super+f` in Ghostty) to launch the sessionizer.

### Custom Keybindings

#### Ghostty
- `Super+f` - Launch tmux sessionizer
- `Super+comma` - Open tmux command mode
- `Super+k` - Switch session
- `Super+t` - New tmux window
- `Super+n` - Split horizontally
- `Super+Shift+n` - Split vertically
- `Super+w` - Close pane
- `Super+1-9` - Switch to window 1-9

See [ghostty/config](ghostty/config) for all keybindings.

#### Tmux
- `prefix` = `Ctrl+b` (default)
- `prefix + r` - Reload tmux config
- `prefix + f` - Launch sessionizer
- `prefix + M` - Edit tmux config

#### Fish Shell
Aliases configured in [fish/config.fish](fish/config.fish):
- `vim` → `nvim`
- `cat` → `bat`
- `ll` → `eza -l -g --icons --git`
- `gg` → `lazygit`
- `k` → `kubectl`

## Architecture Support

This configuration automatically detects and supports both:
- **Intel Macs** - Uses `/usr/local` paths
- **Apple Silicon Macs** - Uses `/opt/homebrew` paths

## Troubleshooting

### Fish not set as default shell

```bash
# Add fish to shells
echo $(which fish) | sudo tee -a /etc/shells

# Set as default
chsh -s $(which fish)
```

### Tmux plugins not loading

After installation or when switching themes for the first time:

1. Open tmux
2. Press `prefix + I` (capital i) to install all plugins
3. All theme plugins (rose-pine, gruvbox) will be installed
4. Theme switcher will activate the correct one

### Neovim plugins not loading

Open Neovim and run:
```vim
:Lazy sync
```

### Theme not applying

```bash
# Restart terminal
exec fish

# Reload tmux
tmux source ~/.config/tmux/tmux.conf

# Restart Neovim to apply colorscheme
# Just close and reopen Neovim

# Rebuild bat cache (if needed)
bat cache --build
```

### Verify installation

```bash
make check
```

## Uninstallation

To remove the dotfiles:

```bash
cd ~/.dotfiles
make uninstall    # Remove symlinks
make restore      # Restore previous configs (if backed up)
```

To completely remove:

```bash
rm -rf ~/.dotfiles
rm -rf ~/.dotfiles-backup-*
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on customization and contributing.

## License

This is a personal configuration repository. Feel free to fork and customize for your own use.

## Credits

- Tmux sessionizer inspired by [ThePrimeagen](https://github.com/ThePrimeagen/.dotfiles)
- Various configurations inspired by the dotfiles community

## Author

**Darius** - [cupsadarius](https://github.com/cupsadarius)
