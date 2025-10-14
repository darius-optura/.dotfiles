# Dot Files

## Dependencies

* [Homebrew](https://brew.sh)
* [Ghostty](https://ghostty.org/)
* [Fish Shell](https://fishshell.com/)
* [Tmux](https://github.com/tmux/tmux)
* [NeoVim](https://neovim.io/)
* [Starship](https://starship.rs/)

## Instalation steps

Assuming you already have `homebrew` installed we can proceed with the instalation steps.

### Install packages

```bash
brew install fish tmux neovim bat starship fd ripgrep fzf git-delta zoxide eza go lazygit orbstack luarocks
```

```bash
brew install --cask ghostty
```

```bash
brew tap homebrew/cask-fonts && brew install --cask font-hack-nerd-font
```

### Clone repo in `~/.dotfiles`

```bash
git clone --recursive git@github.com:cupsadarius/dotfiles.git ~/.dotfiles
```

### Symlink config files to `~/.config`

```bash
cd ~/.config

ln -s $HOME/.dotfiles/ghostty ./ghostty
ln -s $HOME/.dotfiles/fish ./fish
ln -s $HOME/.dotfiles/nvim ./nvim
ln -s $HOME/.dotfiles/starship ./starship
ln -s $HOME/.dotfiles/tmux ./tmux
ln -s $HOME/.dotfiles/bat ./bat
ln -s $HOME/.dotfiles/lazygit ./lazygit
```

### Symlink tmux sessionzier to `~/.local/bin`

```bash
cd ~/.local/bin

ln -s $HOME/.dotfiles/bin/tmux-sessionizer ./tmux-sessionizer
ln -s $HOME/.dotfiles/bin/tmux-windowizer ./tmux-windowizer
```

### Install [oh-my-fish](https://github.com/oh-my-fish/oh-my-fish)

```bash
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
```

### Install [fisher](https://github.com/jorgebucaran/fisher)

```bash
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
```

### Install `fish shell` dependencies

```bash
fisher install jorgebucaran/nvm.fish

```

### Install [tmux plugin manager](https://github.com/tmux-plugins/tpm)

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### Update bat theme cache
```bash
bat cache --build
```
