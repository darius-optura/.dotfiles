function set_fzf_theme
    set -l theme $argv[1]

    # Normalize theme name
    switch $theme
        case catppuccin cat mocha
            set theme catppuccin
        case rose-pine rose rosepine rose_pine
            set theme rose-pine
        case gruvbox gruvbox-dark gruvbox_dark
            set theme gruvbox
    end

    # Set FZF colors based on theme
    switch $theme
        case catppuccin
            # Catppuccin Mocha Transparent
            set -Ux FZF_DEFAULT_OPTS "\
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#313244,label:#CDD6F4"

        case rose-pine
            # Rose Pine Moon
            set -Ux FZF_DEFAULT_OPTS "\
--color=fg:#908caa,hl:#ea9a97 \
--color=fg+:#e0def4,bg+:#393552,hl+:#ea9a97 \
--color=border:#44415a,header:#3e8fb0,gutter:#232136 \
--color=spinner:#f6c177,info:#9ccfd8 \
--color=pointer:#c4a7e7,marker:#eb6f92,prompt:#908caa"

        case gruvbox
            # Gruvbox Dark Transparent
            set -Ux FZF_DEFAULT_OPTS "\
--color=fg:#bdae93,header:#83a598,info:#fabd2f,pointer:#8ec07c \
--color=marker:#8ec07c,fg+:#ebdbb2,prompt:#fabd2f,hl+:#83a598 \
--color=selected-bg:#3c3836 \
--color=border:#1d2021,label:#fabd2f"

        case '*'
            # Default to catppuccin if unknown theme
            set -Ux FZF_DEFAULT_OPTS "\
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#313244,label:#CDD6F4"
    end
end
