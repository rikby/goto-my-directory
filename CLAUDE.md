# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a shell script-based directory navigation tool called "goto-my-directory". It allows users to quickly navigate to directories by typing partial names. The tool supports both a simple numbered selection interface and an enhanced fuzzy finder (fzf) interface.

## Key Files and Architecture

- `goto.sh` - Main script containing all core functionality
- `install.sh` - Standalone installer that downloads and installs the script
- `plugins/` - Plugin directory containing extensible functionality
  - `venv-activate.plugin.sh` - Auto-activates Python virtual environments
  - `venv-activate.sh` - Standalone venv activation script
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
- `_GOTO_DIRS` - Array of multiple directories to search (takes precedence over `_GOTO_DIR`)
- `_GOTO_MAX_DEPTH` - Search depth (default: 1)
- `_GOTO_AUTOSELECT_SINGLE_RESULT` - Auto-select single matches (default: 1)
- Config file: `~/.config/goto-my-directory/config.sh`

### Multiple Directory Search
- Use `_GOTO_DIRS=("${HOME}/" "/opt/projects/" "/var/www/")` to search multiple locations
- If `_GOTO_DIRS` is defined, `_GOTO_DIR` is ignored
- Maintains backward compatibility with existing `_GOTO_DIR` configurations

## Testing the Script

Since this is a shell script project, testing is done by:

1. **Direct execution**: `./goto.sh [directory_name]` - runs in test mode
2. **Source and test**: `source ./goto.sh && goto [directory_name]`
3. **Install and test**: `./goto.sh --install` then restart shell

## Installation Commands

- `./goto.sh --install [rc_file]` - Install to shell RC file
- `./goto.sh --update-code` or `./goto.sh -u [rc_file]` - Force update script file even if it exists
- `./goto.sh --config` - Create/edit configuration file
- `sh install.sh` - Use the dedicated installer script

## Dependencies

- **Required**: Standard POSIX shell utilities (`find`, `grep`, `cd`)
- **Optional**: `fzf` for enhanced interactive experience

## Plugin System

The tool features an extensible plugin system that automatically executes hooks after successful directory changes.

### Plugin Architecture
- **Location**: `plugins/*.plugin.sh` files in repository, installed to `~/.config/goto-my-directory/plugins/`
- **Auto-loading**: All `*.plugin.sh` files are sourced during shell initialization
- **Hook registration**: Plugins register functions in `_GOTO_PLUGIN_HOOKS` variable
- **Execution**: Hooks are called automatically after each successful `cd`
- **Error handling**: Failed plugins don't break the goto command

### Included Plugins
- **venv-activate**: Automatically activates Python virtual environments when entering directories with `venv/`, `.venv/`, or `bin/activate`

### Plugin Development
Plugins should be fast, read-only operations since goto is used frequently. Avoid slow operations like package installation or network requests.

See [PLUGIN_DEVELOPMENT.md](PLUGIN_DEVELOPMENT.md) for comprehensive plugin development documentation, including:
- Quick start guide with examples
- Performance guidelines and best practices
- Plugin submission process for contributions
- Testing procedures and checklists

## Change Request (CR) System

This project uses a structured Change Request system for tracking feature development and enhancements.

### CR Directory Structure
- **Configuration**: `.gt-config.toml` - CR system configuration
- **Counter**: `.gt-next` - Next CR number tracking
- **CRs**: `docs/CRs/GT-XXX-title.md` - Individual change request documents

### CR Workflow for Development
1. **Reference Existing CRs**: When implementing features, always reference the related CR document (e.g., GT-001)
2. **Update CR Status**: Change status from "Proposed" to "In Progress" when starting implementation
3. **Implementation Notes**: Add implementation details to the "Implementation Notes" section
4. **Acceptance Criteria**: Use CR acceptance criteria as implementation checklist
5. **Mark Complete**: Update status to "Completed" when all acceptance criteria are met

### Current Active CRs
- **GT-001**: Dynamic depth control with -N flags (-2, -5, -0 flags)

### CR Integration with Code Changes
- Reference CR numbers in commit messages when implementing features
- Update CR status during implementation phases
- Use CR acceptance criteria to validate implementation completeness
- Document any deviations from CR specifications in implementation notes

## Development Notes

- The script is written in POSIX shell for maximum compatibility
- Uses shellcheck disable directives for bash-specific features when needed
- Handles both sourced and executed contexts
- Supports multiple shell types (bash, zsh, fish, ksh, dash)
- Error codes are defined as constants for consistent error handling
- Plugin system uses whitespace-safe function name handling
- Use @release.sh for adding new release tags to git repository. Target code has to be commited before.