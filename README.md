# Dotfiles

Modern macOS development environment configuration with automated setup and theme switching.

## Features

- **Automated Installation** - Single command setup with `make install`
- **Theme Switching** - Quick theme changes across all applications
- **Architecture Support** - Works on Intel and Apple Silicon Macs, with partial Debian/Ubuntu support
- **Backup System** - Automatic backup of existing configurations
- **Health Checks** - Verify installation with `make check`
- **Claude Code Config** - Hooks, skills, commands and settings for Claude Code

## Tech Stack

### Core Tools
- **[Ghostty](https://ghostty.org/)** - Primary terminal emulator
- **[herdr](https://herdr.dev)** - Agent multiplexer for workspaces and git worktrees (primary multiplexer)
- **[Fish Shell](https://fishshell.com/)** - Friendly interactive shell
- **[Tmux](https://github.com/tmux/tmux)** - Terminal multiplexer (kept as a fallback)
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
- **[jq](https://jqlang.github.io/jq/)** - JSON processor (used by the herdr scripts and hooks)
- **[gh](https://cli.github.com/)** - GitHub CLI
- **[rtk](https://www.rtk-ai.app/)** - CLI proxy that cuts LLM token use, run as a Claude Code Bash hook
- **[btop](https://github.com/aristocratos/btop)** - System monitor

### Additional Tools
- **[OrbStack](https://orbstack.dev/)** - Docker & Kubernetes for macOS
- **Go, Python, Luarocks, tree-sitter-cli** - Development runtimes and tools
- **Node.js** - LTS, installed through nvm.fish

## Quick Start

### Bootstrap Installation (Recommended)

Install everything with a single command (macOS only):

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
2. Install all required packages, plus the herdr release binary into `~/.local/bin`
3. Backup existing configs
4. Create symlinks (configs into `~/.config`, scripts into `~/.local/bin`)
5. Install the Claude Code config into `~/.claude`
6. Set up Fish shell, oh-my-fish, fisher plugins, Node.js LTS, and TPM

`install.sh` also accepts `--dry-run`, `--force` and `--uninstall`.

## Theme Management

Switch themes across all applications with one command:

```bash
# Dark themes (default)
make theme THEME=catppuccin                    # Catppuccin Mocha
make theme THEME=rose-pine                     # Rose Pine Moon
make theme THEME=gruvbox                       # Gruvbox Dark
make theme THEME=cyberdream                    # Cyberdream
make theme THEME=optura                        # Optura

# Light themes
make theme THEME=catppuccin VARIANT=light      # Catppuccin Latte
make theme THEME=rose-pine VARIANT=light       # Rose Pine Dawn
make theme THEME=gruvbox VARIANT=light         # Gruvbox Light
make theme THEME=cyberdream VARIANT=light      # Cyberdream Light
make theme THEME=optura VARIANT=light          # Optura Light

# Or use the script directly
~/.dotfiles/scripts/switch-theme.sh catppuccin light
~/.dotfiles/scripts/switch-theme.sh gruvbox dark
```

The theme switcher updates: macOS appearance, Fish, Ghostty, Tmux, Herdr, Bat, Starship, FZF,
Neovim, and Claude Code. It saves the choice to `~/.config/dotfiles-theme`.

See [themes/README.md](themes/README.md) for more details on adding custom themes.

## Available Commands

```bash
make help         # Show all available commands
make install      # Full installation
make update       # Update Homebrew, submodules, TPM, Fish and Neovim plugins
make backup       # Backup current configurations
make restore      # Restore from latest backup
make uninstall    # Remove symlinks and installed packages (interactive)
make theme        # Switch theme (THEME=catppuccin|rose-pine|gruvbox|cyberdream|optura VARIANT=dark|light)
make check        # Verify installation health
```

## Project Structure

```
~/.dotfiles/
├── bat/                # Bat themes
├── bin/                # Custom scripts
│   ├── herdr-sessionizer
│   ├── herdr-switch
│   ├── tmux-sessionizer
│   ├── tmux-windowizer
│   └── vmrss
├── btop/               # System monitor config
├── claude/             # Claude Code config (CLAUDE.md, commands, hooks, skills, settings template)
├── fish/               # Fish shell config
├── ghostty/            # Ghostty terminal config
├── herdr/              # herdr config (config.toml)
├── lazygit/            # Lazygit config
├── nvim/               # Neovim configuration
├── starship/           # Starship prompt config
├── tmux/               # Tmux configuration
├── tmux-sessionizer/   # Sessionizer project list (example config)
├── scripts/            # Utility scripts (theme switcher, ghostty-shell, brew-heal, ...)
├── themes/             # Theme documentation
├── install.sh          # Main installation script
├── bootstrap.sh        # Bootstrap script
├── Makefile            # Command shortcuts
└── PACKAGES.md         # Package documentation
```

`install.sh` links `~/.config/herdr/config.toml` only, not the whole directory, because herdr keeps
sockets, logs, plugins and session state next to its config.

### Claude Code

`install.sh` symlinks `claude/CLAUDE.md`, `claude/commands/`, `claude/hooks/` and `claude/skills/`
into `~/.claude`. It renders `claude/settings.json.template` into `~/.claude/settings.json`, replacing
`__HOME__` with your home directory and backing up the old file first. The hooks are:

- `block-outside-worktree.sh` - blocks edits to the main checkout while working in a worktree
- `herdr-agent-state.sh` - reports Claude session state to herdr (managed by herdr)
- `remote-control-keepawake.sh` - backs the `/keep-awake` and `/keep-awake-off` commands

## Configuration

### herdr

Ghostty runs [scripts/ghostty-shell](scripts/ghostty-shell), which puts Node.js and `~/.local/bin` on
`PATH` and starts `herdr --session default` in Fish. herdr's prefix is `Ctrl+b`. The Ghostty `Super`
keys send `Ctrl+b`-prefixed keys, which herdr handles. See [herdr/config.toml](herdr/config.toml).

- `Super+f` / `prefix + f` - `herdr-sessionizer`: pick a project dir with fzf, open or focus it as a workspace
- `Super+k` / `prefix + w` - command bar from the herdr-bar plugin
  (`herdr plugin install jeffarese/herdr-bar --yes`). The older `herdr-switch` popup is kept
  commented out in the config as the fallback.
- `Super+g` / `prefix + g` - Glance PR plugin, split to the right of the focused pane
- `prefix + Shift+k` - herdr's built-in goto navigator
- `Ctrl+Shift+h` / `Ctrl+Shift+l` - previous / next workspace
- `Ctrl+Shift+1-9` - jump to workspace N
- `Ctrl+Shift+j` / `Ctrl+Shift+k` - next / previous agent; `prefix + Alt+1-9` - focus agent N

`herdr-sessionizer` reads its project paths from `~/.config/tmux-sessionizer/config`, the same file
as `tmux-sessionizer`:

```bash
# Edit the config file
nvim ~/.config/tmux-sessionizer/config

# Add your project directories (one per line)
~/Work/project1
~/Work/project2
~/Incubator/experiments
```

#### Worktree functions

Fish functions for git worktrees in `<repo>/.claude/worktrees/<branch>`. Run them inside a herdr
session.

- `hw [--review] <branch> [<base>]` - create the worktree off `<base>` (default `origin/main`; if the
  branch exists on origin, it is based on `origin/<branch>`), run the repo's `.herdr/setup.sh` if
  present, then lay out nvim, claude, a shell and Glance PR
- `hw-open [--review] <branch>` - open an existing worktree with the same layout, no setup
- `hw-rm [<branch>|<path>]` - run the repo's `.herdr/teardown.sh` if present, remove the worktree and
  delete its branch (defaults to the current worktree)

`--review` lays out only claude and Glance PR, for reviewing a branch.

### Custom Keybindings

#### Ghostty
- `Super+f` - Launch herdr-sessionizer
- `Super+k` - Open the command bar
- `Super+g` - Open Glance PR
- `Super+t` - New tab
- `Super+n` - Split vertically
- `Super+Shift+n` - Split horizontally
- `Super+w` - Close pane
- `Super+z` - Zoom pane
- `Super+arrows` - Focus pane left/down/up/right
- `Super+1-9` - Switch to tab 1-9
- `Super+Shift+[` / `Super+Shift+]` - Previous / next tab
- `Super+Shift+g` / `Super+Shift+o` / `Super+Alt+d` - New / open / remove worktree

See [ghostty/config](ghostty/config) for all keybindings.

#### Tmux
Tmux is no longer started by Ghostty. Its config, TPM and `tmux-sessionizer` stay installed as a
fallback. The Ghostty `Super` keys also work inside tmux, because tmux uses the same `Ctrl+b` prefix.

- `prefix` = `Ctrl+b` (default)
- `prefix + r` - Reload tmux config
- `prefix + f` - Launch tmux-sessionizer
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

On Debian/Ubuntu, `install.sh` installs a few apt prerequisites and then uses Homebrew on Linux.
Ghostty is not installed there.

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

# Herdr reloads live if it is running; otherwise the theme applies on next launch

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
make uninstall    # Remove symlinks and, after a prompt for each, installed packages
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
