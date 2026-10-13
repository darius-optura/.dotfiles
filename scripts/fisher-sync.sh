#!/usr/bin/env bash
# Sync fish plugins with fish/fish_plugins (the only plugin state in git).
#
# fisher keeps its own record of installed plugins in fish_variables, which
# is per machine. When plugin files exist on disk but fisher did not install
# them (an old checkout that tracked them, an interrupted run), fisher refuses
# with "conflicting files". Those files are downloadable copies, so remove
# them and sync again.
#
# stdin is closed on every fisher call: without a TTY, fisher reads plugin
# names from stdin and would treat whatever is piped in as the plugin list.

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}!${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

FISHER_URL="https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish"
FISH_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/fish"
PLUGINS_FILE="$FISH_CONFIG/fish_plugins"

if ! command -v fish >/dev/null 2>&1; then
    print_warning "fish not found, skipping fish plugins"
    exit 0
fi

if [[ ! -f "$PLUGINS_FILE" ]]; then
    print_error "$PLUGINS_FILE not found"
    exit 1
fi

# fisher rewrites fish_plugins after every run and drops plugins that failed,
# so keep the committed list and put it back.
wanted=$(cat "$PLUGINS_FILE")

fisher_update() {
    fish -c "type -q fisher; or curl -fsSL $FISHER_URL | source; and fisher update" </dev/null 2>&1
}

print_info "Syncing fish plugins..."
output=$(fisher_update) || true

conflicts=$(awk '/please remove or move conflicting files first/ { grab=1; next } grab && /^ +\// { sub(/^ +/, ""); print; next } { grab=0 }' <<< "$output")

if [[ -n "$conflicts" ]]; then
    print_warning "Replacing plugin files fisher did not install"
    while IFS= read -r path; do
        # Only ever delete inside the fish config directory.
        case "$path" in
            "$FISH_CONFIG"/*) rm -rf "$path" ;;
            *) print_error "Refusing to remove $path" ;;
        esac
    done <<< "$conflicts"
    echo "$wanted" > "$PLUGINS_FILE"
    output=$(fisher_update) || true
fi

echo "$output" | grep -v -E '^ +/' || true

# Keep the committed order so the repo stays clean.
if [[ "$(sort "$PLUGINS_FILE")" == "$(sort <<< "$wanted")" ]]; then
    echo "$wanted" > "$PLUGINS_FILE"
    print_success "Fish plugins in sync: $(tr '\n' ' ' <<< "$wanted")"
else
    print_error "fisher could not install every plugin; fish_plugins now lists:"
    cat "$PLUGINS_FILE"
    echo "$wanted" > "$PLUGINS_FILE"
    exit 1
fi
