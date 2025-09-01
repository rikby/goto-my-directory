#!/usr/bin/env bats

# BATS core tests for goto-my-directory project
# This file contains only the most essential functionality tests
# For additional tests, see: extended.bats, install.bats, plugins.bats, edge-cases.bats

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
    mkdir -p "${TEST_HOME}/work/client-project"
    mkdir -p "${TEST_HOME}/src/golang"
    
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

# Test help functionality
@test "goto shows help with -h flag" {
    run goto -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "goto - Quick directory navigation tool" ]]
    [[ "$output" =~ "Usage:" ]]
}

@test "goto shows help with --help flag" {
    run goto --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "goto - Quick directory navigation tool" ]]
    [[ "$output" =~ "Options:" ]]
}

@test "goto shows help when called with no arguments" {
    run goto
    [ "$status" -eq 1 ]
    [[ "$output" =~ "goto - Quick directory navigation tool" ]]
}

# Test core directory finding functionality
@test "goto --test finds multiple matching directories" {
    cd "${TEST_HOME}"
    
    run_goto_test "goto --test project"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Found 4 match(es):" ]]
    [[ "$output" =~ "${TEST_HOME}/projects" ]]
    [[ "$output" =~ "${TEST_HOME}/projects/myproject" ]]
    [[ "$output" =~ "${TEST_HOME}/projects/project-web" ]]
    [[ "$output" =~ "${TEST_HOME}/work/client-project" ]]
}

@test "goto --test finds single directory match" {
    cd "${TEST_HOME}"
    
    run_goto_test "goto --test golang"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Found 1 match(es):" ]]
    [[ "$output" =~ "${TEST_HOME}/src/golang" ]]
}

@test "goto --test handles no matches found" {
    cd "${TEST_HOME}"
    
    run_goto_test "goto --test nonexistent"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No directories found matching" ]]
}