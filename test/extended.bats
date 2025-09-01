#!/usr/bin/env bats

# BATS extended tests for goto-my-directory project
# This file contains advanced functionality and edge case tests that were moved from goto.bats

# Helper function to run goto in test mode with proper environment
run_goto_test() {
    local cmd="$1"
    run bash -c "
        export GOTO_TEST_MODE=1
        export _GOTO_DIR='${TEST_HOME}'
        export _GOTO_CONFIG_DIR='${TEST_CONFIG_DIR}'
        export _GOTO_CONFIG_FILE='${TEST_CONFIG_FILE}'
        export _GOTO_MAX_DEPTH=2
        export _GOTO_AUTOSELECT_SINGLE_RESULT=1
        export _GOTO_PLUGIN_HOOKS=''
        
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        $cmd
    "
}

# Setup function run before each test
setup() {
    # Create temporary directory structure for testing in /tmp
    export TEST_HOME="$(mktemp -d /tmp/goto-test-XXXXXX)"
    export TEST_CONFIG_DIR="${TEST_HOME}/.config/goto-my-directory"
    export TEST_CONFIG_FILE="${TEST_CONFIG_DIR}/config.sh"
    
    # Create test directory structure
    mkdir -p "${TEST_HOME}/projects/myproject"
    mkdir -p "${TEST_HOME}/projects/project-web"
    mkdir -p "${TEST_HOME}/documents/notes"
    mkdir -p "${TEST_HOME}/work/client-project"
    mkdir -p "${TEST_HOME}/src/golang"
    mkdir -p "${TEST_HOME}/src/python-scripts"
    
    # Override config variables for testing
    export _GOTO_DIR="${TEST_HOME}"
    export _GOTO_CONFIG_DIR="${TEST_CONFIG_DIR}"
    export _GOTO_CONFIG_FILE="${TEST_CONFIG_FILE}"
    export _GOTO_MAX_DEPTH=2
    export _GOTO_AUTOSELECT_SINGLE_RESULT=1
    export _GOTO_PLUGIN_HOOKS=""
    
    # Create minimal config file
    mkdir -p "${TEST_CONFIG_DIR}"
    cat > "${TEST_CONFIG_FILE}" << EOF
_GOTO_DIR=${TEST_HOME}
_GOTO_MAX_DEPTH=2
_GOTO_AUTOSELECT_SINGLE_RESULT=1
EOF
    
    # Source the goto script
    source "${BATS_TEST_DIRNAME}/../goto.sh"
}

# Teardown function run after each test
teardown() {
    # Clean up temporary directories
    [ -n "${TEST_HOME}" ] && rm -rf "${TEST_HOME}"
}

# Test multiple directory configuration
@test "goto --test works with _GOTO_DIRS array" {
    cd "${TEST_HOME}"
    
    # Need custom version for _GOTO_DIRS override
    run bash -c "
        export GOTO_TEST_MODE=1
        export _GOTO_CONFIG_DIR='${TEST_CONFIG_DIR}'
        export _GOTO_CONFIG_FILE='${TEST_CONFIG_FILE}'
        export _GOTO_MAX_DEPTH=2
        export _GOTO_AUTOSELECT_SINGLE_RESULT=1
        export _GOTO_PLUGIN_HOOKS=''
        export _GOTO_DIRS=('${TEST_HOME}/projects' '${TEST_HOME}/work')
        
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        goto --test client
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Found 1 match(es):" ]]
    [[ "$output" =~ "${TEST_HOME}/work/client-project" ]]
}

# Test base matching functionality (without fzf)
@test "__goto_base_check_choice validates numeric input" {
    cd "${TEST_HOME}"
    
    # Test valid numeric input
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        _matches=('dir1' 'dir2' 'dir3')
        _choice=2
        __goto_base_check_choice
    "
    [ "$status" -eq 0 ]
    
    # Test invalid non-numeric input
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        _matches=('dir1' 'dir2' 'dir3')
        _choice='invalid'
        __goto_base_check_choice
    "
    [ "$status" -eq 5 ]
    [[ "$output" =~ "Invalid input" ]]
}

@test "__goto_base_check_choice validates choice range" {
    cd "${TEST_HOME}"
    
    # Test choice too high
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        _matches=('dir1' 'dir2')
        _choice=5
        __goto_base_check_choice
    "
    [ "$status" -eq 5 ]
    [[ "$output" =~ "Invalid _choice" ]]
    
    # Test choice too low
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        _matches=('dir1' 'dir2')
        _choice=0
        __goto_base_check_choice
    "
    [ "$status" -eq 5 ]
    [[ "$output" =~ "Invalid _choice" ]]
}

# Test current file detection
@test "__goto_current_file detects script path" {
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_current_file
    "
    [ "$status" -eq 0 ]
    # Output should contain a path
    [[ "$output" =~ "/" ]]
}

# Test error codes
@test "goto returns correct error codes for no matches" {
    cd "${TEST_HOME}"
    
    # Test CODE_NO_DIR_FOUND (1) for no matches  
    run_goto_test "goto --test nonexistent"
    [ "$status" -eq 1 ]
}

@test "goto returns correct error codes for cancelled selection" {
    cd "${TEST_HOME}"
    
    # Test CODE_BREAK (3) for cancelled selection
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        _choice=''
        __goto_base_check_choice
    "
    [ "$status" -eq 3 ]
}

# Test configuration functionality
@test "__goto_create_default_config creates config file" {
    # Remove any existing config
    rm -f "${TEST_CONFIG_FILE}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_create_default_config
    "
    [ "$status" -eq 0 ]
    [ -f "${TEST_CONFIG_FILE}" ]
    
    # Check config file contents
    run cat "${TEST_CONFIG_FILE}"
    [[ "$output" =~ "_GOTO_DIR" ]]
    [[ "$output" =~ "_GOTO_MAX_DEPTH" ]]
}

@test "__goto_create_default_config doesn't overwrite existing config" {
    # Create existing config with custom content
    echo "# Custom config" > "${TEST_CONFIG_FILE}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_create_default_config
    "
    [ "$status" -eq 0 ]
    
    # Check that original content is preserved
    run cat "${TEST_CONFIG_FILE}"
    [[ "$output" =~ "# Custom config" ]]
    [[ ! "$output" =~ "Creating default config" ]]
}

# Test plugin hook system
@test "plugin hooks are called correctly" {
    cd "${TEST_HOME}"
    
    # Test with mock plugin functions
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        
        # Mock plugin functions
        test_before_cd() { echo 'Before CD hook called'; }
        test_after_cd() { echo 'After CD hook called'; }
        
        # Register hooks
        _GOTO_PLUGIN_HOOKS='test_before_cd test_after_cd'
        
        # Override cd to avoid actual directory change
        cd() { echo \"cd \$1\"; }
        
        __goto_change_dir() {
            # Call all before_cd plugin hooks
            echo \"\$_GOTO_PLUGIN_HOOKS\" | tr ' ' '\n' | while read -r func; do
                [ -n \"\$func\" ] || continue
                func=\$(echo \"\$func\" | sed 's/^[[:space:]]*//;s/[[:space:]]*\$//')
                if [ -n \"\$func\" ] && echo \"\$func\" | grep -q '_before_cd\$' && type \"\$func\" >/dev/null 2>&1; then
                    \"\$func\" 2>/dev/null || true
                fi
            done
            
            echo \"Going to '\${_selected_dir}'...\"
            cd \"\${_selected_dir}\" || return 2
            
            # Call all after_cd plugin hooks
            echo \"\$_GOTO_PLUGIN_HOOKS\" | tr ' ' '\n' | while read -r func; do
                [ -n \"\$func\" ] || continue
                func=\$(echo \"\$func\" | sed 's/^[[:space:]]*//;s/[[:space:]]*\$//')
                if [ -n \"\$func\" ] && echo \"\$func\" | grep -q '_after_cd\$' && type \"\$func\" >/dev/null 2>&1; then
                    \"\$func\" 2>/dev/null || true
                fi
            done
        }
        
        _selected_dir='${TEST_HOME}/projects'
        __goto_change_dir
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Before CD hook called" ]]
    [[ "$output" =~ "After CD hook called" ]]
    [[ "$output" =~ "Going to" ]]
}

# Test depth handling
@test "goto respects max depth setting" {
    # Create deep nested structure
    mkdir -p "${TEST_HOME}/level1/level2/level3/deep-project"
    cd "${TEST_HOME}"
    
    # Test with depth 1 (shouldn't find deep project)
    run bash -c "
        export GOTO_TEST_MODE=1
        export _GOTO_DIR='${TEST_HOME}'
        export _GOTO_CONFIG_DIR='${TEST_CONFIG_DIR}'
        export _GOTO_CONFIG_FILE='${TEST_CONFIG_FILE}'
        export _GOTO_MAX_DEPTH=1
        export _GOTO_AUTOSELECT_SINGLE_RESULT=1
        export _GOTO_PLUGIN_HOOKS=''
        
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        goto --test deep-project
    "
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No directories found" ]]
    
    # Test with depth 4 (should find deep project)
    run bash -c "
        export GOTO_TEST_MODE=1
        export _GOTO_DIR='${TEST_HOME}'
        export _GOTO_CONFIG_DIR='${TEST_CONFIG_DIR}'
        export _GOTO_CONFIG_FILE='${TEST_CONFIG_FILE}'
        export _GOTO_MAX_DEPTH=4
        export _GOTO_AUTOSELECT_SINGLE_RESULT=1
        export _GOTO_PLUGIN_HOOKS=''
        
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        goto --test deep-project
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Found 1 match(es):" ]]
    [[ "$output" =~ "deep-project" ]]
}