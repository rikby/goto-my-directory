# goto-my-directory

`goto` is a command-line tool to quickly navigate to your most used directories. It allows you to jump to a directory by typing only a part of its name. It's smart, fast, and includes an interactive selector for when there are multiple matches.

## Features

- **Partial Matching**: Find directories by typing just a piece of their name.
- **Interactive Selector**: If multiple directories match your query, `goto` will present you with a list to choose from.
- **Fuzzy Finder Integration**: Uses `fzf` (if installed) for an enhanced, interactive filtering experience with directory previews.
- **Fallback UI**: If `fzf` is not available, it provides a simple and clear numbered list for selection.
- **Auto-Select**: If only one directory matches, `goto` navigates there instantly.
- **Plugin System**: Extensible plugin architecture that automatically executes hooks after directory changes.
- **Python Virtual Environment**: Auto-activates venv when entering Python project directories.
- **Easy Installation**: A simple one-line command to set it up.
- **Configurable**: Easily customize the search directory, search depth, and other settings.

## Dependencies

- **`fzf`** (Optional but Recommended): For the best interactive experience, `fzf` should be installed. You can find installation instructions [here](https://github.com/junegunn/fzf#installation).

## Installation

The recommended way to install is to use the installer script. This will download `goto.sh`, all plugins, create configuration files, and set up your shell automatically.

### One-Line Installation

```sh
curl -L https://raw.githubusercontent.com/rikby/goto-my-directory/main/install.sh | sh
```

Or with wget:
```sh
wget -qO- https://raw.githubusercontent.com/rikby/goto-my-directory/main/install.sh | sh
```

This will:
- Download `goto.sh` to `~/.config/goto-my-directory/`
- Download all plugins (including venv-activate)
- Create a default configuration file
- Add the source line to your shell RC file
- Set up everything needed to start using `goto`

### Manual Installation Steps

If you prefer to inspect before installing:

1.  **Download and inspect the installer:**
    ```sh
    curl -L https://raw.githubusercontent.com/rikby/goto-my-directory/main/install.sh -o install.sh
    cat install.sh  # Review the script
    ```

2.  **Run the installer:**
    ```sh
    sh install.sh
    ```

3.  **Restart your shell** or source your configuration file (e.g., `source ~/.bashrc`) to complete the installation.

### Manual Installation

Alternatively, you can clone the repository and run the installation manually.

```sh
git clone https://github.com/rikby/goto-my-directory.git
cd goto-my-directory
sh goto.sh --install
```

### Updating the Script

To update an existing installation with a newer version of the script:

```sh
# Force update the script file even if it already exists
./goto.sh --update-code
# or using the short option
./goto.sh -u
```

## Usage

Once installed, use the `goto` command followed by a partial directory name:

```sh
goto my-project
```

- If one directory named `my-project-folder` exists in your search path, you will be taken there directly.
- If multiple directories match (e.g., `my-project-alpha`, `my-project-beta`), you will be prompted to select one.

### Custom Search Path
You can also specify a custom directory to search within:
```sh
goto project /opt/projects        # Search for "project" only in /opt/projects
goto web /var/www                # Search for "web" directories in /var/www
goto config ~/.config            # Search for "config" in your config directory
```
This is useful for one-off searches in specific locations without changing your global configuration.

### Plugin Features

When navigating to directories, `goto` automatically:
- **Activates Python virtual environments** if `venv/`, `.venv/`, or `bin/activate` is present
- **Executes custom plugins** for project-specific automation
- **Provides extensible hooks** for additional functionality

Example with virtual environment:
```bash
$ goto python-project
Looking for python-project...
Going to '/Users/username/projects/my-super-python-project'...
✓ Python virtual environment activated successfully!
(venv) $ 
```

## Configuration

To customize the behavior of `goto`, you can edit its configuration file.

1.  First, run the config command to create the initial configuration file:
    ```sh
    ./goto.sh --config
    ```
    This will create the file at `~/.config/goto-my-directory/config.sh` and open it in your default editor (`nano` or `vi`).

2.  You can then edit the following variables:

    -   `_GOTO_DIR`: The root directory where `goto` will search for your target directories.
        -   **Default**: `${HOME}/`
    -   `_GOTO_MAX_DEPTH`: How many levels deep the search will go. A value of `1` will only search in the immediate subdirectories of `_GOTO_DIR`.
        -   **Default**: `1`
    -   `_GOTO_AUTOSELECT_SINGLE_RESULT`: If set to `1`, automatically `cd` into the directory if it's the only match.
        -   **Default**: `1`

**Example Config (`~/.config/goto-my-directory/config.sh`):**
```sh
# Single directory search (traditional)
_GOTO_DIR=${HOME}/dev/projects

# Multiple directory search (takes precedence over _GOTO_DIR)
# _GOTO_DIRS=("${HOME}/dev/projects" "/opt/work" "/var/www")

# How deep to search for directories
_GOTO_MAX_DEPTH=2

# Automatically select the directory if it's the only match
_GOTO_AUTOSELECT_SINGLE_RESULT=1
```

### Multiple Directory Search

You can configure `goto` to search across multiple directories simultaneously:

```sh
# Search across multiple project locations
_GOTO_DIRS=("${HOME}/personal" "${HOME}/work" "/opt/projects" "/var/www")
```

When `_GOTO_DIRS` is defined, it takes precedence over `_GOTO_DIR`. This allows you to:
- Search across work and personal project directories
- Include system-wide project folders  
- Search web server directories
- Organize projects by client or type

**Benefits:**
- Single `goto` command searches all configured locations
- No need to remember which directory contains which project
- Backward compatible with existing `_GOTO_DIR` configurations

## Plugin Development

The plugin system allows you to extend `goto` with custom functionality that executes automatically after directory changes.

### Creating a Plugin

1. **Create the plugin file** in the `plugins/` directory:
   ```bash
   # plugins/my-plugin.plugin.sh
   #!/bin/bash
   
   # Your plugin logic here
   my_custom_function() {
       echo "Hello from my plugin!"
   }
   
   # Register the plugin hook
   _GOTO_PLUGIN_HOOKS="$_GOTO_PLUGIN_HOOKS my_custom_function"
   ```

2. **Install/update** to copy plugins:
   ```bash
   ./goto.sh --update-code
   ```

3. **Reload** your shell:
   ```bash
   source ~/.zshrc  # or ~/.bashrc
   ```

### Plugin Guidelines

- **Keep it fast**: Plugins run on every directory change, so avoid slow operations
- **Read-only operations**: Don't modify files or install packages automatically  
- **Handle errors gracefully**: Use `2>/dev/null || true` to prevent breaking goto
- **Test thoroughly**: Ensure your plugin works across different environments

### Plugin Examples

**Git status display:**
```bash
__goto_plugin_git_status_after_cd() {
    if [ -d ".git" ]; then
        branch=$(git branch --show-current 2>/dev/null)
        echo "📋 Git branch: $branch"
    fi
}
```

**Project info:**
```bash
__goto_plugin_project_info_after_cd() {
    if [ -f "package.json" ]; then
        echo "📦 Node.js project detected"
    elif [ -f "requirements.txt" ]; then
        echo "🐍 Python project detected"
    fi
}
```

For comprehensive plugin development documentation, see [PLUGIN_DEVELOPMENT.md](PLUGIN_DEVELOPMENT.md).

## Contributing

This project uses a structured Change Request (CR) system for tracking feature development and enhancements.

### Development Process

1. **Feature Requests**: New features and enhancements are documented as Change Requests in `docs/CRs/`
2. **CR Format**: Each CR follows the format `GT-XXX-feature-name.md` with detailed specifications
3. **Implementation**: Development follows CR acceptance criteria and technical requirements
4. **Current CRs**: Check `docs/CRs/` directory for active change requests

### Submitting Changes

When contributing code changes:
- Reference the related CR number in commit messages (e.g., "GT-001: Implement dynamic depth control")
- Update CR status and implementation notes during development
- Ensure all acceptance criteria are met before marking CR as complete

### Current Development Focus

- **GT-001**: Dynamic depth control with command-line flags (-2, -5, -0) for flexible search depth