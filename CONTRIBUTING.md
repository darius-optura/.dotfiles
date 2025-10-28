# Contributing Guide

Thank you for your interest in customizing or contributing to these dotfiles!

## For Personal Use

Feel free to fork this repository and customize it for your own needs. Here are some common customizations:

### Adding New Packages

1. Install the package via Homebrew:
   ```bash
   brew install your-package
   ```

2. Add it to `PACKAGES.md` for documentation

3. Update `install.sh` to include it in the package array:
   ```bash
   local packages=(
       # ... existing packages
       "your-package"
   )
   ```

### Customizing Fish Shell

Edit `fish/config.fish` to add:
- Custom aliases
- Environment variables
- Functions

Your custom functions go in `fish/functions/`:
```bash
# fish/functions/myfunction.fish
function myfunction
    echo "Hello from my function"
end
```

### Customizing Neovim

The Neovim configuration uses lazy.nvim. Add plugins in `nvim/lua/plugins/`:

```lua
-- nvim/lua/plugins/myplugin.lua
return {
  "author/plugin-name",
  config = function()
    -- Plugin configuration
  end
}
```

### Customizing Tmux

Edit `tmux/tmux.conf` for:
- Keybindings
- Status bar configuration
- Plugin settings

### Adding New Keybindings

#### Ghostty
Edit `ghostty/config`:
```conf
keybind = super+your_key=text:\x02your_command
```

#### Tmux
Edit `tmux/tmux.conf`:
```tmux
bind-key your_key your_command
```

### Adding Custom Scripts

1. Create your script in `bin/`:
   ```bash
   touch bin/myscript
   chmod +x bin/myscript
   ```

2. Update `install.sh` to symlink it:
   ```bash
   ln -sf "$DOTFILES_DIR/bin/myscript" "$LOCAL_BIN_DIR/myscript"
   ```

### Modifying Theme Switcher

To add a new theme, edit `scripts/switch-theme.sh`:

1. Add theme to `normalize_theme()` function
2. Add theme cases to each `update_*_theme()` function
3. Create theme files in respective config directories
4. Document in `themes/README.md`

See [themes/README.md](themes/README.md) for detailed instructions.

## For Contributing Back

If you've made improvements that might benefit others, consider contributing:

### Before Contributing

1. **Test thoroughly** - Ensure your changes work on both Intel and Apple Silicon Macs
2. **Document** - Update relevant documentation
3. **Follow conventions** - Match existing code style
4. **Keep it focused** - One improvement per pull request

### Contribution Process

1. **Fork the repository**
   ```bash
   # On GitHub, click "Fork"
   git clone https://github.com/YOUR-USERNAME/dotfiles.git
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the existing structure
   - Test on a clean installation if possible
   - Update documentation

4. **Test your changes**
   ```bash
   make check    # Verify installation
   make install  # Test full installation
   ```

5. **Commit with clear messages**
   ```bash
   git add .
   git commit -m "Add feature: brief description"
   ```

6. **Push and create Pull Request**
   ```bash
   git push origin feature/your-feature-name
   # Create PR on GitHub
   ```

### What to Contribute

Welcome contributions:
- **Bug fixes** - Fix issues with installation or configuration
- **New themes** - Add support for additional themes
- **Documentation** - Improve or clarify documentation
- **Compatibility** - Improve cross-platform compatibility
- **Performance** - Optimize scripts or configurations
- **Features** - Add useful new features that benefit most users

Not recommended:
- Highly personal preferences
- Breaking changes without discussion
- Unnecessary dependencies
- Large, unfocused changes

### Code Style

#### Shell Scripts
- Use `#!/usr/bin/env bash` shebang
- Include error handling with `set -e`
- Use functions for logical grouping
- Add comments for complex logic
- Use colored output for user feedback

#### Configuration Files
- Follow the `.editorconfig` settings
- Use consistent indentation (2 spaces for most files)
- Add comments explaining non-obvious settings
- Group related settings together

#### Documentation
- Use clear, concise language
- Include code examples where helpful
- Keep formatting consistent with existing docs
- Update table of contents if adding sections

### Testing Checklist

Before submitting a PR, verify:
- [ ] Works on macOS (Intel and/or Apple Silicon)
- [ ] Fresh installation completes without errors
- [ ] `make check` passes
- [ ] All symlinks created correctly
- [ ] Documentation updated
- [ ] No hardcoded personal paths or data
- [ ] Scripts are executable (`chmod +x`)
- [ ] No sensitive information committed

### Getting Help

Questions or need help?
- Check existing documentation
- Review closed issues on GitHub
- Open a discussion on GitHub
- Comment on related issues

## Development Tips

### Testing Without Installing

Test individual scripts:
```bash
# Test theme switcher
bash -n scripts/switch-theme.sh  # Syntax check
bash scripts/switch-theme.sh catppuccin  # Dry run
```

### Debugging Installation

Add debug output:
```bash
set -x  # Enable debug mode
# Your commands here
set +x  # Disable debug mode
```

### Local Testing

Create a test environment:
```bash
# Use a Docker container or VM
# Or test on a separate user account
```

## Questions?

Feel free to open an issue for:
- Feature requests
- Bug reports
- Documentation improvements
- General questions

Thank you for contributing to making these dotfiles better!

## License

By contributing, you agree that your contributions will be licensed under the same license as this project (personal use, open source).
