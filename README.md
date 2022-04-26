# Dot Files

## Dependencies

* [Homebrew](https://brew.sh)
* [Alacritty](https://alacritty.org/)
* [Fish Shell](https://fishshell.com/)
* [Tmux](https://github.com/tmux/tmux)
* [NeoVim](https://neovim.io/)
* [Starship](https://starship.rs/)

## Instalation steps

Assuming you already have `homebrew` installed we can proceed with the instalation steps.

### Install packages

```bash
brew install fish tmux neovim bat starship fd ripgrep fzf git-delta
```

```bash
brew install --cask alacritty
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

ln -s $HOME/.dotfiles/alacritty ./alacritty
ln -s $HOME/.dotfiles/fish ./fish
ln -s $HOME/.dotfiles/nvim ./nvim
ln -s $HOME/.dotfiles/starship ./starship
ln -s $HOME/.dotfiles/tmux ./tmux
```

### Install [oh-my-fish](https://github.com/oh-my-fish/oh-my-fish)

```bash
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
```

### Install `fish shell` dependencies

```bash
omf install z nvm
```

```bash
omf install https://github.com/catppuccin/fish
```

### Install [tmux plugin manager](https://github.com/tmux-plugins/tpm)

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### Install [neovim package manager](https://github.com/wbthomason/packer.nvim)

```bash
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim
 ```

### Install Language Servers

```bash
npm install -g typescript typescript-language-server dockerfile-language-server-nodejs vscode-langservers-extracted
```

```bash
go install golang.org/x/tools/gopls@latest
```
