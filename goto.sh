#!/bin/sh
#set -e
#set -u
# shellcheck disable=SC3040
#set -o pipefail

_GOTO_DIR="$HOME/home"
_GOTO_MAX_DEPTH=1
_GOTO_AUTOSELECT_SINGLE_RESULT=1

# shellcheck disable=SC2034
# shellcheck disable=SC3024
# shellcheck disable=SC3001
# shellcheck disable=SC3054
# shellcheck disable=SC3018
# shellcheck disable=SC3014
# shellcheck disable=SC3005
# noinspection POSIX

__goto_full() {
    readonly __CODE_BREAK=3
    readonly __CODE_WRONG_ANSWER=5
    readonly __CODE_NO_DIR_FOUND=2
    readonly __CODE_SUCCESS=0

    if [ -z "${1:-}" ]; then
        echo "Error: no directory name provided." > /dev/srderr
        echo "Usage: goto <partial_directory_name>"
        return 1
    fi

    _search_dir="${1:-}"
    echo "Looking for ${_search_dir}..."
    _selected_dir=""

    __goto_find_dirs() {
        find -L "${_GOTO_DIR}" -maxdepth "${_GOTO_MAX_DEPTH:-1}" \
            \( -type d -o -type l -exec test -d {} \; \) \
            -iname "*${_search_dir}*" -print 2>/dev/null
    }

    _choice=0
    _matches=()
    while IFS='' read -r line; do _matches+=("${line}"); done < <(__goto_find_dirs "${_search_dir}")

    __goto_base_match() {
        case ${#_matches[@]} in
            0)
                echo "No directories found matching '*${_search_dir}*' in ${_GOTO_DIR}"
                return 1
                ;;
            1)
                # Exactly one match - go there directly
                _selected_dir=$(echo "${_matches[*]}" | head -n1)
                echo "Found: ${_selected_dir#$_GOTO_DIR/}"
                cd "${_selected_dir}" || return 1
                ;;
            *)
                # Multiple _matches - show selector
                echo "Multiple directories found matching '*${_search_dir}*':"
                echo

                while true; do
                    __goto_base_list_matches_and_choose
                    __goto_base_check_choice && break || \
                      [ $? == ${__CODE_BREAK} ] && return ${__CODE_BREAK}
                done

                export _selected_dir=${_matches[$((_choice -1))]}
                ;;
        esac

    }

    __goto_base_list_matches_and_choose() {
        for ((i = 0; i < ${#_matches[@]}; i++)); do
            printf "%2d) %s\n" "$((i + 1))" "${_matches[i]#${_GOTO_DIR}/}"
        done

        echo
        printf "Enter number (1-%d), or press Enter to cancel: " "${#_matches[@]}"
        read -r _choice
        export _choice
    }

    __goto_base_check_choice() {
        if [ -z "${_choice}" ]; then
            echo "Cancelled."
            return ${__CODE_BREAK}
        fi

        if ! echo "${_choice}" | grep -qE '^[0-9]+$'; then
            echo "Invalid input. Please enter a number." > /dev/stderr
            return ${__CODE_WRONG_ANSWER}
        fi

        if [ "${_choice}" -lt 1 ] || [ "${_choice}" -gt "${#_matches[@]}" ]; then
            echo "Invalid _choice. Please enter a number between 1 and ${#_matches[@]}." > /dev/stderr
            return ${__CODE_WRONG_ANSWER}
        fi
    }

    __goto_fzf_match() {
        _selected_dir=$(printf "%s\n" "${_matches[@]}" | \
                   fzf --prompt="Select directory: " \
                       --height=40% \
                       --reverse \
                       --preview="ls -la {}" \
                       --preview-window=right:50%)
        export _selected_dir
    }

    __goto_change_dir() {
        echo "Going to '${_selected_dir}'..."
        cd "${_selected_dir}" || return ${__CODE_NO_DIR_FOUND}
    }

    if [ "${_GOTO_AUTOSELECT_SINGLE_RESULT}" == "1" ] && [ "${#_matches[@]}" == "1" ]; then
        _selected_dir=${_matches[0]}
        __goto_change_dir || return $?
        return
    fi

    if command -v fzf >/dev/null 2>&1; then
        while true; do
            __goto_fzf_match && break || return $?
        done
    else
        __goto_base_match || return $?
    fi

    if [ -z "${_selected_dir}" ]; then
        echo "Cancelled." > /dev/stderr
        return ${__CODE_BREAK}
    fi

    __goto_change_dir || return $?
}

goto() {
    __goto_full "${@}"
}

__goto_install() {
    echo "Including goto into your .bashrc file..."
    
}

# Add aliases within.bashrc/.zshrc files
case "$0" in
    *bashrc|*zshrc)
        alias gt='goto'
        ;;
    goto|goto.sh)
        echo "Testing mode."
        echo "For actual usage, run: "
        echo "  $ source ./goto.sh"
        echo "And use it:"
        echo "  $ goto mydir"
        __goto_full "${@}"
        ;;
esac