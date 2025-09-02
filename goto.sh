#!/usr/bin/env bash
#set -e
#set -u
# shellcheck disable=SC3040
#set -o pipefail

# The top-level directory to search for your projects
_GOTO_DIR="${_GOTO_DIR:-${HOME}/}"

# How deep to search for directories
_GOTO_MAX_DEPTH=${_GOTO_MAX_DEPTH:-1}

# Automatically select the directory if it's the only match, works only if fzf module is available
# If fzf is not installed the script will a single directory automatically
_GOTO_AUTOSELECT_SINGLE_RESULT=${_GOTO_AUTOSELECT_SINGLE_RESULT:-1}

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

    # Parse flags first
    local test_mode=false
    local verbose_mode=false
    local args=()

    _GOTO_VERSION=0.3.2
    
    # Parse arguments to extract flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --test)
                test_mode=true
                shift
                ;;
            -v|--verbose)
                verbose_mode=true
                shift
                ;;
            -h|--help)
                args+=("$1")
                shift
                ;;
            --install|--update-code|-u|--config)
                args+=("$1")
                shift
                ;;
            --version|-V)
                shift
                echo ${_GOTO_VERSION}
                return
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    
    # Restore positional parameters
    set -- "${args[@]}"

    # Convert _GOTO_DIR to _GOTO_DIRS array for unified handling
    if [ -z "${_GOTO_DIRS+x}" ]; then
        # _GOTO_DIRS not set, use _GOTO_DIR
        _GOTO_DIRS=("$_GOTO_DIR")
    fi

    local_goto_dirs=("${_GOTO_DIRS[@]}")

    show_help() {
        cat <<EOF
goto - Quick directory navigation tool

Usage:
  goto [OPTIONS] <partial_directory_name> [custom_search_path]

Options:
  -h, --help     Show this help message and exit
  -V, --version  Show version information
  -v, --verbose  Show verbose output including all matches
  --test         Test mode - list matches without navigating (for testing)
  --install      Install goto to your shell's RC file
  --update-code, -u  Force update script even if it exists
  --config       Edit configuration file

Arguments:
  <partial_directory_name>  Directory name or pattern to search for
  [custom_search_path]      Optional: Custom directory to search in

Description:
  Navigate to directories by typing partial names. Searches configured
  directories and presents matches for selection.

  You can optionally specify a custom search path as the second argument
  to search within a specific directory instead of your configured paths.

Configuration:
  The tool uses a config file at ~/.config/goto-my-directory/config.sh
  where you can set search directories and options.

  Key config variables:
    _GOTO_DIRS              Array of directories to search
    _GOTO_MAX_DEPTH         Maximum search depth
    _GOTO_AUTOSELECT_SINGLE_RESULT  Auto-select single matches

Plugins:
  Supports plugins for extended functionality. See plugins/ directory
  for examples and plugin development guide.

Examples:
  goto proj                    # Search for directories matching "proj"
  goto proj /opt/projects      # Search for "proj" only in /opt/projects
  goto --verbose proj          # Show all matches with verbose output
  goto --test proj             # List matches without navigating (test mode)
  goto --config               # Edit configuration
  goto --install              # Install to current shell

For more information, see README.md
EOF
    }

    # Handle help options and empty arguments
    case "${1:-}" in
        -h|--help)
            show_help
            return 0
            ;;
        "")
            show_help
            return 1
            ;;
    esac

    if [ -n "${2:-}" ]; then
        if [ -d "${2:-}" ]; then
            local_goto_dirs=("$(cd "${2}" && pwd)")
        else
           echo "Second argument is not a directory." > /dev/stderr
           return ${__CODE_NO_DIR_FOUND}
        fi
    fi

    local _search_dir="${1:-}"
    [ "$test_mode" = false ] && echo "Looking for ${_search_dir}..."
    local _selected_dir=""

    __goto_find_dirs() {
        find -L "${local_goto_dirs[@]}" -mindepth 1 -maxdepth "${_GOTO_MAX_DEPTH:-1}" \
            \( -type d -o -type l -exec test -d {} \; \) \
            -iname "*${_search_dir}*" -print 2>/dev/null | grep -v '^$'
    }

    _choice=0
    _matches=()
    
    # Use a more portable approach with command substitution
    _found_dirs=$(__goto_find_dirs "${_search_dir}")
    if [ -n "$_found_dirs" ]; then
        # Use a while read loop to properly populate the array
        # This works correctly in both bash and zsh
        while IFS= read -r dir; do
            [ -n "$dir" ] && _matches+=("$dir")
        done <<< "$_found_dirs"
    fi

    # Handle test mode - just output matches and exit
    if [ "$test_mode" = true ]; then
        case ${#_matches[@]} in
            0)
                echo "No directories found matching '*${_search_dir}*'"
                return 1
                ;;
            *)
                echo "Found ${#_matches[@]} match(es):"
                for match in "${_matches[@]}"; do
                    echo "$match"
                done
                return 0
                ;;
        esac
    fi

    # Handle verbose mode - show all matches
    if [ "$verbose_mode" = true ]; then
        case ${#_matches[@]} in
            0)
                echo "No directories found matching '*${_search_dir}*'"
                return 1
                ;;
            *)
                echo "Found ${#_matches[@]} match(es):"
                for ((i = 0; i < ${#_matches[@]}; i++)); do
                    printf "%2d) %s\n" "$((i + 1))" "${_matches[i]}"
                done
                echo
                ;;
        esac
    fi

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
        # Call all before_cd plugin hooks before changing directory
        # Use word splitting to handle both bash and zsh correctly
        echo "$_GOTO_PLUGIN_HOOKS" | tr ' ' '\n' | while read -r func; do
            # Skip empty lines
            [ -n "$func" ] || continue
            # Strip leading/trailing whitespace from function name
            func=$(echo "$func" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ -n "$func" ] && echo "$func" | grep -q "_before_cd$" && type "$func" >/dev/null 2>&1; then
                "$func" 2>/dev/null || true
            fi
        done
        
        echo "Going to '${_selected_dir}'..."
        cd "${_selected_dir}" || return ${__CODE_NO_DIR_FOUND}
        
        # Call all after_cd plugin hooks after successful directory change
        # Use word splitting to handle both bash and zsh correctly
        echo "$_GOTO_PLUGIN_HOOKS" | tr ' ' '\n' | while read -r func; do
            # Skip empty lines
            [ -n "$func" ] || continue
            # Strip leading/trailing whitespace from function name
            func=$(echo "$func" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ -n "$func" ] && echo "$func" | grep -q "_after_cd$" && type "$func" >/dev/null 2>&1; then
                "$func" 2>/dev/null || true
            fi
        done
    }

    if command -v fzf >/dev/null 2>&1; then
        # If autoselect is enabled and only one match, skip fzf
        if [ "${_GOTO_AUTOSELECT_SINGLE_RESULT}" = "1" ] && [ "${#_matches[@]}" = "1" ]; then
            _selected_dir="${_matches[@]:0:1}" # cross-shell approach for bash and zsh
        else
            while true; do
                __goto_fzf_match && break || return $?
            done
        fi
    else
        __goto_base_match || return $?
    fi

    if [ -z "${_selected_dir}" ]; then
        echo "Cancelled." > /dev/stderr
        return ${__CODE_BREAK}
    fi

    __goto_change_dir || return $?
}

# Get the current script file path in a shell-agnostic way
__goto_current_file() {
  [ -n "${BASH_SOURCE[0]}" ] && echo ${BASH_SOURCE[0]} || echo "${(%):-%x}"
}

# Function to install goto into the current shell's resource file
__goto_install() {
    rc_file="$1"
    force_copy="$2"
    readonly script_path="${_GOTO_CONFIG_DIR}/goto.sh"

    # Create the default config file if it doesn't exist
    __goto_create_default_config

    # Copy current script to config directory
    # TODO: Add versioning to detect when script needs updating
    current_script="$(__goto_current_file)"
    if [ "$current_script" != "$script_path" ] && [ -f "$current_script" ]; then
        if [ "$force_copy" = "--force-copy" ] || [ ! -f "$script_path" ]; then
            echo "✅ Copying script to ${script_path}..."
            mkdir -p "${_GOTO_CONFIG_DIR}" || {
                echo "Error: Could not create config directory ${_GOTO_CONFIG_DIR}." >&2
                return 1
            }
            cp "$current_script" "$script_path" || {
                echo "Error: Could not copy script to ${script_path}." >&2
                return 1
            }
            
            # Copy plugins directory if it exists
            source_plugins_dir="$(dirname "$current_script")/plugins"
            if [ -d "$source_plugins_dir" ]; then
                echo "✅ Copying plugins to ${_GOTO_CONFIG_DIR}/plugins/..."
                cp -r "$source_plugins_dir" "${_GOTO_CONFIG_DIR}/" || {
                    echo "Warning: Could not copy plugins directory." >&2
                }
            fi
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

# Alternative: Multiple search directories (takes precedence over _GOTO_DIR)
# _GOTO_DIRS=("${HOME}/" "/opt/projects/" "/var/www/")

# How deep to search for directories
_GOTO_MAX_DEPTH=1

# Automatically select the directory if it's the only match, works only if fzf module is available
# If fzf is not installed the script will a single directory automatically
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

__goto_hide_test_mode=1

__goto_test() {
    __goto_color_green="\033[0;32m"
    __goto_color_reset="\033[0m"
    [ ${__goto_hide_test_mode:-0} -eq 1 ] && {
        echo -e "[ ${__goto_color_green}TESTING MODE ${__goto_color_reset} ]"
        echo "For actual usage, run: "
        echo "  $ source ./goto.sh"
        echo "Or install it with:"
        echo "  $ goto.sh --install"
        echo "Or:"
        echo "  $ goto.sh --install /path/to/your/rcfile"
        echo "And use it:"
        echo "  $ goto mydir"
    }
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
# But preserve any pre-set test environment variables
if [ "${GOTO_TEST_MODE:-}" != "1" ]; then
    source "${_GOTO_CONFIG_FILE}" 2>/dev/null || {
        echo "Config file not found at ${_GOTO_CONFIG_FILE}. Please run 'goto.sh --config' to create it." >&2
        # Exit gracefully whether sourced or executed
        return 1 2>/dev/null || exit 1
    }
fi

# Initialize plugin hooks list
_GOTO_PLUGIN_HOOKS=""

# Load all plugins
for plugin in "${_GOTO_CONFIG_DIR}/plugins"/*.plugin.sh; do
    [ -f "$plugin" ] && source "$plugin"
done

# If the script is executed directly (not sourced) and no flags were passed, run the test function.
# Check for direct execution in both bash and zsh
if [ "$(__goto_current_file)" = "$0" ]; then
    # In bash: BASH_SOURCE[0] equals $0 when executed directly
    # In zsh: ZSH_EVAL_CONTEXT is unset when executed directly, contains "file" when sourced
    if [ -z "${BASH_VERSION:-}" ]; then
        # We're in zsh - check ZSH_EVAL_CONTEXT
        if [ -z "${ZSH_EVAL_CONTEXT:-}" ] || ! echo "${ZSH_EVAL_CONTEXT}" | grep -q "file"; then
            __goto_test "${@}"
        fi
    else
        # We're in bash - already checked that $0 equals BASH_SOURCE[0]
        __goto_test "${@}"
    fi
fi