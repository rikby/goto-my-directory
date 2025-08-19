#!/bin/bash
# venv-activate.plugin.sh - Auto-activate Python virtual environments after directory changes

# Source the standalone venv-activate script
# Use a more reliable method to get the script directory
_plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${_plugin_dir}/venv-activate.sh"

# Track what goto activated so we don't deactivate manually activated venvs
export _GOTO_ACTIVATED_VENV=""

# Plugin hook function called before directory change (deactivation)
__goto_plugin_venv_activate_before_cd() {
    # Only deactivate if goto activated the venv (not user activated)
    if [ -n "$_GOTO_ACTIVATED_VENV" ] && [ -n "$VIRTUAL_ENV" ]; then
        # Check if currently activated venv matches what goto activated
        if [ "$VIRTUAL_ENV" = "$_GOTO_ACTIVATED_VENV" ]; then
            echo "↩️ Deactivating virtual environment..."
            deactivate 2>/dev/null || true
            _GOTO_ACTIVATED_VENV=""
        fi
    fi
}

# Plugin hook function called after successful directory change (activation)
__goto_plugin_venv_activate_after_cd() {
    # Check for virtual environment in various forms:
    # 1. venv/ or .venv/ subdirectories
    # 2. Current directory is itself a venv (has pyvenv.cfg)
    # 3. bin/ directory with activate script
    if [ -d "venv" ] || [ -d ".venv" ] || [ -f "pyvenv.cfg" ] || [ -f "bin/activate" ]; then
        # Store current VIRTUAL_ENV to check if activation was successful
        local old_venv="$VIRTUAL_ENV"
        venv-activate 2>/dev/null || true
        
        # If venv-activate succeeded and changed VIRTUAL_ENV, track it
        if [ -n "$VIRTUAL_ENV" ] && [ "$VIRTUAL_ENV" != "$old_venv" ]; then
            _GOTO_ACTIVATED_VENV="$VIRTUAL_ENV"
        fi
    fi
}

# Register both plugin hooks
_GOTO_PLUGIN_HOOKS="$_GOTO_PLUGIN_HOOKS __goto_plugin_venv_activate_before_cd __goto_plugin_venv_activate_after_cd"