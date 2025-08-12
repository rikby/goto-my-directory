#!/bin/sh
set -e

# The repository and the script to download
REPO_URL="https://raw.githubusercontent.com/rikby/goto-my-directory/main/goto.sh"
TMP_SCRIPT="/tmp/goto.sh"

# Download the main goto.sh script
echo "Downloading goto.sh from the repository..."
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${REPO_URL}" -o "${TMP_SCRIPT}"
elif command -v wget >/dev/null 2>&1; then
    wget -qO "${TMP_SCRIPT}" "${REPO_URL}"
else
    echo "Error: You need curl or wget to download the script." >&2
    exit 1
fi

# Make the downloaded script executable and run its installer
chmod +x "${TMP_SCRIPT}"
"${TMP_SCRIPT}" --install

# Clean up the temporary file
rm "${TMP_SCRIPT}"

echo "Installation complete. Please restart your shell or run 'source ~/.bashrc' (or equivalent)."
