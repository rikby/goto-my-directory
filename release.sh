#!/usr/bin/env bash
#
# Release script for goto-my-directory project
# Creates a new release by updating the version and creating a git tag
#
# Usage: ./release.sh <version>
# Example: ./release.sh 0.3.0
#

set -euo pipefail

# Script directory detection - works regardless of how script is called
readonly __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly GOTO_SCRIPT="${__dir}/goto.sh"

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_INVALID_ARGS=1
readonly EXIT_INVALID_VERSION=2
readonly EXIT_FILE_NOT_FOUND=3
readonly EXIT_GIT_ERROR=4

# Function to display usage information
usage() {
    cat << EOF
Usage: $0 <version>

Creates a new release by:
1. Validating the version format (semantic versioning)
2. Updating _GOTO_VERSION in goto.sh
3. Committing the version change
4. Creating and pushing a git tag

Arguments:
  version    Version number in semantic versioning format (e.g., 1.2.3, 0.1.0)

Examples:
  $0 0.3.0
  $0 1.0.0
  $0 2.1.3

EOF
}

# Function to validate semantic version format
validate_version() {
    local version="$1"
    
    # Check if version matches semantic versioning pattern (X.Y.Z or X.Y.Z-suffix)
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
        echo "Error: Invalid version format. Expected semantic versioning (e.g., 1.2.3)" >&2
        return $EXIT_INVALID_VERSION
    fi
}

# Function to check if git working directory is clean
check_git_status() {
    if ! git diff-index --quiet HEAD --; then
        echo "Error: Working directory is not clean. Please commit or stash your changes first." >&2
        return $EXIT_GIT_ERROR
    fi
}

# Function to update version in goto.sh
update_version() {
    local version="$1"
    local backup_file="${GOTO_SCRIPT}.backup"
    
    # Create backup of original file
    cp "$GOTO_SCRIPT" "$backup_file"
    
    # Update version using sed with proper escaping
    if ! sed -i.tmp "s/^    _GOTO_VERSION=.*$/    _GOTO_VERSION=${version}/" "$GOTO_SCRIPT"; then
        echo "Error: Failed to update version in $GOTO_SCRIPT" >&2
        # Restore backup
        mv "$backup_file" "$GOTO_SCRIPT"
        return $EXIT_FILE_NOT_FOUND
    fi
    
    # Remove temporary file created by sed -i on macOS
    [[ -f "${GOTO_SCRIPT}.tmp" ]] && rm -f "${GOTO_SCRIPT}.tmp"
    
    # Verify the change was made
    if ! grep -q "^    _GOTO_VERSION=${version}$" "$GOTO_SCRIPT"; then
        echo "Error: Version update verification failed" >&2
        # Restore backup
        mv "$backup_file" "$GOTO_SCRIPT"
        return $EXIT_FILE_NOT_FOUND
    fi
    
    # Remove backup file
    rm -f "$backup_file"
    
    echo "Updated version to $version in $GOTO_SCRIPT"
}

# Function to create git commit and tag
create_release() {
    local version="$1"
    
    # Add the modified goto.sh file
    if ! git add "$GOTO_SCRIPT"; then
        echo "Error: Failed to stage $GOTO_SCRIPT" >&2
        return $EXIT_GIT_ERROR
    fi
    
    # Commit the version update
    if ! git commit -m "Bump version to ${version}"; then
        echo "Error: Failed to create commit" >&2
        return $EXIT_GIT_ERROR
    fi
    
    # Create annotated tag
    if ! git tag -a "v${version}" -m "Release version ${version}"; then
        echo "Error: Failed to create git tag" >&2
        return $EXIT_GIT_ERROR
    fi
    
    echo "Created git commit and tag v${version}"
}

# Main function
main() {
    # Check if version argument is provided
    if [[ $# -eq 0 ]]; then
        echo "Error: Version argument is required" >&2
        usage
        return $EXIT_INVALID_ARGS
    fi
    
    # Show help if requested
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        usage
        return $EXIT_SUCCESS
    fi
    
    local version="$1"
    
    # Validate inputs
    validate_version "$version" || return $?
    
    # Check if goto.sh exists
    if [[ ! -f "$GOTO_SCRIPT" ]]; then
        echo "Error: goto.sh not found at $GOTO_SCRIPT" >&2
        return $EXIT_FILE_NOT_FOUND
    fi
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "Error: Not in a git repository" >&2
        return $EXIT_GIT_ERROR
    fi
    
    # Check if working directory is clean
    check_git_status || return $?
    
    # Confirm the release
    echo "About to release version: $version"
    echo "This will:"
    echo "  1. Update _GOTO_VERSION in $GOTO_SCRIPT"
    echo "  2. Create a git commit"
    echo "  3. Create a git tag v${version}"
    echo
    read -p "Continue? (y/N): " -r confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Release cancelled"
        return $EXIT_SUCCESS
    fi
    
    # Perform the release
    update_version "$version" || return $?
    create_release "$version" || return $?
    
    echo
    echo "Successfully released version: $version"
    echo "To push to remote repository, run:"
    echo "  git push origin main"
    echo "  git push origin v${version}"
    
    return $EXIT_SUCCESS
}

# Execute main function if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi