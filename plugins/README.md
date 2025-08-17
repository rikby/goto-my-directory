# Plugin Development Guide

This directory contains plugins for the goto-my-directory tool. Plugins extend goto's functionality by automatically executing hooks after successful directory changes.

## Plugin Architecture

### How Plugins Work

1. **Auto-loading**: All `*.plugin.sh` files in this directory are automatically sourced when goto.sh is loaded
2. **Hook registration**: Plugins register their hook functions in the `_GOTO_PLUGIN_HOOKS` variable
3. **Automatic execution**: Registered hooks are called after every successful `cd` operation
4. **Error isolation**: Failed plugins don't break the goto command

### Plugin Template

```bash
#!/bin/bash
# my-feature.plugin.sh - Brief description of what this plugin does

# Source any standalone scripts if needed
# source "$(dirname "${BASH_SOURCE[0]:-$0}")/my-feature.sh"

# Define your hook function
__goto_plugin_my_feature_after_cd() {
    # Your plugin logic here
    # This function is called every time goto successfully changes directories
    
    # Example: Check if we're in a specific type of project
    if [ -f "Dockerfile" ]; then
        echo "🐳 Docker project detected"
    fi
}

# Register the plugin hook
_GOTO_PLUGIN_HOOKS="$_GOTO_PLUGIN_HOOKS __goto_plugin_my_feature_after_cd"
```

## Plugin Guidelines

### Performance Considerations

Since goto is used frequently throughout the day, plugins must be **fast and lightweight**:

✅ **Good practices:**
- Read file existence with `[ -f "filename" ]` (instant)
- Check directory existence with `[ -d "dirname" ]` (instant)  
- Display information about the current directory
- Set environment variables
- Show status of existing services

❌ **Avoid these:**
- Network requests (slow and unreliable)
- Package installation (npm install, pip install, etc.)
- File compilation or building
- Database operations
- Heavy file processing

### Error Handling

Always handle errors gracefully to prevent breaking the goto command:

```bash
# Good: Silent failure
some_command 2>/dev/null || true

# Good: Conditional execution
if command -v some_tool >/dev/null 2>&1; then
    some_tool --status
fi

# Bad: Unhandled errors can break goto
some_command_that_might_fail
```

### Naming Conventions

- **Plugin files**: `feature-name.plugin.sh`
- **Hook functions**: `__goto_plugin_feature_name_after_cd()`
- **Helper functions**: `__goto_plugin_feature_name_helper()`

## Development Workflow

1. **Create plugin** in `plugins/` directory
2. **Test locally**:
   ```bash
   source ./goto.sh
   goto some-directory  # Test your plugin
   ```
3. **Install plugin**:
   ```bash
   ./goto.sh --update-code
   ```
4. **Reload shell** to activate:
   ```bash
   source ~/.zshrc  # or ~/.bashrc
   ```

## Existing Plugins

### venv-activate.plugin.sh

Automatically activates Python virtual environments when entering directories containing:
- `venv/bin/activate`
- `.venv/bin/activate`  
- `bin/activate`

**Files:**
- `venv-activate.plugin.sh` - Plugin wrapper
- `venv-activate.sh` - Standalone activation script

## Plugin Ideas

Here are some fast, useful plugin ideas:

### Information Display
- **Git status**: Show current branch and dirty status
- **Project type**: Detect Node.js, Python, Java projects by files present
- **Environment hints**: Show if .env files exist
- **Last modified**: Display when key project files were last changed

### Environment Setup
- **Load .env files**: Source environment variables from project files
- **Set JAVA_HOME**: Based on .java-version file
- **Update PATH**: Add project-specific bin directories

### Status Checks
- **Service status**: Check if development servers are running on expected ports
- **Docker status**: Show running containers for the project
- **Database connectivity**: Test connection to project databases (read-only)

## Testing Your Plugin

Create a simple test to verify your plugin works:

```bash
# Test plugin loading
source ~/.config/goto-my-directory/goto.sh
echo "Loaded hooks: $_GOTO_PLUGIN_HOOKS"

# Test plugin execution in a test directory
mkdir -p /tmp/test-goto-plugin
cd /tmp/test-goto-plugin
# Create test files your plugin looks for
touch package.json  # or requirements.txt, Dockerfile, etc.

# Test goto with your plugin
goto test-goto-plugin
```

## Contributing

When contributing plugins:

1. Follow the naming conventions and guidelines above
2. Test thoroughly in different environments
3. Document what your plugin does and when it activates
4. Keep plugins focused on a single responsibility
5. Ensure plugins are fast and don't slow down goto usage