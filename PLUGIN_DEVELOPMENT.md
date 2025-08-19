# Plugin Development Guide

This guide explains how to create and contribute plugins for goto-my-directory.

## Quick Start

### Creating a Simple Plugin

1. **Create the plugin file** in the `plugins/` directory:
   ```bash
   # plugins/git-status.plugin.sh
   #!/bin/bash
   
   # Plugin hook function
   __goto_plugin_git_status_after_cd() {
       if [ -d ".git" ]; then
           branch=$(git branch --show-current 2>/dev/null)
           status=$(git status --porcelain 2>/dev/null)
           
           if [ -n "$status" ]; then
               echo "📋 Git: $branch (dirty)"
           else
               echo "📋 Git: $branch (clean)"
           fi
       fi
   }
   
   # Register the plugin hook
   _GOTO_PLUGIN_HOOKS="$_GOTO_PLUGIN_HOOKS __goto_plugin_git_status_after_cd"
   ```

2. **Test locally**:
   ```bash
   source ./goto.sh
   goto your-project  # Should show git status
   ```

3. **Install system-wide** (optional):
   ```bash
   ./goto.sh --update-code
   source ~/.zshrc  # or ~/.bashrc
   ```

## Plugin Architecture

### How Plugins Work

1. **Auto-loading**: All `*.plugin.sh` files are sourced when goto loads
2. **Hook registration**: Plugins add their functions to `_GOTO_PLUGIN_HOOKS`  
3. **Automatic execution**: Hooks are called after each successful directory change
4. **Error isolation**: Plugin failures don't break the goto command

### Plugin Template

```bash
#!/bin/bash
# plugin-name.plugin.sh - Brief description

# Optional: Source external scripts
# source "$(dirname "${BASH_SOURCE[0]:-$0}")/helper-script.sh"

# Main plugin function (required)
__goto_plugin_NAME_after_cd() {
    # Your plugin logic here
    # This runs every time goto changes directories
    
    # Example: Check for specific project type
    if [ -f "package.json" ]; then
        echo "📦 Node.js project detected"
    fi
}

# Register the hook (required)
_GOTO_PLUGIN_HOOKS="$_GOTO_PLUGIN_HOOKS __goto_plugin_NAME_after_cd"
```

## Development Guidelines

### Performance Requirements

Since goto is used frequently, plugins must be **fast and lightweight**:

✅ **Good practices:**
```bash
# File existence checks (instant)
[ -f "package.json" ] && echo "Node.js project"

# Directory checks (instant)  
[ -d ".git" ] && show_git_status

# Environment variables
export PROJECT_TYPE="nodejs"

# Quick command checks
command -v docker >/dev/null && check_docker_compose
```

❌ **Avoid these:**
```bash
# Network requests (slow, unreliable)
curl -s api.github.com/user  # DON'T

# Package installation
npm install  # DON'T

# Heavy processing
find . -name "*.js" | wc -l  # DON'T (unless needed)

# Database operations
mysql -e "SELECT COUNT(*) FROM users"  # DON'T
```

### Error Handling

Always handle errors gracefully:

```bash
# Good: Silent failure
some_command 2>/dev/null || true

# Good: Conditional execution
if command -v some_tool >/dev/null 2>&1; then
    some_tool --status
fi

# Good: Check before accessing
[ -f ".env" ] && echo "Environment file found"

# Bad: Unhandled errors
some_command_that_might_fail  # Could break goto
```

### Naming Conventions

- **Plugin files**: `feature-name.plugin.sh`
- **Hook functions**: `__goto_plugin_feature_name_after_cd()`
- **Helper functions**: `__goto_plugin_feature_name_helper()`
- **Variables**: `_GOTO_PLUGIN_FEATURE_NAME_VAR`

## Example Plugins

### 1. Project Type Detection
```bash
#!/bin/bash
# project-info.plugin.sh - Detect and display project type

__goto_plugin_project_info_after_cd() {
    if [ -f "package.json" ]; then
        echo "📦 Node.js project"
    elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
        echo "🐍 Python project" 
    elif [ -f "Cargo.toml" ]; then
        echo "🦀 Rust project"
    elif [ -f "go.mod" ]; then
        echo "🐹 Go project"
    elif [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
        echo "☕ Java project"
    fi
}

_GOTO_PLUGIN_HOOKS="$_GOTO_PLUGIN_HOOKS __goto_plugin_project_info_after_cd"
```

### 2. Development Server Status
```bash
#!/bin/bash
# dev-server.plugin.sh - Check if development servers are running

__goto_plugin_dev_server_after_cd() {
    # Check common development ports
    local ports="3000 8000 8080 5000"
    
    for port in $ports; do
        if lsof -ti:$port >/dev/null 2>&1; then
            echo "🌐 Server running on port $port"
            return
        fi
    done
}

_GOTO_PLUGIN_HOOKS="$_GOTO_PLUGIN_HOOKS __goto_plugin_dev_server_after_cd"
```

### 3. Docker Status
```bash
#!/bin/bash
# docker-status.plugin.sh - Show Docker container status

__goto_plugin_docker_status_after_cd() {
    if [ -f "docker-compose.yml" ] && command -v docker-compose >/dev/null 2>&1; then
        local running=$(docker-compose ps -q 2>/dev/null | wc -l)
        if [ "$running" -gt 0 ]; then
            echo "🐳 Docker: $running containers running"
        else
            echo "🐳 Docker: compose file found (not running)"
        fi
    fi
}

_GOTO_PLUGIN_HOOKS="$_GOTO_PLUGIN_HOOKS __goto_plugin_docker_status_after_cd"
```

## Testing Your Plugin

### Basic Testing
```bash
# Test plugin loading
source ./goto.sh
echo "Loaded hooks: $_GOTO_PLUGIN_HOOKS"

# Test in different directories
mkdir -p /tmp/test-project
cd /tmp/test-project

# Create test files your plugin looks for
touch package.json
echo '{"name": "test"}' > package.json

# Test with goto
goto test-project
```

### Advanced Testing
```bash
# Test error handling
chmod -r some_file  # Remove read permissions
goto test-project   # Should not break

# Test with missing commands
alias docker-compose='command_that_does_not_exist'
goto test-project   # Should handle gracefully

# Test performance
time goto test-project  # Should be fast
```

## Contributing Plugins

### Submission Process

1. **Fork the repository**
2. **Create your plugin** following the guidelines above
3. **Test thoroughly** in different environments  
4. **Update documentation** if needed
5. **Submit a pull request**

### Plugin Submission Checklist

- [ ] Follows naming conventions
- [ ] Includes error handling
- [ ] Performance tested (< 100ms execution time)
- [ ] Works across different shells (bash, zsh)
- [ ] Handles missing dependencies gracefully
- [ ] Includes clear documentation
- [ ] No network requests or slow operations
- [ ] Tested with and without required tools

### Pull Request Template

```markdown
## Plugin: [Plugin Name]

### Description
Brief description of what the plugin does.

### Features  
- Feature 1
- Feature 2

### Dependencies
- Required: bash/zsh, coreutils
- Optional: git, docker, etc.

### Testing
- [ ] Tested on macOS/Linux
- [ ] Tested with bash and zsh
- [ ] Tested with missing dependencies
- [ ] Performance verified (< 100ms)

### Examples
```bash
$ goto my-project
📦 Node.js project
🐳 Docker: 3 containers running
```

## Plugin Ideas

### Information Display
- **Git enhanced**: Show branch, commits ahead/behind, stash count
- **Last modified**: Display when key files were last changed
- **Directory size**: Show size for large directories
- **File counts**: Count files by type (*.js, *.py, etc.)

### Environment Setup  
- **Load .env files**: Source environment variables automatically
- **Set JAVA_HOME**: Based on .java-version file
- **Update PATH**: Add project-specific bin directories
- **Activate conda**: Based on environment.yml

### Status Checks
- **Database connectivity**: Test connections (read-only)
- **API health**: Check if services respond
- **Certificate expiry**: Warn about expiring SSL certs
- **Disk space**: Alert on low disk space

### Development Tools
- **Test status**: Show last test results
- **Build status**: Check if builds are needed
- **Dependency updates**: Check for outdated packages (display only)
- **Code metrics**: Show basic project statistics

Remember: Focus on **information display** and **environment setup** rather than **actions that modify files** or **slow operations**.