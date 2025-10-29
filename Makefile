.PHONY: help install update backup restore uninstall theme check

# Default theme
THEME ?= catppuccin

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Run full installation
	@echo "Starting dotfiles installation..."
	@bash install.sh

update: ## Update all plugins and submodules
	@echo "Updating Homebrew..."
	@brew update
	@echo ""
	@echo "Upgrading Homebrew packages..."
	@brew upgrade
	@echo ""
	@echo "Updating Git submodules..."
	@git submodule update --remote --merge
	@echo "Updating TPM plugins..."
	@if [ -d "$$HOME/.tmux/plugins/tpm" ]; then \
		$$HOME/.tmux/plugins/tpm/bin/update_plugins all; \
	else \
		echo "TPM not installed. Run 'make install' first."; \
	fi
	@echo "Updating Fish plugins..."
	@fish -c "fisher update" 2>/dev/null || echo "Fisher not installed"
	@echo "Updating Neovim plugins..."
	@nvim --headless "+Lazy! sync" +qa 2>/dev/null || echo "Neovim plugins update skipped"
	@echo "Updating Mason LSP servers..."
	@nvim --headless "+MasonUpdate" +qa 2>/dev/null || echo "Mason update skipped"
	@echo "Updating Treesitter parsers..."
	@nvim --headless "+TSUpdate" +qa 2>/dev/null || echo "Treesitter update skipped"
	@echo "Rebuilding bat cache..."
	@bat cache --build
	@echo ""
	@echo "✓ All updates complete!"
	@echo ""
	@echo "Run 'brew cleanup' to remove old versions (optional)"

backup: ## Backup current configurations
	@echo "Creating backup..."
	@BACKUP_DIR="$$HOME/.dotfiles-backup-$$(date +%Y%m%d-%H%M%S)"; \
	mkdir -p "$$BACKUP_DIR"; \
	for config in ghostty fish nvim starship tmux bat lazygit alacritty kitty tmux-sessionizer; do \
		if [ -e "$$HOME/.config/$$config" ] && [ ! -L "$$HOME/.config/$$config" ]; then \
			cp -r "$$HOME/.config/$$config" "$$BACKUP_DIR/"; \
			echo "  Backed up $$config"; \
		fi; \
	done; \
	if [ -e "$$HOME/.local/bin/tmux-sessionizer" ] && [ ! -L "$$HOME/.local/bin/tmux-sessionizer" ]; then \
		mkdir -p "$$BACKUP_DIR/bin"; \
		cp "$$HOME/.local/bin/tmux-sessionizer" "$$BACKUP_DIR/bin/"; \
		cp "$$HOME/.local/bin/tmux-windowizer" "$$BACKUP_DIR/bin/" 2>/dev/null || true; \
		echo "  Backed up bin scripts"; \
	fi; \
	echo "✓ Backup saved to $$BACKUP_DIR"

restore: ## Restore from latest backup
	@LATEST_BACKUP=$$(ls -dt $$HOME/.dotfiles-backup-* 2>/dev/null | head -1); \
	if [ -z "$$LATEST_BACKUP" ]; then \
		echo "✗ No backup found"; \
		exit 1; \
	fi; \
	echo "Restoring from $$LATEST_BACKUP..."; \
	for config in ghostty fish nvim starship tmux bat lazygit alacritty kitty tmux-sessionizer; do \
		if [ -d "$$LATEST_BACKUP/$$config" ]; then \
			rm -rf "$$HOME/.config/$$config"; \
			cp -r "$$LATEST_BACKUP/$$config" "$$HOME/.config/"; \
			echo "  Restored $$config"; \
		fi; \
	done; \
	if [ -d "$$LATEST_BACKUP/bin" ]; then \
		cp "$$LATEST_BACKUP/bin/"* "$$HOME/.local/bin/" 2>/dev/null || true; \
		echo "  Restored bin scripts"; \
	fi; \
	echo "✓ Restore complete"

uninstall: ## Remove all symlinks and restore backups
	@echo "Uninstalling dotfiles..."
	@for config in ghostty fish nvim starship tmux bat lazygit alacritty kitty; do \
		if [ -L "$$HOME/.config/$$config" ]; then \
			rm "$$HOME/.config/$$config"; \
			echo "  Removed $$config symlink"; \
		fi; \
	done
	@if [ -L "$$HOME/.local/bin/tmux-sessionizer" ]; then \
		rm "$$HOME/.local/bin/tmux-sessionizer"; \
		echo "  Removed tmux-sessionizer symlink"; \
	fi
	@if [ -L "$$HOME/.local/bin/tmux-windowizer" ]; then \
		rm "$$HOME/.local/bin/tmux-windowizer"; \
		echo "  Removed tmux-windowizer symlink"; \
	fi
	@echo "✓ Uninstall complete"
	@echo ""
	@echo "To restore your previous configs, run: make restore"

theme: ## Switch theme (Usage: make theme THEME=catppuccin|rose-pine|gruvbox)
	@if [ ! -f "scripts/switch-theme.sh" ]; then \
		echo "✗ Theme switcher not found. Please ensure scripts/switch-theme.sh exists"; \
		exit 1; \
	fi
	@bash scripts/switch-theme.sh $(THEME)

check: ## Verify installation health
	@echo "Checking dotfiles installation..."
	@echo ""
	@echo "Required Commands:"
	@for cmd in fish tmux nvim bat starship fd rg fzf delta zoxide eza lazygit; do \
		if command -v $$cmd >/dev/null 2>&1; then \
			echo "  ✓ $$cmd"; \
		else \
			echo "  ✗ $$cmd (missing)"; \
		fi; \
	done
	@echo ""
	@echo "Configuration Symlinks:"
	@for config in ghostty fish nvim starship tmux bat lazygit; do \
		if [ -L "$$HOME/.config/$$config" ]; then \
			echo "  ✓ $$config"; \
		else \
			echo "  ✗ $$config (not symlinked)"; \
		fi; \
	done
	@echo ""
	@echo "Bin Scripts:"
	@for script in tmux-sessionizer tmux-windowizer; do \
		if [ -L "$$HOME/.local/bin/$$script" ]; then \
			echo "  ✓ $$script"; \
		else \
			echo "  ✗ $$script (not symlinked)"; \
		fi; \
	done
	@echo ""
	@echo "Plugin Managers:"
	@if [ -d "$$HOME/.local/share/omf" ]; then \
		echo "  ✓ oh-my-fish"; \
	else \
		echo "  ✗ oh-my-fish (not installed)"; \
	fi
	@if fish -c "type -q fisher" 2>/dev/null; then \
		echo "  ✓ fisher"; \
	else \
		echo "  ✗ fisher (not installed)"; \
	fi
	@if [ -d "$$HOME/.tmux/plugins/tpm" ]; then \
		echo "  ✓ TPM"; \
	else \
		echo "  ✗ TPM (not installed)"; \
	fi
	@echo ""
