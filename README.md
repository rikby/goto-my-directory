# goto Script Setup Instructions

## Installation

1. **Save the script** to your home directory:
   ```bash
   nano ~/goto.sh
   ```
   Copy and paste the script content, then save with `Ctrl+X`, `Y`, `Enter`.

2. **Make it executable**:
   ```bash
   chmod +x ~/goto.sh
   ```

3. **Add to your shell profile** (choose based on your shell):

   **For Bash** (add to `~/.bash_profile` or `~/.bashrc`):
   ```bash
   echo "source ~/goto.sh" >> ~/.bash_profile
   ```

   **For Zsh** (default on newer macOS, add to `~/.zshrc`):
   ```bash
   echo "source ~/goto.sh" >> ~/.zshrc
   ```

4. **Reload your shell**:
   ```bash
   source ~/.zshrc  # or ~/.bash_profile
   ```

## Usage Examples

```bash
# Basic usage
goto Documents    # Goes directly if only one match
goto brow         # Shows selector if multiple matches
gt proj           # Using the short alias

# If you have directories like:
# ~/home/projects/browser-extension/
# ~/home/projects/brownfield-app/
# ~/home/downloads/brown-paper/

# Running 'goto brow' would show:
# Multiple directories found matching '*brow*':
# 
#  1) projects/browser-extension
#  2) projects/brownfield-app  
#  3) downloads/brown-paper
#
# Enter number (1-3), or press Enter to cancel:
```

## Optional: Enhanced Version with fzf

For an even better experience, install **fzf** (fuzzy finder):

```bash
# Install fzf via Homebrew
brew install fzf

# Then use goto_fzf instead of goto
goto_fzf brow
```

The fzf version provides:
- Fuzzy searching as you type
- File preview
- Better keyboard navigation
- More intuitive interface

## Features

✅ **Case-insensitive matching** - `goto DOCS` finds `Documents`  
✅ **Partial matching** - `goto proj` finds `projects`  
✅ **Single match auto-navigation** - No menu if only one result  
✅ **Clean numbered selection** - Easy to choose from multiple matches  
✅ **Input validation** - Handles invalid selections gracefully  
✅ **Short alias** - Use `gt` instead of `goto`  
✅ **iTerm compatible** - Works perfectly in iTerm2  
✅ **Safe navigation** - Only searches within ~/home directory  

## Troubleshooting

- **Command not found**: Make sure you sourced the script in your shell profile
- **Permission denied**: Run `chmod +x ~/goto.sh`
- **No matches found**: Check that directories exist in ~/home and spelling is correct

