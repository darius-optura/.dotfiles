function gsp --description 'Git: Smart Push'
    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "❌ Error: Not a git repository"
        return 1
end

    # Check if we have a commit message
    if [ -z "$1" ]; then
        echo "❌ Error: Please provide a commit message"
        echo "Usage: gp \"your commit message\""
        return 1
    fi

    # Store current branch name
    current_branch=$(git branch --show-current)

    # Show status before committing
    echo "📊 Current Status:"
    git status

    # Check if there are changes to commit
    if [ -z "$(git status --porcelain)" ]; then
        echo "❌ Error: No changes to commit"
        return 1
    fi

    # Perform git operations
    if git add . && \
       git commit -v -m "$1" && \
       git push origin "$current_branch"; then
        echo "✅ Successfully pushed to $current_branch"

        # Show last 3 commits
        echo "📜 Last 3 commits on $current_branch:"
        git log -n 3 --oneline --decorate --color

        # Show branch status
        echo "🌳 Branch Status:"
        git status -sb
    else
        echo "❌ Error: Git operation failed"
        return 1
    fi
