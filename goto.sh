#!/bin/sh
#set -e
#set -u
# shellcheck disable=SC3040
#set -o pipefail

_GOTO_DIR="${_GOTO_DIR:-${HOME}/}"
_GOTO_MAX_DEPTH=1
_GOTO_AUTOSELECT_SINGLE_RESULT=1

_GOTO_CONFIG_DIR=${XDG_CONFIG_HOME:-${HOME}/.config}/goto-my-directory
_GOTO_CONFIG_FILE=${_GOTO_CONFIG_DIR}/config.sh


# shellcheck disable=SC2034
# shellcheck disable=SC3024
# shellcheck disable=SC3001
# shellcheck disable=SC3054
# shellcheck disable=SC3018
# shellcheck disable=SC3014
# shellcheck disable=SC3005
# noinspection POSIX

goto() {
    readonly __CODE_BREAK=3
    readonly __CODE_WRONG_ANSWER=5
    readonly __CODE_NO_DIR_FOUND=2
    readonly __CODE_ERROR=1
    readonly __CODE_SUCCESS=0

    if [ -z "${1:-}" ]; then
        echo "Error: no directory name provided." > /dev/srderr
        echo "Usage: goto <partial_directory_name>"
        echo "Lookup directory: ${_GOTO_DIR}"
        return 1
    fi

    local _search_dir="${1:-}"
    echo "Looking for ${_search_dir}..."
    local _selected_dir=""

    __goto_find_dirs() {
        find -L "${_GOTO_DIR}" -maxdepth "${_GOTO_MAX_DEPTH:-1}" \
            \( -type d -o -type l -exec test -d {} \; \) \
            -iname "*${_search_dir}*" -print 2>/dev/null | grep -v '^$'
    }

    _choice=0
    _matches=()
    while IFS='' read -r line; do _matches+=("${line}"); done < <(__goto_find_dirs "${_search_dir}")


    # __goto_base_* functions to match directory in basic approach
    # This function is used when fzf is not available or not preferred
    # It lists all found directories and allows the user to select one by number
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
                ;;
            *)
                # Multiple matches - show selector
                echo "Multiple directories found matching '*${_search_dir}*':"
                echo

                while true; do
                    __goto_base_list_matches_and_choose
                    __goto_base_check_choice && break || \
                      [ $? = ${__CODE_BREAK} ] && return ${__CODE_BREAK}
                done

                _selected_dir=${_matches[$((_choice -1))]}
                export _selected_dir
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

    # if [ "${_GOTO_AUTOSELECT_SINGLE_RESULT}" = "1" ] && [ "${#_matches[@]}" = "1" ]; then
    #     _selected_dir=${_matches[0]}
    #     __goto_change_dir || return $?
    #     return
    # fi

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

# Function to install goto into the current shell's resource file
__goto_install() {
    local rc_file="$1"
    local force_copy="$2"
    local readonly script_path="${_GOTO_CONFIG_DIR}/goto.sh"

    # Create the default config file if it doesn't exist
    __goto_create_default_config

    # Copy current script to config directory
    # TODO: Add versioning to detect when script needs updating
    local current_script="$(__goto_current_file)"
    if [ "$current_script" != "$script_path" ] && [ -f "$current_script" ]; then
        if [ "$force_copy" = "--force-copy" ] || [ ! -f "$script_path" ]; then
            echo "Copying script to ${script_path}..."
            mkdir -p "${_GOTO_CONFIG_DIR}" || {
                echo "Error: Could not create config directory ${_GOTO_CONFIG_DIR}." >&2
                return 1
            }
            cp "$current_script" "$script_path" || {
                echo "Error: Could not copy script to ${script_path}." >&2
                return 1
            }
        else
            echo "ℹ️ Script already exists at ${script_path}. Use --update-code (-u) to force update."
        fi
    fi

    if [ -z "$rc_file" ]; then
        case "${SHELL}" in
            *bash) rc_file="${HOME}/.bashrc" ;;
            *zsh)  rc_file="${HOME}/.zshrc" ;;
            *fish) rc_file="${HOME}/.config/fish/config.fish" ;;
            *ksh)  rc_file="${HOME}/.kshrc" ;;
            *dash|sh) rc_file="${HOME}/.profile" ;;
        esac
    fi
    if [ -z "$rc_file" ]; then
        echo "Error: No resource file specified or detected." >&2
        return 1
    fi
    if [ ! -f "$rc_file" ]; then
        # Attempt to create it if it doesn't exist
        touch "$rc_file" || {
            echo "Error: Resource file '$rc_file' does not exist and could not be created." >&2
            return 1
        }
    fi

    # Add the sourcing line to the rc file if it's not already there.
    if ! grep -Fq ". \"${script_path}\"" "$rc_file"; then
        echo "" >> "$rc_file"
        echo "# >>> GOTO-MY-DIRECTORY initialize >>>" >> "$rc_file"
        echo ". \"${script_path}\"" >> "$rc_file"
        echo "# <<< GOTO-MY-DIRECTORY initialize <<<" >> "$rc_file"
        echo "✅ Added source line to $rc_file"
    else
        echo "ℹ️ Source line already present in $rc_file"
    fi
}

# Creates the default config file if it doesn't exist.
__goto_create_default_config() {
    if [ ! -f "${_GOTO_CONFIG_FILE}" ]; then
        echo "Creating default config file at ${_GOTO_CONFIG_FILE}..."
        mkdir -p "${_GOTO_CONFIG_DIR}" || {
            echo "Error: Could not create config directory ${_GOTO_CONFIG_DIR}." >&2
            return 1
        }
        # Create the config file with default values
        cat <<EOF > "${_GOTO_CONFIG_FILE}"
# The top-level directory to search for your projects
_GOTO_DIR=${HOME}/

# How deep to search for directories
_GOTO_MAX_DEPTH=1

# Automatically select the directory if it's the only match
_GOTO_AUTOSELECT_SINGLE_RESULT=1
EOF
    fi
}

__goto_config() {
    # Ensure the config file exists, creating it if necessary.
    __goto_create_default_config

    # Open the config file in an editor
    nano "${_GOTO_CONFIG_FILE}" 2>/dev/null || vi "${_GOTO_CONFIG_FILE}" 2>/dev/null \
        || echo "Please edit ${_GOTO_CONFIG_FILE} manually to set your preferences." >&2 && \
            echo "Current settings:" && cat "${_GOTO_CONFIG_FILE}"
}


__goto_test() {
    local __goto_color_green="\033[0;32m"
    local __goto_color_reset="\033[0m"
    echo -e "[ ${__goto_color_green}TESTING MODE ${__goto_color_reset} ]"
    echo "For actual usage, run: "
    echo "  $ source ./goto.sh"
    echo "Or install it with:"
    echo "  $ goto.sh --install"
    echo "Or:"
    echo "  $ goto.sh --install /path/to/your/rcfile"
    echo "And use it:"
    echo "  $ goto mydir"
    goto "${@:-}"
}

# Main logic: Decide what to do based on arguments and execution context.
case "${1:-}" in
    --install)
        __goto_install "${2:-}"
        exit 0
        ;;
    --update-code|-u)
        __goto_install "${2:-}" --force-copy
        exit 0
        ;;
    --config)
        __goto_config
        exit 0
        ;;
esac

# If not installing or configuring, source the config file for the goto function.
source "${_GOTO_CONFIG_FILE}" 2>/dev/null || {
    echo "Config file not found at ${_GOTO_CONFIG_FILE}. Please run 'goto.sh --config' to create it." >&2
    # Exit gracefully whether sourced or executed
    return 1 2>/dev/null || exit 1
}

# Get the current script file path in a shell-agnostic way
__goto_current_file() {
  [ -n "${BASH_SOURCE[0]}" ] && echo ${BASH_SOURCE[0]} || echo "${(%):-%x}"
}


# If the script is executed directly (not sourced) and no flags were passed, run the test function.
if [ "$(__goto_current_file)" = "$0" ] && [ -z "${ZSH_EVAL_CONTEXT:-}" ]; then
    __goto_test "${@}"
fi