function rw-open --description 'Open an existing .claude/worktrees/<branch> as a Rex session'
    # Usage: rw-open [--review] <branch>
    # Rex port of hw-open. Switches to the branch's Rex session if one is open,
    # else lays one out as `rw` does. No bootstrap: the worktree is assumed
    # already set up.
    argparse review -- $argv; or return 1
    if test (count $argv) -ne 1
        echo "usage: rw-open [--review] <branch>" >&2
        return 1
    end
    if not command -q rex
        echo "rw-open: rex not found; run this inside Rex" >&2
        return 1
    end
    set -l branch $argv[1]

    set -l common (git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    if test -z "$common"
        echo "rw-open: not inside a git repository" >&2
        return 1
    end
    set -l main (path dirname $common)
    set -l dir "$main/.claude/worktrees/$branch"
    if not test -d $dir
        echo "rw-open: no worktree at $dir" >&2
        return 1
    end

    set -l session (_rw_session $branch)
    if test -n "$session"
        rex do session.select session_id=$session
        return
    end

    set -l layout
    set -q _flag_review; and set layout --review
    _rw_layout $layout $dir $branch; or return 1
    echo "rw-open: opened $dir"
end
