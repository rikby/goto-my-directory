#!/bin/bash
# venv-activate.plugin.sh - Auto-activate Python virtual environments after directory changes

# Source the standalone venv-activate script
# Use a more reliable method to get the script directory
_plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${_plugin_dir}/venv-activate.sh"


# Plugin hook function called after successful directory change
__goto_plugin_venv_activate_after_cd() {
    # Only try to activate if we're in a directory that might have a venv
    # Check if any of the common venv directories exist
    if [ -d "venv" ] || [ -d ".venv" ] || [ -d "bin" ]; then
        venv-activate 2>/dev/null || true
    fi
}

# Register this plugin hook
_GOTO_PLUGIN_HOOKS="$_GOTO_PLUGIN_HOOKS __goto_plugin_venv_activate_after_cd"