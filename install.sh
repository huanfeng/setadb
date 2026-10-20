#!/bin/sh
# setadb installer for Linux/macOS
# https://github.com/huanfeng/setadb
#
# Install or update:
#   curl -fsSL https://raw.githubusercontent.com/huanfeng/setadb/main/install.sh | sh
# Uninstall:
#   curl -fsSL https://raw.githubusercontent.com/huanfeng/setadb/main/install.sh | sh -s -- --uninstall
#
# Environment:
#   SETADB_DIR  install directory (default: ${XDG_DATA_HOME:-~/.local/share}/setadb)
#   SETADB_REF  branch or tag to download (default: main)
#   SETADB_URL  full URL of setadb.sh, overrides SETADB_REF (e.g. a mirror)
#
# Downloads setadb.sh and adds a `source` line to ~/.bashrc and/or ~/.zshrc.
# Re-running it updates setadb.sh and never duplicates the rc line.

set -eu

SETADB_DIR="${SETADB_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/setadb}"
SETADB_REF="${SETADB_REF:-main}"
URL="${SETADB_URL:-https://raw.githubusercontent.com/huanfeng/setadb/$SETADB_REF/setadb.sh}"
MARK="# setadb (https://github.com/huanfeng/setadb)"
LINE="[ -f \"$SETADB_DIR/setadb.sh\" ] && . \"$SETADB_DIR/setadb.sh\""

info() { printf '[setadb] %s\n' "$*"; }
die() { printf '[setadb] Error: %s\n' "$*" >&2; exit 1; }

# rc files to touch: the one for the login shell (created if missing), plus
# any other existing bash/zsh rc so both shells work.
rc_files() {
    case "$(basename "${SHELL:-}")" in
        zsh) printf '%s\n' "$HOME/.zshrc" ;;
        bash) printf '%s\n' "$HOME/.bashrc" ;;
    esac
    for _f in "$HOME/.zshrc" "$HOME/.bashrc"; do
        [ -f "$_f" ] && printf '%s\n' "$_f"
    done
    return 0
}

# Remove the marker line, the line right after it and the blank line that
# install() put in front of it.
strip_rc() {
    [ -f "$1" ] && grep -qxF "$MARK" "$1" || return 0
    _tmp="$1.setadb.tmp"
    awk -v m="$MARK" '
        skip         { skip = 0; next }
        $0 == m      { skip = 1; held = 0; next }
        held         { print ""; held = 0 }
        $0 == ""     { held = 1; next }
                     { print }
        END          { if (held) print "" }
    ' "$1" > "$_tmp"
    cat "$_tmp" > "$1" && rm -f "$_tmp"
    info "Removed from $1"
}

uninstall() {
    for rc in $(rc_files | sort -u); do
        strip_rc "$rc"
    done
    rm -f "$SETADB_DIR/setadb.sh"
    rmdir "$SETADB_DIR" 2>/dev/null || true
    info "Uninstalled. Open a new shell (ANDROID_SERIAL stays set in shells that are already open)."
}

download() {
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$1" -o "$2"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$2" "$1"
    else
        die "need curl or wget"
    fi
}

install() {
    mkdir -p "$SETADB_DIR"
    _tmp="$SETADB_DIR/setadb.sh.tmp"
    download "$URL" "$_tmp" || { rm -f "$_tmp"; die "download failed: $URL"; }
    grep -q '^setadb()' "$_tmp" || { rm -f "$_tmp"; die "downloaded file does not look like setadb.sh"; }
    mv -f "$_tmp" "$SETADB_DIR/setadb.sh"
    info "Installed $SETADB_DIR/setadb.sh"

    _done=""
    for rc in $(rc_files | sort -u); do
        # Rewrite instead of skipping so a changed SETADB_DIR takes effect.
        strip_rc "$rc" >/dev/null
        printf '\n%s\n%s\n' "$MARK" "$LINE" >> "$rc"
        info "Added to $rc"
        _done="$rc"
    done
    [ -n "$_done" ] || info "No bash/zsh rc found; add this line yourself:  $LINE"

    if ! command -v adb >/dev/null 2>&1; then
        info "Note: 'adb' is not in PATH yet; setadb needs it."
    fi
    printf '\n'
    info "Done. Open a new shell, or run:  . \"$SETADB_DIR/setadb.sh\""
    info "Then just run:  setadb"
}

case "${1:-}" in
    --uninstall|uninstall) uninstall ;;
    ""|--install|install) install ;;
    -h|--help) info "usage: install.sh [--uninstall]   (env: SETADB_DIR, SETADB_REF, SETADB_URL)" ;;
    *) die "unknown option: $1 (use --uninstall or nothing)" ;;
esac
