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

![fzf-demo](https://user-images.githubusercontent.com/junegunn/fzf/master/image/demo.gif)
*(Demo shows general fzf usage, which this script integrates)*

### Plugin Features

When navigating to directories, `goto` automatically:
- **Activates Python virtual environments** if `venv/`, `.venv/`, or `bin/activate` is present
- **Executes custom plugins** for project-specific automation
- **Provides extensible hooks** for additional functionality

Example with virtual environment:
```bash
$ goto my-python-project
Looking for my-python-project...
Going to '/Users/username/projects/my-python-project'...
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
# The top-level directory to search for your projects
_GOTO_DIR=${HOME}/dev/projects

# How deep to search for directories
_GOTO_MAX_DEPTH=2

# Automatically select the directory if it's the only match
_GOTO_AUTOSELECT_SINGLE_RESULT=1
```

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