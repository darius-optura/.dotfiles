function _hw_prune_parents --description 'drop the empty dirs a slash in a branch name created'
    # Usage: _hw_prune_parents <main-checkout> <worktree-path>
    # `.claude/worktrees/<owner>/<branch>` leaves an empty <owner>/ behind.
    set -l root (path resolve $argv[1])/.claude/worktrees
    set -l parent (path dirname (path resolve $argv[2]))
    while test "$parent" != "$root"; and rmdir $parent 2>/dev/null
        set parent (path dirname $parent)
    end
end
