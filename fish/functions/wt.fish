function wt --description 'Create a git worktree off origin/main, bootstrap it, open it in Zed'
    argparse 'no-open' 'no-setup' 'h/help' -- $argv
    or return 1

    if set -q _flag_help; or test (count $argv) -ne 1
        echo "usage: wt <branch-name> [--no-open] [--no-setup]"
        echo "  branch is cut from origin/main; the worktree lands in"
        echo "  <repo>/.claude/worktrees/<branch-name>"
        test -n "$_flag_help"; and return 0; or return 1
    end

    set -l branch $argv[1]

    set -l common (git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    if test -z "$common"
        echo "wt: not inside a git repository" >&2
        return 1
    end
    set -l main (path dirname $common)
    set -l dir "$main/.claude/worktrees/$branch"

    if test -e $dir
        echo "wt: $dir already exists" >&2
        return 1
    end

    git -C $main fetch origin main --quiet; or return 1
    git -C $main worktree add --no-track -b $branch $dir origin/main; or return 1
    # Keep `git worktree prune` from reaping a branch whose checkout is idle.
    git -C $main worktree lock $dir 2>/dev/null

    if not set -q _flag_no_setup
        set -l setup "$main/.zed/worktree-setup.sh"
        if test -x $setup
            $setup $dir $main; or return 1
        else
            echo "wt: no .zed/worktree-setup.sh in $main — skipping bootstrap" >&2
        end
    end

    if not set -q _flag_no_open
        _wt_zed -n $dir
    end

    echo "wt: $branch -> $dir"
end

function _wt_zed --description 'Run the Zed CLI wherever it lives'
    if command -q zed
        command zed $argv
    else if test -x /Applications/Zed.app/Contents/MacOS/cli
        /Applications/Zed.app/Contents/MacOS/cli $argv
    else
        echo "wt: no zed CLI found (run 'zed: install cli' from Zed's palette)" >&2
        return 1
    end
end
