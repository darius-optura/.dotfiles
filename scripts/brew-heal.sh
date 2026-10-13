#!/usr/bin/env bash
# Detect and repair Homebrew problems that break `brew upgrade`, mostly on
# Intel Macs where Homebrew no longer ships bottles and builds from source.
#
#   brew-heal.sh          fix what is safe; ask before sudo (only with a TTY)
#   brew-heal.sh --check  report only, change nothing
#
# Every fix here was needed by hand at least once:
#   - stale libc++ headers from an old Command Line Tools install shadow the
#     SDK's, so every C++ source build fails with "'vector' file not found"
#   - unlinked kegs (a killed upgrade, or python.org Python owning
#     /usr/local/bin/python3) leave formulae like pip missing for later builds
#   - root-owned directories inside the prefix make `brew link` fail
#   - a tmux upgrade leaves the running server on the old version

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

CHECK_ONLY=false
[[ "$1" == "--check" ]] && CHECK_ONLY=true

if ! command -v brew >/dev/null 2>&1; then
    print_warning "brew not found, skipping Homebrew health checks"
    exit 0
fi

PROBLEMS=0

# Run a sudo fix: ask first, and only when a human can answer.
sudo_fix() {
    local description="$1"
    shift
    PROBLEMS=$((PROBLEMS + 1))
    if [[ "$CHECK_ONLY" == true ]]; then
        print_warning "$description"
        echo "    fix: sudo $*"
        return
    fi
    if [[ ! -t 0 ]]; then
        print_warning "$description (needs sudo, no terminal)"
        echo "    run: sudo $*"
        return
    fi
    local response
    read -rp "$(echo -e "${YELLOW}!${NC} $description. Fix with sudo? [Y/n] ")" response
    if [[ "${response:-y}" =~ ^[Yy]$ ]]; then
        sudo "$@" && print_success "Fixed: $description"
    else
        echo "    skipped; run later: sudo $*"
    fi
}

# --- Stale Command Line Tools libc++ headers --------------------------------
check_clt_headers() {
    [[ "$(uname -s)" == "Darwin" ]] || return 0
    local clt=/Library/Developer/CommandLineTools
    local stale="$clt/usr/include/c++"
    local sdk
    sdk=$(xcrun --show-sdk-path 2>/dev/null) || return 0

    # Modern CLTs ship libc++ only inside the SDK. A toolchain copy without
    # <vector> is a leftover that clang searches first.
    if [[ -d "$stale/v1" && ! -e "$stale/v1/vector" && -e "$sdk/usr/include/c++/v1/vector" ]]; then
        sudo_fix "Stale libc++ headers in $stale break C++ builds" \
            mv "$stale" "$stale.stale-$(date +%Y%m%d)"
    fi
}

# --- brew doctor: unlinked kegs and unwritable directories -------------------
check_doctor() {
    local doctor
    doctor=$(brew doctor 2>&1 || true)

    # Unlinked kegs: the list follows "Run `brew link` on these:", indented.
    local kegs
    kegs=$(awk '/Run `brew link` on these:/ { grab=1; next } grab && /^  [^ ]/ { print $1; next } grab { grab=0 }' <<< "$doctor")
    local keg
    for keg in $kegs; do
        PROBLEMS=$((PROBLEMS + 1))
        if [[ "$CHECK_ONLY" == true ]]; then
            print_warning "Unlinked keg: $keg (fix: brew link $keg)"
            continue
        fi
        local link_output
        if link_output=$(brew link "$keg" 2>&1); then
            print_success "Linked $keg"
            continue
        fi
        # A root-owned directory deep in the prefix (brew doctor only checks
        # the top level), e.g. lib/pkcs11 created by smart-card drivers.
        local blocked
        blocked=$(sed -n 's|^\(/.*\) is not writable\.$|\1|p' <<< "$link_output" | head -1)
        if [[ -n "$blocked" ]]; then
            sudo_fix "$blocked is not writable, brew cannot link $keg" \
                chown "$(whoami):admin" "$blocked"
            if [[ -w "$blocked" ]] && brew link "$keg" >/dev/null 2>&1; then
                print_success "Linked $keg"
            fi
            continue
        fi
        # Overwrite only when every conflict is a python.org framework link.
        local conflicts
        conflicts=$(brew link --overwrite --dry-run "$keg" 2>/dev/null | awk '/^Would remove:/ { grab=1; next } grab && /->/ { print $3 }')
        if [[ -n "$conflicts" ]] && ! grep -qv '/Library/Frameworks/Python.framework/' <<< "$conflicts"; then
            brew link --overwrite "$keg" >/dev/null && print_success "Linked $keg (replaced python.org links)"
        else
            print_error "Could not link $keg; run: brew link --overwrite --dry-run $keg"
        fi
    done

    # Unwritable directories: one absolute path per line after the warning.
    local dirs
    dirs=$(awk '/directories are not writable by your user/ { grab=1; next } grab && /^\// { print; next } grab && NF { grab=0 }' <<< "$doctor")
    local dir
    for dir in $dirs; do
        # Change the directory only, so root-owned entries inside (for example
        # smart-card drivers in lib/pkcs11) keep their owner.
        sudo_fix "$dir is not writable, brew cannot link into it" \
            chown "$(whoami):admin" "$dir"
    done
}

# --- tmux server older than the tmux binary ----------------------------------
check_tmux_server() {
    command -v tmux >/dev/null 2>&1 || return 0
    tmux list-sessions >/dev/null 2>&1 || return 0
    local client server
    client=$(tmux -V | awk '{ print $2 }')
    server=$(tmux display-message -p '#{version}' 2>/dev/null || echo "unknown")
    if [[ "$server" != "$client" ]]; then
        PROBLEMS=$((PROBLEMS + 1))
        print_warning "tmux server runs $server, binary is $client. Restart it when convenient: tmux kill-server"
    fi
}

print_info "Checking Homebrew health..."
check_clt_headers
check_doctor
check_tmux_server

if [[ $PROBLEMS -eq 0 ]]; then
    print_success "Homebrew health OK"
fi
