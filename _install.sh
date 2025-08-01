#!/bin/sh

CURRENT_FILE="$(realpath "$0")"

# Detect actual shell name
CURRENT_SHELL="$(ps -p $$ -o comm= | awk -F/ '{print $NF}')"

# Map shell to RC file
case "$CURRENT_SHELL" in
  bash)
    RC_FILE="$HOME/.bashrc"
    INCLUDE_LINE=". \"$CURRENT_FILE\""
    ;;
  zsh)
    RC_FILE="$HOME/.zshrc"
    INCLUDE_LINE=". \"$CURRENT_FILE\""
    ;;
  fish)
    RC_FILE="$HOME/.config/fish/config.fish"
    INCLUDE_LINE="source \"$CURRENT_FILE\""
    ;;
  ksh)
    RC_FILE="$HOME/.kshrc"
    INCLUDE_LINE=". \"$CURRENT_FILE\""
    ;;
  dash|sh)
    RC_FILE="$HOME/.profile"
    INCLUDE_LINE=". \"$CURRENT_FILE\""
    ;;
  *)
    echo "❌ Unsupported shell: $CURRENT_SHELL"
    exit 1
    ;;
esac

# Append if not already included
if [ -f "$RC_FILE" ]; then
  if ! grep -Fq "$INCLUDE_LINE" "$RC_FILE"; then
    echo "# >>> goto initialize >>>" >> "$RC_FILE"
    echo "$INCLUDE_LINE" >> "$RC_FILE"
    echo "# <<< goto initialize <<<" >> "$RC_FILE"
    echo "✅ Added to $RC_FILE"
  else
    echo "ℹ️ Already present in $RC_FILE"
  fi
else
  echo "⚠️ RC file not found: $RC_FILE"
fi