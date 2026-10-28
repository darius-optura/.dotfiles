function _rw_layout --description 'Open a Rex session for a worktree: nvim + claude + glance + shell'
    # args: [--review] <worktree-dir> <branch>
    # Layout:  nvim (top-left) | claude (top-right) | glance
    #          ------ shell (bottom) ------------------ |  (PR)
    # --review: claude (full height) | glance (PR)
    argparse review -- $argv; or return 1
    set -l dir $argv[1]
    set -l branch $argv[2]

    # Panes start as `fish -C CMD`: fish runs CMD once its config has loaded and
    # stays an interactive shell after CMD exits. Typing the command in with
    # `rex send` raced the shell's startup and was lost in slow repos.
    set -l first 'nvim .'
    set -q _flag_review; and set first claude

    # The window label keeps the branch after Claude renames the session (see
    # _rw_session).
    set -l session (rex new $branch --window $branch --cwd $dir --json -- fish -C $first | jq -r '.session_id // empty')
    set -l root (rex session inspect $session --json | jq -r '.windows[0].focused_block_id // empty')
    if test -z "$session" -o -z "$root"
        echo "_rw_layout: could not create the Rex session" >&2
        return 1
    end
    # Label the root block after what it runs. Tools find the agent by the
    # `claude` label (occam bench hands reviews to it), in both layouts.
    set -l root_label nvim
    set -q _flag_review; and set root_label claude
    rex block rename -s $session $root $root_label >/dev/null

    # Right column, full height: Glance PR. Split first, so the later down-split
    # of root spans only the left part. --ratio is the NEW block's share.
    rex split -s $session -b $root --split right --ratio 26 --cwd $dir --label glance --focus=false -- herdr-pr-glance view --cwd $dir >/dev/null

    if not set -q _flag_review
        # Bottom: plain shell (~1/4 height) for git, tests and the dev server.
        rex split -s $session -b $root --split below --ratio 25 --cwd $dir --label dev --focus=false >/dev/null
        # Top-right: claude (~40% of the top row). Root keeps nvim.
        rex split -s $session -b $root --split right --ratio 40 --cwd $dir --label claude --focus=false -- fish -C claude >/dev/null
    end

    rex focus -s $session $root
    # Bringing the session to the front is an app action: it needs Remote
    # Control on in Rex > Settings > Rex Server.
    rex do session.select session_id=$session >/dev/null 2>&1
    or echo "_rw_layout: session '$branch' is ready; turn on Remote Control to switch to it automatically" >&2
    return 0
end
