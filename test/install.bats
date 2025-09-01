#!/usr/bin/env bats

# BATS tests for goto-my-directory installation functionality
# This file tests the installation and configuration features

# Setup function run before each test
setup() {
    # Create temporary directory structure for testing in /tmp
    export TEST_HOME="$(mktemp -d /tmp/goto-test-XXXXXX)"
    export TEST_CONFIG_DIR="${TEST_HOME}/.config/goto-my-directory"
    export TEST_CONFIG_FILE="${TEST_CONFIG_DIR}/config.sh"
    export TEST_RC_FILE="${TEST_HOME}/.bashrc"
    
    # Override config variables for testing
    export _GOTO_CONFIG_DIR="${TEST_CONFIG_DIR}"
    export _GOTO_CONFIG_FILE="${TEST_CONFIG_FILE}"
    export HOME="${TEST_HOME}"
    
    # Create a mock shell RC file
    touch "${TEST_RC_FILE}"
    
    # Source the goto script
    source "${BATS_TEST_DIRNAME}/../goto.sh"
}

# Teardown function run after each test
teardown() {
    # Clean up temporary directories
    [ -n "${TEST_HOME}" ] && rm -rf "${TEST_HOME}"
}

# Test installation functionality
@test "__goto_install creates config directory" {
    # Remove config directory if it exists
    rm -rf "${TEST_CONFIG_DIR}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_install '${TEST_RC_FILE}'
    "
    [ "$status" -eq 0 ]
    [ -d "${TEST_CONFIG_DIR}" ]
}

@test "__goto_install creates default config file" {
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_install '${TEST_RC_FILE}'
    "
    [ "$status" -eq 0 ]
    [ -f "${TEST_CONFIG_FILE}" ]
    
    # Check config file contents
    run cat "${TEST_CONFIG_FILE}"
    [[ "$output" =~ "_GOTO_DIR" ]]
    [[ "$output" =~ "_GOTO_MAX_DEPTH" ]]
    [[ "$output" =~ "_GOTO_AUTOSELECT_SINGLE_RESULT" ]]
}

@test "__goto_install adds source line to RC file" {
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_install '${TEST_RC_FILE}'
    "
    [ "$status" -eq 0 ]
    
    # Check that source line was added
    run grep -F ". \"${TEST_CONFIG_DIR}/goto.sh\"" "${TEST_RC_FILE}"
    [ "$status" -eq 0 ]
    
    # Check for installation markers
    run grep -F ">>> GOTO-MY-DIRECTORY initialize >>>" "${TEST_RC_FILE}"
    [ "$status" -eq 0 ]
    
    run grep -F "<<< GOTO-MY-DIRECTORY initialize <<<" "${TEST_RC_FILE}"
    [ "$status" -eq 0 ]
}

@test "__goto_install doesn't duplicate source line" {
    # First installation
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_install '${TEST_RC_FILE}'
    "
    [ "$status" -eq 0 ]
    
    # Second installation
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_install '${TEST_RC_FILE}'
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Source line already present" ]]
    
    # Check that source line appears only once
    run bash -c "grep -c '. \"${TEST_CONFIG_DIR}/goto.sh\"' '${TEST_RC_FILE}'"
    [[ "$output" == "1" ]]
}

@test "__goto_install copies script to config directory" {
    # Create a mock source script
    local source_script="${TEST_HOME}/goto.sh"
    cp "${BATS_TEST_DIRNAME}/../goto.sh" "${source_script}"
    
    run bash -c "
        # Override __goto_current_file to return our mock script
        __goto_current_file() { echo '${source_script}'; }
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_install '${TEST_RC_FILE}'
    "
    [ "$status" -eq 0 ]
    [ -f "${TEST_CONFIG_DIR}/goto.sh" ]
    [[ "$output" =~ "Copying script to" ]]
}

@test "__goto_install respects force-copy flag" {
    # Create existing script in config directory
    mkdir -p "${TEST_CONFIG_DIR}"
    echo "# Old script" > "${TEST_CONFIG_DIR}/goto.sh"
    
    # Create a mock source script
    local source_script="${TEST_HOME}/goto.sh"
    echo "# New script" > "${source_script}"
    
    # Test without force flag
    run bash -c "
        __goto_current_file() { echo '${source_script}'; }
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_install '${TEST_RC_FILE}'
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Script already exists" ]]
    
    # Verify old script is still there
    run cat "${TEST_CONFIG_DIR}/goto.sh"
    [[ "$output" =~ "# Old script" ]]
    
    # Test with force flag
    run bash -c "
        __goto_current_file() { echo '${source_script}'; }
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_install '${TEST_RC_FILE}' --force-copy
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Copying script to" ]]
    
    # Verify new script replaced old one
    run cat "${TEST_CONFIG_DIR}/goto.sh"
    [[ "$output" =~ "# New script" ]]
}

@test "__goto_install copies plugins directory" {
    # Create mock plugins directory
    local source_plugins="${TEST_HOME}/plugins"
    mkdir -p "${source_plugins}"
    echo "# Test plugin" > "${source_plugins}/test.plugin.sh"
    
    # Create a mock source script
    local source_script="${TEST_HOME}/goto.sh"
    cp "${BATS_TEST_DIRNAME}/../goto.sh" "${source_script}"
    
    run bash -c "
        __goto_current_file() { echo '${source_script}'; }
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_install '${TEST_RC_FILE}'
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Copying plugins to" ]]
    [ -d "${TEST_CONFIG_DIR}/plugins" ]
    [ -f "${TEST_CONFIG_DIR}/plugins/test.plugin.sh" ]
}

@test "__goto_install handles missing RC file" {
    # Remove RC file
    rm -f "${TEST_RC_FILE}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_install '${TEST_RC_FILE}'
    "
    [ "$status" -eq 0 ]
    [ -f "${TEST_RC_FILE}" ]
    
    # Check that source line was added
    run grep -F ". \"${TEST_CONFIG_DIR}/goto.sh\"" "${TEST_RC_FILE}"
    [ "$status" -eq 0 ]
}

@test "__goto_install fails with invalid RC file path" {
    local invalid_path="/nonexistent/dir/rcfile"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_install '${invalid_path}'
    "
    [ "$status" -eq 1 ]
    [[ "$output" =~ "does not exist and could not be created" ]]
}

@test "__goto_install detects shell type automatically" {
    # Test bash detection
    export SHELL="/bin/bash"
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_install
    "
    [ "$status" -eq 0 ]
    
    # Test zsh detection
    export SHELL="/usr/local/bin/zsh"
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_install
    "
    [ "$status" -eq 0 ]
}

# Test configuration functionality
@test "__goto_create_default_config creates proper structure" {
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_create_default_config
    "
    [ "$status" -eq 0 ]
    [ -d "${TEST_CONFIG_DIR}" ]
    [ -f "${TEST_CONFIG_FILE}" ]
    [[ "$output" =~ "Creating default config file" ]]
}

@test "__goto_create_default_config preserves existing config" {
    # Create existing config
    mkdir -p "${TEST_CONFIG_DIR}"
    echo "# Existing config" > "${TEST_CONFIG_FILE}"
    echo "_GOTO_DIR=/custom/path" >> "${TEST_CONFIG_FILE}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_create_default_config
    "
    [ "$status" -eq 0 ]
    
    # Verify existing content is preserved
    run cat "${TEST_CONFIG_FILE}"
    [[ "$output" =~ "# Existing config" ]]
    [[ "$output" =~ "_GOTO_DIR=/custom/path" ]]
    [[ ! "$output" =~ "Creating default config file" ]]
}

@test "__goto_config creates and opens config file" {
    # Remove existing config
    rm -f "${TEST_CONFIG_FILE}"
    
    # Mock editors to avoid interactive editing
    run bash -c "
        nano() { echo 'nano called on' \"\$1\"; }
        vi() { echo 'vi called on' \"\$1\"; }
        export -f nano vi
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_config
    "
    [ "$status" -eq 0 ]
    [ -f "${TEST_CONFIG_FILE}" ]
    [[ "$output" =~ "nano called on" || "$output" =~ "vi called on" ]]
}

@test "goto --install flag works correctly" {
    run bash -c "
        cd '${BATS_TEST_DIRNAME}/..'
        ./goto.sh --install '${TEST_RC_FILE}'
    "
    [ "$status" -eq 0 ]
    [ -f "${TEST_CONFIG_FILE}" ]
    
    # Check that source line was added
    run grep -F ". \"${TEST_CONFIG_DIR}/goto.sh\"" "${TEST_RC_FILE}"
    [ "$status" -eq 0 ]
}

@test "goto --update-code flag works correctly" {
    # Create existing config
    mkdir -p "${TEST_CONFIG_DIR}"
    echo "# Old script" > "${TEST_CONFIG_DIR}/goto.sh"
    
    run bash -c "
        cd '${BATS_TEST_DIRNAME}/..'
        ./goto.sh --update-code '${TEST_RC_FILE}'
    "
    [ "$status" -eq 0 ]
    
    # Verify script was updated
    run head -1 "${TEST_CONFIG_DIR}/goto.sh"
    [[ "$output" =~ "#!/bin/sh" ]]
}

@test "goto --config flag works correctly" {
    # Mock editors to avoid interactive editing
    run bash -c "
        nano() { echo 'Config opened'; return 0; }
        vi() { echo 'Config opened'; return 0; }
        export -f nano vi
        cd '${BATS_TEST_DIRNAME}/..'
        ./goto.sh --config
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Config opened" ]]
}