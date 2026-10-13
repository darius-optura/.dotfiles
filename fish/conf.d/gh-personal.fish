# Use personal gh account for repos under ~/Personal.
# Points gh at a separate config dir when cwd is inside ~/Personal.
function __gh_personal_switch --on-variable PWD
    if string match -q "$HOME/Personal*" -- $PWD
        set -gx GH_CONFIG_DIR $HOME/.config/gh-personal
    else
        set -e GH_CONFIG_DIR
    end
end

# run once for the shell's starting directory
__gh_personal_switch
