# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a shell script-based directory navigation tool called "goto-my-directory". It allows users to quickly navigate to directories by typing partial names. The tool supports both a simple numbered selection interface and an enhanced fuzzy finder (fzf) interface.

## Key Files and Architecture

- `goto.sh` - Main script containing all core functionality
- `install.sh` - Standalone installer that downloads and installs the script
- `bin/goto` - Binary wrapper that sources the main script and chooses between fzf/standard interfaces (it is useless here)
- `ABOUT.md` - Brief project description
- `README.md` - Comprehensive documentation

## Core Functions (goto.sh)

- `goto()` - Main function that handles directory searching and navigation
- `__goto_find_dirs()` - Uses `find` to locate matching directories
- `__goto_base_match()` - Handles directory selection without fzf
- `__goto_fzf_match()` - Handles directory selection with fzf interface
- `__goto_install()` - Installation logic for adding to shell RC files
- `__goto_config()` - Configuration file creation and editing
- `__goto_test()` - Test mode when script is executed directly

## Configuration

The script uses these configuration variables:
- `_GOTO_DIR` - Root directory to search (default: `${HOME}/`)
- `_GOTO_MAX_DEPTH` - Search depth (default: 1)
- `_GOTO_AUTOSELECT_SINGLE_RESULT` - Auto-select single matches (default: 1)
- Config file: `~/.config/goto-my-directory/config.sh`

## Testing the Script

Since this is a shell script project, testing is done by:

1. **Direct execution**: `./goto.sh [directory_name]` - runs in test mode
2. **Source and test**: `source ./goto.sh && goto [directory_name]`
3. **Install and test**: `./goto.sh --install` then restart shell

## Installation Commands

- `./goto.sh --install [rc_file]` - Install to shell RC file
- `./goto.sh --config` - Create/edit configuration file
- `sh install.sh` - Use the dedicated installer script

## Dependencies

- **Required**: Standard POSIX shell utilities (`find`, `grep`, `cd`)
- **Optional**: `fzf` for enhanced interactive experience

## Development Notes

- The script is written in POSIX shell for maximum compatibility
- Uses shellcheck disable directives for bash-specific features when needed
- Handles both sourced and executed contexts
- Supports multiple shell types (bash, zsh, fish, ksh, dash)
- Error codes are defined as constants for consistent error handling