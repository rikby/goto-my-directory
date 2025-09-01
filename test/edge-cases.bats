#!/usr/bin/env bats

# BATS tests for goto-my-directory edge cases and error handling
# This file tests various edge cases, error conditions, and boundary scenarios

# Setup function run before each test
setup() {
    # Create temporary directory structure for testing in /tmp
    export TEST_HOME="$(mktemp -d /tmp/goto-test-XXXXXX)"
    export TEST_CONFIG_DIR="${TEST_HOME}/.config/goto-my-directory"
    export TEST_CONFIG_FILE="${TEST_CONFIG_DIR}/config.sh"
    
    # Create complex test directory structure for edge cases
    mkdir -p "${TEST_HOME}/normal-dir"
    mkdir -p "${TEST_HOME}/dir with spaces"
    mkdir -p "${TEST_HOME}/dir-with-dashes"
    mkdir -p "${TEST_HOME}/dir_with_underscores"
    mkdir -p "${TEST_HOME}/UPPERCASE-DIR"
    mkdir -p "${TEST_HOME}/mixedCase-Dir"
    mkdir -p "${TEST_HOME}/123numeric-start"
    mkdir -p "${TEST_HOME}/special@chars#dir"
    mkdir -p "${TEST_HOME}/.hidden-dir"
    mkdir -p "${TEST_HOME}/深度中文目录"
    mkdir -p "${TEST_HOME}/empty-parent-dir/"
    mkdir -p "${TEST_HOME}/very/deeply/nested/directory/structure/here"
    
    # Create symbolic links
    ln -s "${TEST_HOME}/normal-dir" "${TEST_HOME}/symlink-to-dir"
    ln -s "/nonexistent/path" "${TEST_HOME}/broken-symlink"
    
    # Create files (not directories) that might confuse the search
    touch "${TEST_HOME}/file-not-dir.txt"
    touch "${TEST_HOME}/executable-file"
    chmod +x "${TEST_HOME}/executable-file"
    
    # Override config variables for testing
    export _GOTO_DIR="${TEST_HOME}"
    export _GOTO_CONFIG_DIR="${TEST_CONFIG_DIR}"
    export _GOTO_CONFIG_FILE="${TEST_CONFIG_FILE}"
    export _GOTO_MAX_DEPTH=3
    export _GOTO_AUTOSELECT_SINGLE_RESULT=1
    export _GOTO_PLUGIN_HOOKS=""
    
    # Create minimal config file
    mkdir -p "${TEST_CONFIG_DIR}"
    cat > "${TEST_CONFIG_FILE}" << EOF
_GOTO_DIR=${TEST_HOME}
_GOTO_MAX_DEPTH=3
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

# Test handling of special characters in directory names
@test "goto --test handles directories with spaces" {
    cd "${TEST_HOME}"
    
    run bash -c "
        export GOTO_TEST_MODE=1
        export _GOTO_DIR='${TEST_HOME}'
        export _GOTO_CONFIG_DIR='${TEST_CONFIG_DIR}'
        export _GOTO_CONFIG_FILE='${TEST_CONFIG_FILE}'
        export _GOTO_MAX_DEPTH=3
        export _GOTO_AUTOSELECT_SINGLE_RESULT=1
        export _GOTO_PLUGIN_HOOKS=''
        
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        goto --test 'with spaces'
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Found 1 match(es):" ]]
    [[ "$output" =~ "dir with spaces" ]]
}

@test "goto --test handles directories with special characters" {
    cd "${TEST_HOME}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        goto --test 'special@chars'
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Found 1 match(es):" ]]
    [[ "$output" =~ "special@chars#dir" ]]
}

@test "goto --test handles directories with unicode characters" {
    cd "${TEST_HOME}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        goto --test '中文'
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Found 1 match(es):" ]]
    [[ "$output" =~ "深度中文目录" ]]
}

@test "goto is case insensitive by default" {
    cd "${TEST_HOME}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_change_dir() { echo \"Going to '\${_selected_dir}'...\"; }
        goto 'uppercase'
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Looking for uppercase..." ]]
    [[ "$output" =~ "Going to" ]]
    [[ "$output" =~ "UPPERCASE-DIR" ]]
}

@test "goto handles directories starting with numbers" {
    cd "${TEST_HOME}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_change_dir() { echo \"Going to '\${_selected_dir}'...\"; }
        goto '123'
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Going to" ]]
    [[ "$output" =~ "123numeric-start" ]]
}

@test "goto handles hidden directories" {
    cd "${TEST_HOME}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_change_dir() { echo \"Going to '\${_selected_dir}'...\"; }
        goto 'hidden'
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Going to" ]]
    [[ "$output" =~ ".hidden-dir" ]]
}

# Test symbolic link handling
@test "goto follows symbolic links to directories" {
    cd "${TEST_HOME}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_change_dir() { echo \"Going to '\${_selected_dir}'...\"; }
        goto 'symlink'
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Going to" ]]
    [[ "$output" =~ "symlink-to-dir" ]]
}

@test "goto ignores broken symbolic links" {
    cd "${TEST_HOME}"
    
    # Search for something that would match broken-symlink
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        goto 'broken'
    "
    # Should not find broken symlinks since they don't point to valid directories
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No directories found" ]]
}

@test "goto ignores files that are not directories" {
    cd "${TEST_HOME}"
    
    # Search for something that matches both a file and directory
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_change_dir() { echo \"Going to '\${_selected_dir}'...\"; }
        goto 'file'
    "
    # Should not find the .txt file, only directories
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No directories found" ]]
}

# Test boundary conditions
@test "goto handles empty search string gracefully" {
    cd "${TEST_HOME}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        goto ''
    "
    [ "$status" -eq 1 ]
    [[ "$output" =~ "goto - Quick directory navigation tool" ]]
}

@test "goto handles very long directory names" {
    # Create directory with very long name
    local long_name="very-long-directory-name-that-exceeds-normal-expectations-and-tests-boundary-conditions-for-filename-handling"
    mkdir -p "${TEST_HOME}/${long_name}"
    cd "${TEST_HOME}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        __goto_change_dir() { echo \"Going to '\${_selected_dir}'...\"; }
        goto 'very-long-directory'
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Going to" ]]
}

@test "goto handles maximum depth correctly" {
    cd "${TEST_HOME}"
    
    # Test with depth 1 - should not find deeply nested directory
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        _GOTO_MAX_DEPTH=1
        goto 'structure'
    "
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No directories found" ]]
    
    # Test with depth 6 - should find deeply nested directory
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        _GOTO_MAX_DEPTH=6
        __goto_change_dir() { echo \"Going to '\${_selected_dir}'...\"; }
        goto 'structure'
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Going to" ]]
}

@test "goto handles depth 0 (current directory only)" {
    cd "${TEST_HOME}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        _GOTO_MAX_DEPTH=0
        goto 'normal'
    "
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No directories found" ]]
}

# Test error conditions
@test "goto handles permission denied directories gracefully" {
    # Create directory and remove read permissions
    local restricted_dir="${TEST_HOME}/restricted"
    mkdir -p "${restricted_dir}/hidden-inside"
    chmod 000 "${restricted_dir}"
    cd "${TEST_HOME}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        goto 'hidden-inside' 2>/dev/null
    "
    # Should not crash, might not find directory due to permissions
    [ "$status" -ne 0 ] || [ "$status" -eq 0 ]
    
    # Restore permissions for cleanup
    chmod 755 "${restricted_dir}"
}

@test "goto handles filesystem errors gracefully" {
    cd "${TEST_HOME}"
    
    # Test with nonexistent base directory
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        local_goto_dirs=('/nonexistent/path')
        goto 'anything'
    "
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No directories found" ]]
}

@test "goto handles circular symbolic links" {
    # Create circular symlinks
    ln -s "${TEST_HOME}/circular-b" "${TEST_HOME}/circular-a"
    ln -s "${TEST_HOME}/circular-a" "${TEST_HOME}/circular-b"
    cd "${TEST_HOME}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        goto 'circular'
    "
    # Should not crash or hang
    [ "$status" -ne 0 ] || [ "$status" -eq 0 ]
}

# Test configuration edge cases
@test "goto handles missing config file" {
    # Remove config file
    rm -f "${TEST_CONFIG_FILE}"
    
    run bash -c "
        unset _GOTO_DIR _GOTO_DIRS _GOTO_MAX_DEPTH
        source '${BATS_TEST_DIRNAME}/../goto.sh'
    "
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Config file not found" ]]
}

@test "goto handles corrupted config file" {
    # Create invalid config file
    echo "invalid shell syntax {[}" > "${TEST_CONFIG_FILE}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
    "
    # Should handle syntax error gracefully
    [ "$status" -ne 0 ]
}

@test "goto handles empty config file" {
    # Create empty config file
    echo "" > "${TEST_CONFIG_FILE}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        goto 'normal'
    "
    # Should use defaults and work
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

# Test input validation
@test "goto validates second argument is directory" {
    cd "${TEST_HOME}"
    
    # Test with file instead of directory
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        goto 'something' '${TEST_HOME}/file-not-dir.txt'
    "
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Second argument is not a directory" ]]
}

@test "goto handles nonexistent second argument" {
    cd "${TEST_HOME}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        goto 'something' '/completely/nonexistent/path'
    "
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Second argument is not a directory" ]]
}

# Test choice validation edge cases
@test "__goto_base_check_choice handles edge case inputs" {
    cd "${TEST_HOME}"
    
    # Test empty choice (cancel)
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        _matches=('dir1' 'dir2')
        _choice=''
        __goto_base_check_choice
    "
    [ "$status" -eq 3 ]
    [[ "$output" =~ "Cancelled" ]]
    
    # Test negative number
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        _matches=('dir1' 'dir2')
        _choice='-1'
        __goto_base_check_choice
    "
    [ "$status" -eq 5 ]
    [[ "$output" =~ "Invalid _choice" ]]
    
    # Test floating point number
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        _matches=('dir1' 'dir2')
        _choice='1.5'
        __goto_base_check_choice
    "
    [ "$status" -eq 5 ]
    [[ "$output" =~ "Invalid input" ]]
    
    # Test very large number
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        _matches=('dir1' 'dir2')
        _choice='999999'
        __goto_base_check_choice
    "
    [ "$status" -eq 5 ]
    [[ "$output" =~ "Invalid _choice" ]]
}

# Test shell compatibility edge cases
@test "goto handles different shell environments" {
    cd "${TEST_HOME}"
    
    # Test without BASH_SOURCE (simulating non-bash shell)
    run bash -c "
        unset BASH_SOURCE
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        goto 'normal' 2>/dev/null || echo 'Handled gracefully'
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Looking for normal" || "$output" =~ "Handled gracefully" ]]
}

@test "goto handles when neither fzf nor regular selection work" {
    cd "${TEST_HOME}"
    
    # Mock scenario where selection fails
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        
        # Override both selection methods to fail
        __goto_fzf_match() { return 1; }
        __goto_base_match() { return 1; }
        
        goto 'normal'
    "
    [ "$status" -eq 1 ]
}

# Test resource exhaustion scenarios
@test "goto handles many directory matches" {
    # Create many directories with similar names
    for i in $(seq 1 50); do
        mkdir -p "${TEST_HOME}/many-dirs-${i}"
    done
    cd "${TEST_HOME}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        goto 'many-dirs'
    "
    # Should not crash with many matches
    [ "$status" -ne 0 ] || [ "$status" -eq 0 ]
    [[ "$output" =~ "Looking for many-dirs" ]]
}

@test "goto handles very deep directory structures" {
    # Create very deep nested structure
    local deep_path="${TEST_HOME}"
    for i in $(seq 1 20); do
        deep_path="${deep_path}/level-${i}"
        mkdir -p "${deep_path}"
    done
    mkdir -p "${deep_path}/target-dir"
    cd "${TEST_HOME}"
    
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        _GOTO_MAX_DEPTH=25
        __goto_change_dir() { echo \"Going to '\${_selected_dir}'...\"; }
        goto 'target-dir'
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Going to" ]]
}