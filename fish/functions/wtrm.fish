function wtrm --description 'Tear down a worktree: drop its DB, salvage docs, remove it'
    argparse 'f/force' 'h/help' -- $argv
    or return 1

    if set -q _flag_help
        echo "usage: wtrm [<branch-name>|<path>] [--force]"
        echo "  defaults to the current worktree; --force discards unmerged work"
        return 0
    end

    set -l common (git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    if test -z "$common"
        echo "wtrm: not inside a git repository" >&2
        return 1
    end
    set -l main (path dirname $common)

    set -l target
    if test (count $argv) -eq 0
        set target (git rev-parse --show-toplevel)
    else if test -d $argv[1]
        set target (path resolve $argv[1])
    else
        set target "$main/.claude/worktrees/$argv[1]"
    end

    if test (path resolve $target) = (path resolve $main)
        echo "wtrm: refusing to remove the main checkout" >&2
        return 1
    end
    if not test -d $target
        echo "wtrm: no worktree at $target" >&2
        return 1
    end

    set -l branch (git -C $target rev-parse --abbrev-ref HEAD)

    # Pull gitignored docs/ back into main before the checkout disappears.
    # salvage-docs takes the worktree path, so run it from main's node_modules.
    npx vite-node $main/scripts/worktree/salvage-docs.ts $target

    # db-drop derives the DB name from the cwd, so it must run inside the
    # worktree - which needs that worktree's own node_modules.
    if test -d $target/node_modules
        set -l here (pwd)
        cd $target
        npx vite-node scripts/worktree/db-drop.ts --force
        cd $here
    else
        echo "wtrm: no node_modules in $target - skipping DB drop" >&2
    end

    # Leave the doomed worktree before git unlinks it.
    if string match -q "$target*" (pwd)
        cd $main
    end

    git -C $main worktree unlock $target 2>/dev/null
    if set -q _flag_force
        git -C $main worktree remove --force $target; or return 1
        test "$branch" != HEAD; and git -C $main branch -D $branch
    else
        git -C $main worktree remove $target; or return 1
        test "$branch" != HEAD; and git -C $main branch -d $branch
    end

    # Nested branch names (feat/x) leave an empty parent directory behind.
    # rmdir -p walks up and stops at the first non-empty directory.
    rmdir -p (path dirname $target) 2>/dev/null

    echo "wtrm: removed $target"
end
