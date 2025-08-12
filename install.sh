#!/bin/sh
set -e

# Define the installation directory and script path
INSTALL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/goto-my-directory"
SCRIPT_PATH="${INSTALL_DIR}/goto.sh"
REPO_URL="https://raw.githubusercontent.com/rikby/goto-my-directory/main/goto.sh"

# Ensure the installation directory exists
echo "Creating installation directory at ${INSTALL_DIR}..."
mkdir -p "${INSTALL_DIR}"

# Download the main goto.sh script directly to its final destination
echo "Downloading goto.sh to ${SCRIPT_PATH}..."
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${REPO_URL}" -o "${SCRIPT_PATH}"
elif command -v wget >/dev/null 2>&1; then
    wget -qO "${SCRIPT_PATH}" "${REPO_URL}"
else
    echo "Error: You need curl or wget to download the script." >&2
    exit 1
fi

# Make the downloaded script executable and run its installer
chmod +x "${SCRIPT_PATH}"
"${SCRIPT_PATH}" --install

echo "Installation complete. Please restart your shell or run 'source ~/.bashrc' (or equivalent)."