#!/bin/sh

# goto-my-directory installer script
# This script downloads and installs the goto-my-directory tool directly to ~/.config

set -e

echo "Installing goto-my-directory..."

# Configuration
REPO_URL="https://raw.githubusercontent.com/rikby/goto-my-directory/main"
SCRIPT_URL="${REPO_URL}/goto.sh"
CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/goto-my-directory"
PLUGINS_DIR="${CONFIG_DIR}/plugins"
CONFIG_FILE="${CONFIG_DIR}/config.sh"
SCRIPT_PATH="${CONFIG_DIR}/goto.sh"

# Create installation directory
echo "Creating installation directory at ${CONFIG_DIR}..."
mkdir -p "${CONFIG_DIR}"
mkdir -p "${PLUGINS_DIR}"

# Download the main script
echo "Downloading goto.sh..."
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${SCRIPT_URL}" -o "${SCRIPT_PATH}"
elif command -v wget >/dev/null 2>&1; then
    wget -q "${SCRIPT_URL}" -O "${SCRIPT_PATH}"
else
    echo "Error: Neither curl nor wget is available. Please install one of them." >&2
    exit 1
fi

# Download plugins
echo "Downloading plugins..."
for plugin in "venv-activate.plugin.sh" "venv-activate.sh" "README.md"; do
    plugin_url="${REPO_URL}/plugins/${plugin}"
    plugin_path="${PLUGINS_DIR}/${plugin}"
    
    echo "  - Downloading ${plugin}..."
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "${plugin_url}" -o "${plugin_path}" || echo "    Warning: Could not download ${plugin}"
    else
        wget -q "${plugin_url}" -O "${plugin_path}" || echo "    Warning: Could not download ${plugin}"
    fi
done

# Create default config file
if [ ! -f "${CONFIG_FILE}" ]; then
    echo "Creating default config file..."
    cat <<EOF > "${CONFIG_FILE}"
# The top-level directory to search for your projects
_GOTO_DIR=\${HOME}/

# How deep to search for directories
_GOTO_MAX_DEPTH=1

# Automatically select the directory if it's the only match
_GOTO_AUTOSELECT_SINGLE_RESULT=1
EOF
fi

# Determine shell RC file
case "${SHELL}" in
    *bash) rc_file="${HOME}/.bashrc" ;;
    *zsh)  rc_file="${HOME}/.zshrc" ;;
    *fish) rc_file="${HOME}/.config/fish/config.fish" ;;
    *ksh)  rc_file="${HOME}/.kshrc" ;;
    *dash|sh) rc_file="${HOME}/.profile" ;;
    *) 
        echo "Warning: Unknown shell ${SHELL}. Please manually add the source line to your shell RC file."
        rc_file=""
        ;;
esac

# Add source line to shell RC file
if [ -n "$rc_file" ]; then
    if [ ! -f "$rc_file" ]; then
        touch "$rc_file" || {
            echo "Warning: Could not create $rc_file. Please manually add the source line."
            rc_file=""
        }
    fi
    
    if [ -n "$rc_file" ] && ! grep -Fq ". \"${SCRIPT_PATH}\"" "$rc_file"; then
        echo "" >> "$rc_file"
        echo "# >>> GOTO-MY-DIRECTORY initialize >>>" >> "$rc_file"
        echo ". \"${SCRIPT_PATH}\"" >> "$rc_file"
        echo "# <<< GOTO-MY-DIRECTORY initialize <<<" >> "$rc_file"
        echo "✅ Added source line to $rc_file"
    else
        echo "ℹ️ Source line already present in $rc_file"
    fi
fi

echo ""
echo "🎉 Installation completed successfully!"
echo ""
echo "📁 Installed to: ${CONFIG_DIR}"
echo "🔧 Config file: ${CONFIG_FILE}"
echo "🔌 Plugins: ${PLUGINS_DIR}"
echo ""
echo "To start using goto-my-directory:"
echo "  1. Restart your shell or run: source ${rc_file:-'your shell RC file'}"
echo "  2. Try: goto <partial-directory-name>"
echo ""
echo "To customize settings, edit: ${CONFIG_FILE}"