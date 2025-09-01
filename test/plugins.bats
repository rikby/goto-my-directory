#!/usr/bin/env bats

# BATS tests for goto-my-directory plugin system
# This file tests the plugin loading and hook functionality

# Setup function run before each test
setup() {
    # Create temporary directory structure for testing in /tmp
    export TEST_HOME="$(mktemp -d /tmp/goto-test-XXXXXX)"
    export TEST_CONFIG_DIR="${TEST_HOME}/.config/goto-my-directory"
    export TEST_PLUGINS_DIR="${TEST_CONFIG_DIR}/plugins"
    export TEST_CONFIG_FILE="${TEST_CONFIG_DIR}/config.sh"
    
    # Create test directory structure
    mkdir -p "${TEST_HOME}/project-with-venv"
    mkdir -p "${TEST_HOME}/project-with-venv/venv/bin"
    mkdir -p "${TEST_HOME}/project-with-dotenv"
    mkdir -p "${TEST_HOME}/project-with-dotenv/.venv/bin"
    mkdir -p "${TEST_HOME}/regular-project"
    
    # Create mock venv activate scripts
    cat > "${TEST_HOME}/project-with-venv/venv/bin/activate" << 'EOF'
#!/bin/bash
export VIRTUAL_ENV="$(dirname $(dirname $(readlink -f ${BASH_SOURCE[0]})))"
export PATH="$VIRTUAL_ENV/bin:$PATH"
echo "Virtual environment activated: $VIRTUAL_ENV"
EOF

    cat > "${TEST_HOME}/project-with-dotenv/.venv/bin/activate" << 'EOF'
#!/bin/bash
export VIRTUAL_ENV="$(dirname $(dirname $(readlink -f ${BASH_SOURCE[0]})))"
export PATH="$VIRTUAL_ENV/bin:$PATH"
echo "Virtual environment activated: $VIRTUAL_ENV"
EOF
    
    # Override config variables for testing
    export _GOTO_DIR="${TEST_HOME}"
    export _GOTO_CONFIG_DIR="${TEST_CONFIG_DIR}"
    export _GOTO_CONFIG_FILE="${TEST_CONFIG_FILE}"
    export _GOTO_MAX_DEPTH=2
    export _GOTO_AUTOSELECT_SINGLE_RESULT=1
    
    # Create minimal config file
    mkdir -p "${TEST_CONFIG_DIR}"
    mkdir -p "${TEST_PLUGINS_DIR}"
    cat > "${TEST_CONFIG_FILE}" << EOF
_GOTO_DIR=${TEST_HOME}
_GOTO_MAX_DEPTH=2
_GOTO_AUTOSELECT_SINGLE_RESULT=1
EOF
    
    # Initialize plugin hooks
    export _GOTO_PLUGIN_HOOKS=""
}

# Teardown function run after each test
teardown() {
    # Clean up temporary directories
    [ -n "${TEST_HOME}" ] && rm -rf "${TEST_HOME}"
    
    # Clean up environment variables
    unset VIRTUAL_ENV
    unset _GOTO_ACTIVATED_VENV
}

# Test plugin loading mechanism
@test "plugins are loaded from plugins directory" {
    # Create a test plugin
    cat > "${TEST_PLUGINS_DIR}/test.plugin.sh" << 'EOF'
#!/bin/bash
test_plugin_loaded=1
echo "Test plugin loaded"
EOF
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        echo \"Plugin loaded status: \${test_plugin_loaded:-0}\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Test plugin loaded" ]]
    [[ "$output" =~ "Plugin loaded status: 1" ]]
}

@test "multiple plugins are loaded correctly" {
    # Create multiple test plugins
    cat > "${TEST_PLUGINS_DIR}/plugin1.plugin.sh" << 'EOF'
#!/bin/bash
echo "Plugin 1 loaded"
EOF
    
    cat > "${TEST_PLUGINS_DIR}/plugin2.plugin.sh" << 'EOF'
#!/bin/bash
echo "Plugin 2 loaded"
EOF
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Plugin 1 loaded" ]]
    [[ "$output" =~ "Plugin 2 loaded" ]]
}

@test "non-plugin files are ignored" {
    # Create plugin and non-plugin files
    cat > "${TEST_PLUGINS_DIR}/valid.plugin.sh" << 'EOF'
#!/bin/bash
echo "Valid plugin loaded"
EOF
    
    cat > "${TEST_PLUGINS_DIR}/invalid.sh" << 'EOF'
#!/bin/bash
echo "Invalid file loaded"
EOF
    
    cat > "${TEST_PLUGINS_DIR}/README.md" << 'EOF'
# This should be ignored
EOF
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Valid plugin loaded" ]]
    [[ ! "$output" =~ "Invalid file loaded" ]]
}

# Test plugin hook registration
@test "plugins can register hooks" {
    # Create a plugin that registers hooks
    cat > "${TEST_PLUGINS_DIR}/hooks.plugin.sh" << 'EOF'
#!/bin/bash

test_before_cd() {
    echo "Before CD hook executed"
}

test_after_cd() {
    echo "After CD hook executed"
}

# Register hooks
_GOTO_PLUGIN_HOOKS="$_GOTO_PLUGIN_HOOKS test_before_cd test_after_cd"
EOF
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        echo \"Registered hooks: \$_GOTO_PLUGIN_HOOKS\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Registered hooks:" ]]
    [[ "$output" =~ "test_before_cd" ]]
    [[ "$output" =~ "test_after_cd" ]]
}

@test "plugin hooks are called during directory change" {
    # Create a plugin with hooks
    cat > "${TEST_PLUGINS_DIR}/test-hooks.plugin.sh" << 'EOF'
#!/bin/bash

test_hook_before_cd() {
    echo "Hook: Before changing directory"
}

test_hook_after_cd() {
    echo "Hook: After changing directory to $(pwd)"
}

_GOTO_PLUGIN_HOOKS="$_GOTO_PLUGIN_HOOKS test_hook_before_cd test_hook_after_cd"
EOF
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        
        # Override cd to track calls without actually changing directory
        cd() {
            echo \"cd called with: \$1\"
            # Simulate successful cd
            return 0
        }
        
        _selected_dir='${TEST_HOME}/regular-project'
        __goto_change_dir
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Hook: Before changing directory" ]]
    [[ "$output" =~ "Hook: After changing directory" ]]
    [[ "$output" =~ "Going to" ]]
}

# Test venv-activate plugin functionality
@test "venv-activate plugin detects virtual environments" {
    # Copy the actual venv-activate plugin
    cp "${BATS_TEST_DIRNAME}/../plugins/venv-activate.plugin.sh" "${TEST_PLUGINS_DIR}/"
    
    # Create a standalone venv-activate script for testing
    cat > "${TEST_PLUGINS_DIR}/venv-activate.sh" << 'EOF'
#!/bin/bash
# Mock venv-activate script for testing
if [ -d "venv" ] || [ -d ".venv" ] || [ -f "pyvenv.cfg" ] || [ -f "bin/activate" ]; then
    if [ -f "venv/bin/activate" ]; then
        echo "Activating virtual environment: venv/"
        export VIRTUAL_ENV="$(pwd)/venv"
    elif [ -f ".venv/bin/activate" ]; then
        echo "Activating virtual environment: .venv/"
        export VIRTUAL_ENV="$(pwd)/.venv"
    elif [ -f "bin/activate" ]; then
        echo "Activating virtual environment: current directory"
        export VIRTUAL_ENV="$(pwd)"
    fi
    export PATH="$VIRTUAL_ENV/bin:$PATH"
fi
EOF
    chmod +x "${TEST_PLUGINS_DIR}/venv-activate.sh"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        
        # Mock cd to avoid actual directory change
        cd() {
            case \"\$1\" in
                *project-with-venv*)
                    # Simulate being in project with venv
                    mkdir -p venv/bin
                    ;;
                *project-with-dotenv*)
                    # Simulate being in project with .venv
                    mkdir -p .venv/bin
                    ;;
            esac
            return 0
        }
        
        _selected_dir='${TEST_HOME}/project-with-venv'
        __goto_change_dir
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Going to" ]]
}

@test "venv-activate plugin tracks activated environments" {
    # Copy and modify the venv plugin for testing
    cat > "${TEST_PLUGINS_DIR}/test-venv.plugin.sh" << 'EOF'
#!/bin/bash

# Mock venv-activate function
venv-activate() {
    if [ -d "venv" ]; then
        echo "Mock: Activating venv"
        export VIRTUAL_ENV="$(pwd)/venv"
        return 0
    fi
    return 1
}

# Track what goto activated
export _GOTO_ACTIVATED_VENV=""

__goto_plugin_test_venv_before_cd() {
    if [ -n "$_GOTO_ACTIVATED_VENV" ] && [ -n "$VIRTUAL_ENV" ]; then
        if [ "$VIRTUAL_ENV" = "$_GOTO_ACTIVATED_VENV" ]; then
            echo "Deactivating goto-activated venv: $VIRTUAL_ENV"
            unset VIRTUAL_ENV
            _GOTO_ACTIVATED_VENV=""
        fi
    fi
}

__goto_plugin_test_venv_after_cd() {
    if [ -d "venv" ]; then
        local old_venv="$VIRTUAL_ENV"
        venv-activate
        if [ -n "$VIRTUAL_ENV" ] && [ "$VIRTUAL_ENV" != "$old_venv" ]; then
            _GOTO_ACTIVATED_VENV="$VIRTUAL_ENV"
            echo "Goto activated venv: $VIRTUAL_ENV"
        fi
    fi
}

_GOTO_PLUGIN_HOOKS="$_GOTO_PLUGIN_HOOKS __goto_plugin_test_venv_before_cd __goto_plugin_test_venv_after_cd"
EOF
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        
        # Mock cd and create venv directory when needed
        cd() {
            case \"\$1\" in
                *project-with-venv*)
                    mkdir -p venv
                    ;;
            esac
            return 0
        }
        
        _selected_dir='${TEST_HOME}/project-with-venv'
        __goto_change_dir
        echo \"Tracked venv: \${_GOTO_ACTIVATED_VENV}\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Mock: Activating venv" ]]
    [[ "$output" =~ "Goto activated venv:" ]]
    [[ "$output" =~ "Tracked venv:" ]]
}

# Test plugin error handling
@test "plugin errors don't break goto functionality" {
    # Create a plugin with an error
    cat > "${TEST_PLUGINS_DIR}/broken.plugin.sh" << 'EOF'
#!/bin/bash

broken_before_cd() {
    echo "Before hook with error"
    # Simulate an error
    false
}

broken_after_cd() {
    echo "After hook with error"
    # Simulate an error
    exit 1
}

_GOTO_PLUGIN_HOOKS="$_GOTO_PLUGIN_HOOKS broken_before_cd broken_after_cd"
EOF
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        
        # Mock cd
        cd() {
            echo \"cd called with: \$1\"
            return 0
        }
        
        _selected_dir='${TEST_HOME}/regular-project'
        __goto_change_dir
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Going to" ]]
    # Plugin errors should be suppressed but goto should still work
}

@test "hook function names are trimmed of whitespace" {
    # Create a plugin with hooks that have whitespace in registration
    cat > "${TEST_PLUGINS_DIR}/whitespace.plugin.sh" << 'EOF'
#!/bin/bash

trim_test_before_cd() {
    echo "Trimmed before hook executed"
}

trim_test_after_cd() {
    echo "Trimmed after hook executed"  
}

# Register with extra whitespace
_GOTO_PLUGIN_HOOKS="$_GOTO_PLUGIN_HOOKS  trim_test_before_cd   trim_test_after_cd  "
EOF
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        
        # Mock cd
        cd() {
            return 0
        }
        
        _selected_dir='${TEST_HOME}/regular-project'
        __goto_change_dir
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Trimmed before hook executed" ]]
    [[ "$output" =~ "Trimmed after hook executed" ]]
}

@test "only hooks with correct suffixes are called" {
    # Create functions with various suffixes
    cat > "${TEST_PLUGINS_DIR}/suffix-test.plugin.sh" << 'EOF'
#!/bin/bash

correct_before_cd() {
    echo "Correct before hook"
}

correct_after_cd() {
    echo "Correct after hook"
}

wrong_before() {
    echo "Wrong before hook"
}

wrong_after() {
    echo "Wrong after hook"
}

not_a_hook() {
    echo "Not a hook function"
}

_GOTO_PLUGIN_HOOKS="$_GOTO_PLUGIN_HOOKS correct_before_cd correct_after_cd wrong_before wrong_after not_a_hook"
EOF
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        
        # Mock cd
        cd() {
            return 0
        }
        
        _selected_dir='${TEST_HOME}/regular-project'
        __goto_change_dir
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Correct before hook" ]]
    [[ "$output" =~ "Correct after hook" ]]
    [[ ! "$output" =~ "Wrong before hook" ]]
    [[ ! "$output" =~ "Wrong after hook" ]]
    [[ ! "$output" =~ "Not a hook function" ]]
}

# Test plugin directory creation
@test "missing plugins directory doesn't cause errors" {
    # Remove plugins directory
    rm -rf "${TEST_PLUGINS_DIR}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        echo 'Script loaded successfully'
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Script loaded successfully" ]]
}

@test "empty plugins directory works correctly" {
    # Ensure plugins directory exists but is empty
    rm -f "${TEST_PLUGINS_DIR}"/*.plugin.sh
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        echo \"Plugin hooks: '\$_GOTO_PLUGIN_HOOKS'\"
    "
    [ "$status" -eq 0 ]
    # Should have empty or minimal hook list
    [[ "$output" =~ "Plugin hooks:" ]]
}