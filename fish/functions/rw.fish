function rw --description 'Rex worktree: create off a base ref, bootstrap, open a Rex session'
    # Usage: rw [--review] <branch> [<base>]
    # Rex port of hw. Creates <repo>/.claude/worktrees/<branch> off <base>
    # (default origin/main), runs the repo's .herdr/setup.sh if present, then
    # opens a Rex session named after the branch (see _rw_layout).
    # --review lays out only claude | glance (PR), for reviewing a branch.
    argparse review -- $argv; or return 1
    if test (count $argv) -lt 1 -o (count $argv) -gt 2
        echo "usage: rw [--review] <branch> [<base>]" >&2
        return 1
    end
    if not command -q rex
        echo "rw: rex not found; run this inside Rex" >&2
        return 1
    end
    set -l branch $argv[1]
    set -l base origin/main
    if test (count $argv) -eq 2
        set base $argv[2]
    end

    set -l common (git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    if test -z "$common"
        echo "rw: not inside a git repository" >&2
        return 1
    end
    set -l main (path dirname $common)
    set -l dir "$main/.claude/worktrees/$branch"
    if test -e $dir
        echo "rw: $dir already exists" >&2
        return 1
    end

    # Only the default base needs a fetch; an explicit base (a SHA the caller
    # already fetched, or any local ref) is used as given.
    if test "$base" = origin/main
        git -C $main fetch origin main --quiet; or return 1
        # Branch already on the remote: base on it instead, so the checkout
        # carries its commits and tracks origin/<branch>.
        if git -C $main ls-remote --exit-code --heads origin $branch >/dev/null 2>&1
            git -C $main fetch origin $branch --quiet; or return 1
            set base origin/$branch
            echo "rw: $branch exists on origin, basing on origin/$branch"
        end
    end

    # 1. Create the worktree. A local branch is checked out as it is. A new one
    # tracks origin/<branch> when based on it, and nothing otherwise, so the
    # first push does not target the base branch.
    if git -C $main show-ref --verify --quiet refs/heads/$branch
        git -C $main worktree add $dir $branch; or return 1
    else if test "$base" = origin/$branch
        git -C $main worktree add -b $branch $dir $base; or return 1
    else
        git -C $main worktree add --no-track -b $branch $dir $base; or return 1
    end

    # 2. Bootstrap (repo-owned, optional). Runs synchronously before agents start.
    if test -x "$main/.herdr/setup.sh"
        "$main/.herdr/setup.sh" $dir $branch; or return 1
    end

    # 3. Rex session: nvim + claude + shell + glance, or claude + glance.
    set -l layout
    set -q _flag_review; and set layout --review
    _rw_layout $layout $dir $branch; or return 1

    echo "rw: $branch -> $dir"
end
