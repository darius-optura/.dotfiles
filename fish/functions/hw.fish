function hw --description 'herdr worktree: create off a base ref, bootstrap, lay out nvim+claude+shell'
    # Usage: hw <branch> [<base>]
    # Creates <repo>/.claude/worktrees/<branch> off <base> (default origin/main),
    # runs the repo's .herdr/setup.sh if present, then builds a 3-pane workspace
    # via the herdr socket API:
    # nvim (root, left) | claude (top-right) | codex (bottom-right).
    #
    # NOTE: run this from inside a herdr session (a herdr server must be running).
    # The .result JSON field names below match herdr 0.8.2's API schema; if a
    # future version changes them, adjust the jq paths.
    if test (count $argv) -lt 1 -o (count $argv) -gt 2
        echo "usage: hw <branch> [<base>]" >&2
        return 1
    end
    set -l branch $argv[1]
    set -l base origin/main
    if test (count $argv) -eq 2
        set base $argv[2]
    end

    set -l common (git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    if test -z "$common"
        echo "hw: not inside a git repository" >&2
        return 1
    end
    set -l main (path dirname $common)
    set -l dir "$main/.claude/worktrees/$branch"
    if test -e $dir
        echo "hw: $dir already exists" >&2
        return 1
    end

    # Only the default base needs a fetch; an explicit base (a SHA the caller
    # already fetched, or any local ref) is used as given.
    if test "$base" = origin/main
        git -C $main fetch origin main --quiet; or return 1
        # Branch already on the remote: base on it instead. git then sets the
        # upstream to origin/<branch> and the checkout carries its commits, so
        # no post-create pull is needed.
        if git -C $main ls-remote --exit-code --heads origin $branch >/dev/null 2>&1
            git -C $main fetch origin $branch --quiet; or return 1
            set base origin/$branch
            echo "hw: $branch exists on origin, basing on origin/$branch"
        end
    end

    # 1. Create and open the worktree workspace. Capture the root pane id.
    set -l created (herdr worktree create --path $dir --branch $branch --base $base --no-focus)
    if test $status -ne 0
        echo "hw: herdr worktree create failed" >&2
        return 1
    end
    set -l root (echo $created | jq -r '.result.root_pane.pane_id')
    if test -z "$root" -o "$root" = null
        echo "hw: could not read root pane id from herdr response" >&2
        echo $created >&2
        return 1
    end

    # 2. Bootstrap (repo-owned, optional). Runs synchronously before agents start.
    if test -x "$main/.herdr/setup.sh"
        "$main/.herdr/setup.sh" $dir $branch; or return 1
    end

    # 3. Layout: nvim (top-left) + claude (top-right) + shell (bottom).
    _hw_layout $root $dir $branch

    echo "hw: $branch -> $dir"
end
