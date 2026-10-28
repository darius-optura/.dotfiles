function _rw_session --description 'Print the id of the Rex session _rw_layout opened for a branch'
    # args: <branch>
    # _rw_layout labels the session AND its first window (tab) after the branch.
    # Claude renames the session for its task, so the window label is the one
    # that lasts; the session label still matches before that rename.
    set -l branch $argv[1]
    for s in (rex ls --json | jq -r '.sessions[].session_id')
        if rex session inspect $s --json 2>/dev/null | jq -e --arg n $branch '.label == $n or any(.windows[]; .label == $n)' >/dev/null
            echo $s
            return 0
        end
    end
    return 1
end
