# setadb - select the ADB device for the current shell session
# https://github.com/huanfeng/setadb
#
# This file defines the `setadb` shell function. A function is required
# because exporting ANDROID_SERIAL from a child process would be lost the
# moment that process exits - only code running *in your shell* can change
# your shell's environment.
#
# Install (bash):  echo 'source "/path/to/setadb.sh"' >> ~/.bashrc
# Install (zsh):   echo 'source "/path/to/setadb.sh"' >> ~/.zshrc
# Then run:        setadb
#
# Tested with bash and zsh.

# Resolve this file's own path at load time. Inside a function $0 is the
# function name under zsh, so it has to be captured here at file scope.
if [ -n "${BASH_VERSION:-}" ]; then
    SETADB_SCRIPT="${BASH_SOURCE[0]}"
else
    SETADB_SCRIPT="$0"
fi
case "$SETADB_SCRIPT" in
    /*) : ;;
    *) SETADB_SCRIPT="$(cd "$(dirname "$SETADB_SCRIPT")" 2>/dev/null && pwd)/$(basename "$SETADB_SCRIPT")" ;;
esac

SETADB_VERSION="1.1.0"

_setadb_help() {
    cat <<EOF
setadb $SETADB_VERSION - select the ADB device for the current session

Usage:
  setadb                 Show the device menu and select interactively
  setadb <index>         Select the device by menu index directly
  setadb 0               Same as 'setadb clear'
  setadb clear|-c        Clear ANDROID_SERIAL
  setadb <serial>        Set ANDROID_SERIAL to the given serial
  setadb list|-l         List devices without changing anything
  setadb -s              Show the current ANDROID_SERIAL
  setadb --install       Print the lines needed to install setadb
  setadb -h              Show this help

Notes:
  setadb must run as a shell function so it can modify the current shell.
  Run 'setadb --install' if you have not set that up yet.
EOF
}

_setadb_install_hint() {
    _setadb_rc_hint "$SETADB_SCRIPT"
}

_setadb_rc_hint() {
    _sa_path="$1"
    cat <<EOF
[setadb] Add this line to your shell startup file:

    source "$_sa_path"

Copy-paste one of these, then restart the shell (or re-source the rc file):

    echo 'source "$_sa_path"' >> ~/.bashrc && source ~/.bashrc
    echo 'source "$_sa_path"' >> ~/.zshrc  && source ~/.zshrc

After that, just run:  setadb
EOF
    unset _sa_path
}

# One device per line as "serial<TAB>state". Filtering is by content, not by
# line number: adb may print "* daemon not running *" first, which would push
# the header off line 1 and let it through as a bogus device.
_setadb_list_devices() {
    adb devices 2>/dev/null | awk '
        $1 == "List" { next }
        $1 ~ /^\*/   { next }
        NF >= 2      { print $1"\t"$2 }
    '
}

# $1 = 1-based line number, $2 = device list
_setadb_nth() {
    printf '%s\n' "$2" | sed -n "$1p"
}

_setadb_menu() {
    _sa_devs="$1"
    printf 'ADB devices\n'
    printf -- '-------------------\n'
    printf '  0. [Clear]\n'
    _sa_i=1
    printf '%s\n' "$_sa_devs" | while IFS="$(printf '\t')" read -r _sa_serial _sa_state; do
        [ -z "$_sa_serial" ] && continue
        if [ "$_sa_serial" = "${ANDROID_SERIAL:-}" ]; then
            printf '* %s. [%s] %s\n' "$_sa_i" "$_sa_serial" "$_sa_state"
        else
            printf '  %s. [%s] %s\n' "$_sa_i" "$_sa_serial" "$_sa_state"
        fi
        _sa_i=$((_sa_i + 1))
    done
    printf -- '-------------------\n'
    unset _sa_devs _sa_i _sa_serial _sa_state
}

_setadb_apply() {
    if [ -z "${1:-}" ]; then
        unset ANDROID_SERIAL
        printf '[setadb] ANDROID_SERIAL cleared.\n'
    else
        export ANDROID_SERIAL="$1"
        printf '[setadb] ANDROID_SERIAL = %s\n' "$1"
    fi
}

setadb() {
    _sa_arg="${1:-}"

    case "$_sa_arg" in
        -h|--help|help)
            _setadb_help
            unset _sa_arg
            return 0
            ;;
        -v|--version)
            printf 'setadb %s\n' "$SETADB_VERSION"
            unset _sa_arg
            return 0
            ;;
        --install)
            _setadb_install_hint
            unset _sa_arg
            return 0
            ;;
        -c|clear|--clear)
            _setadb_apply ""
            unset _sa_arg
            return 0
            ;;
        -s|--show)
            if [ -n "${ANDROID_SERIAL:-}" ]; then
                printf '[setadb] ANDROID_SERIAL = %s\n' "$ANDROID_SERIAL"
            else
                printf '[setadb] ANDROID_SERIAL is not set.\n'
            fi
            unset _sa_arg
            return 0
            ;;
    esac

    if ! command -v adb >/dev/null 2>&1; then
        printf "[setadb] Error: 'adb' was not found in PATH.\n" >&2
        unset _sa_arg
        return 1
    fi

    _sa_devs="$(_setadb_list_devices)"
    _sa_count="$(printf '%s\n' "$_sa_devs" | grep -c . )"

    case "$_sa_arg" in
        -l|--list|list)
            _setadb_menu "$_sa_devs"
            unset _sa_arg _sa_devs _sa_count
            return 0
            ;;
    esac

    if [ -z "$_sa_arg" ]; then
        _setadb_menu "$_sa_devs"
        printf 'Please select: '
        read -r _sa_arg
        if [ -z "$_sa_arg" ]; then
            printf '[setadb] Cancelled, nothing changed.\n'
            unset _sa_arg _sa_devs _sa_count
            return 0
        fi
        case "$_sa_arg" in
            *[!0-9]*)
                printf '[setadb] Invalid input: %s\n' "$_sa_arg" >&2
                unset _sa_arg _sa_devs _sa_count
                return 1
                ;;
        esac
    fi

    case "$_sa_arg" in
        *[!0-9]*)
            # Not a number, treat it as a raw serial.
            if ! printf '%s\n' "$_sa_devs" | cut -f1 | grep -qx -- "$_sa_arg"; then
                printf "[setadb] Warning: '%s' is not in the device list, setting it anyway.\n" "$_sa_arg"
            fi
            _setadb_apply "$_sa_arg"
            unset _sa_arg _sa_devs _sa_count
            return 0
            ;;
    esac

    if [ "$_sa_arg" -eq 0 ] 2>/dev/null; then
        _setadb_apply ""
        unset _sa_arg _sa_devs _sa_count
        return 0
    fi

    if [ "$_sa_arg" -gt "$_sa_count" ] 2>/dev/null; then
        printf '[setadb] Index out of range: %s (valid: 0-%s)\n' "$_sa_arg" "$_sa_count" >&2
        unset _sa_arg _sa_devs _sa_count
        return 1
    fi

    _sa_sel="$(_setadb_nth "$_sa_arg" "$_sa_devs" | cut -f1)"
    _setadb_apply "$_sa_sel"
    unset _sa_arg _sa_devs _sa_count _sa_sel
    return 0
}

# Running this file instead of sourcing it can never work, so say so loudly.
_setadb_sourced=0
if [ -n "${BASH_VERSION:-}" ]; then
    [ "${BASH_SOURCE[0]}" != "$0" ] && _setadb_sourced=1
elif [ -n "${ZSH_VERSION:-}" ]; then
    case "${ZSH_EVAL_CONTEXT:-}" in *:file*) _setadb_sourced=1 ;; esac
else
    _setadb_sourced=1
fi

if [ "$_setadb_sourced" = "0" ]; then
    printf '\n'
    printf '  ############################################################\n'
    printf '  #  setadb cannot be run as a normal command.               #\n'
    printf '  ############################################################\n'
    printf '\n'
    printf '  It has to modify ANDROID_SERIAL in YOUR shell. A script run\n'
    printf '  normally gets its own process, and that process - along with\n'
    printf '  everything it exported - disappears the moment it finishes.\n'
    printf '\n'
    _setadb_rc_hint "$SETADB_SCRIPT"
    printf '\n'
    printf '  For a one-off use without installing:\n'
    printf '\n'
    printf '      source "%s" && setadb\n' "$SETADB_SCRIPT"
    printf '\n'
    unset _setadb_sourced
    exit 1
fi
unset _setadb_sourced
