# goto-my-directory

`goto` is a command-line tool to quickly navigate to your most used directories. It allows you to jump to a directory by typing only a part of its name. It's smart, fast, and includes an interactive selector for when there are multiple matches.

## Features

- **Partial Matching**: Find directories by typing just a piece of their name.
- **Interactive Selector**: If multiple directories match your query, `goto` will present you with a list to choose from.
- **Fuzzy Finder Integration**: Uses `fzf` (if installed) for an enhanced, interactive filtering experience with directory previews.
- **Fallback UI**: If `fzf` is not available, it provides a simple and clear numbered list for selection.
- **Auto-Select**: If only one directory matches, `goto` navigates there instantly.
- **Easy Installation**: A simple one-line command to set it up.
- **Configurable**: Easily customize the search directory, search depth, and other settings.

## Dependencies

- **`fzf`** (Optional but Recommended): For the best interactive experience, `fzf` should be installed. You can find installation instructions [here](https://github.com/junegunn/fzf#installation).

## Installation

The recommended way to install is to use the installer script. This will download the main `goto.sh` script, install it to a standard location (`~/.config/goto-my-directory/goto.sh`), and configure your shell to use it.

1.  **Download the installer:**
    ```sh
    # With curl
    curl -L https://raw.githubusercontent.com/rikby/goto-my-directory/main/install.sh -o install.sh
    
    # Or with wget
    wget https://raw.githubusercontent.com/rikby/goto-my-directory/main/install.sh
    ```

2.  **(Optional but Recommended)** Inspect the `install.sh` script to ensure it's safe.

3.  **Run the installer:**
    ```sh
    sh install.sh
    ```

4.  **Restart your shell** or source your configuration file (e.g., `source ~/.bashrc`) to complete the installation.

### Manual Installation

Alternatively, you can clone the repository and run the installation manually.

```sh
git clone https://github.com/rikby/goto-my-directory.git
cd goto-my-directory
sh goto.sh --install
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