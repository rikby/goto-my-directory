#!/bin/bash

# Test runner script for goto-my-directory BATS tests
# This script provides a convenient way to run all tests or specific test files

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BATS_EXECUTABLE=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to find BATS executable
find_bats() {
    # Try common locations for BATS
    local bats_locations=(
        "bats"                    # In PATH
        "/usr/local/bin/bats"     # Homebrew on macOS
        "/opt/homebrew/bin/bats"  # Homebrew on Apple Silicon
        "/usr/bin/bats"           # System package on Linux
        "${HOME}/.local/bin/bats" # Local installation
        "./node_modules/.bin/bats" # npm installation
    )
    
    for bats_path in "${bats_locations[@]}"; do
        if command -v "$bats_path" >/dev/null 2>&1; then
            BATS_EXECUTABLE="$bats_path"
            return 0
        fi
    done
    
    return 1
}

# Function to install BATS if not found
install_bats() {
    print_color "$YELLOW" "BATS not found. Would you like to install it? [y/N]"
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY])
            print_color "$BLUE" "Installing BATS..."
            if command -v brew >/dev/null 2>&1; then
                brew install bats-core
            elif command -v npm >/dev/null 2>&1; then
                npm install -g bats
            elif command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y bats
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y bats
            else
                print_color "$RED" "Could not detect package manager. Please install BATS manually."
                print_color "$BLUE" "Visit: https://github.com/bats-core/bats-core"
                exit 1
            fi
            
            # Try to find BATS again after installation
            if find_bats; then
                print_color "$GREEN" "BATS installed successfully: $BATS_EXECUTABLE"
            else
                print_color "$RED" "BATS installation failed or not found in PATH"
                exit 1
            fi
            ;;
        *)
            print_color "$RED" "BATS is required to run tests. Exiting."
            exit 1
            ;;
    esac
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [TEST_FILES...]

Run BATS tests for goto-my-directory project.

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Run tests in verbose mode
    -t, --tap           Output in TAP format
    -p, --pretty        Pretty print output (default)
    -r, --recursive     Run tests recursively
    -j, --jobs N        Run tests in parallel with N jobs
    -T, --timing        Show timing information
    --install-bats      Install BATS if not found
    --list              List available test files
    --coverage          Run with coverage (if supported)

TEST_FILES:
    If no test files are specified, all .bats files in the test directory will be run.
    You can specify individual test files or patterns:
        $0 goto.bats                    # Run only goto.bats
        $0 goto.bats install.bats       # Run specific test files
        $0 test/*.bats                  # Run all .bats files (default)

EXAMPLES:
    $0                                  # Run all tests
    $0 -v                              # Run all tests in verbose mode
    $0 --jobs 4                        # Run tests in parallel with 4 jobs
    $0 goto.bats                       # Run only goto functionality tests
    $0 -t > test-results.tap           # Output TAP format to file

Available test files:
    goto.bats       - Core goto functionality tests
    install.bats    - Installation and configuration tests
    plugins.bats    - Plugin system tests
    edge-cases.bats - Edge cases and error handling tests

EOF
}

# Function to list available test files
list_test_files() {
    print_color "$BLUE" "Available test files in ${SCRIPT_DIR}:"
    for test_file in "${SCRIPT_DIR}"/*.bats; do
        if [ -f "$test_file" ]; then
            local basename=$(basename "$test_file")
            local description=""
            case "$basename" in
                goto.bats)       description="Core goto functionality tests" ;;
                install.bats)    description="Installation and configuration tests" ;;
                plugins.bats)    description="Plugin system tests" ;;
                edge-cases.bats) description="Edge cases and error handling tests" ;;
                *)               description="Custom test file" ;;
            esac
            printf "  %-20s - %s\n" "$basename" "$description"
        fi
    done
}

# Function to run tests
run_tests() {
    local bats_args=()
    local test_files=()
    local verbose=false
    local jobs=""
    local output_format="pretty"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -t|--tap)
                output_format="tap"
                shift
                ;;
            -p|--pretty)
                output_format="pretty"
                shift
                ;;
            -r|--recursive)
                bats_args+=("--recursive")
                shift
                ;;
            -j|--jobs)
                if [[ -n $2 && $2 =~ ^[0-9]+$ ]]; then
                    jobs="$2"
                    shift 2
                else
                    print_color "$RED" "Error: --jobs requires a numeric argument"
                    exit 1
                fi
                ;;
            -T|--timing)
                bats_args+=("--timing")
                shift
                ;;
            --install-bats)
                install_bats
                exit 0
                ;;
            --list)
                list_test_files
                exit 0
                ;;
            --coverage)
                print_color "$YELLOW" "Coverage not yet implemented"
                shift
                ;;
            -*)
                print_color "$RED" "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                # Check if argument is a test file
                if [[ "$1" == *.bats ]]; then
                    # If it's just a filename, add the script directory path
                    if [[ ! "$1" =~ / ]]; then
                        test_files+=("${SCRIPT_DIR}/$1")
                    else
                        test_files+=("$1")
                    fi
                else
                    # Assume it's a pattern or directory
                    test_files+=("$1")
                fi
                shift
                ;;
        esac
    done
    
    # Set up BATS arguments based on options
    case $output_format in
        tap)
            bats_args+=("--formatter" "tap")
            ;;
        pretty)
            bats_args+=("--formatter" "pretty")
            ;;
    esac
    
    if [[ -n $jobs ]]; then
        bats_args+=("--jobs" "$jobs")
    fi
    
    # If no test files specified, run all .bats files in test directory
    if [[ ${#test_files[@]} -eq 0 ]]; then
        for bats_file in "${SCRIPT_DIR}"/*.bats; do
            [[ -f "$bats_file" ]] && test_files+=("$bats_file")
        done
    fi
    
    # Verify test files exist
    for test_file in "${test_files[@]}"; do
        if [[ ! -f "$test_file" ]]; then
            print_color "$RED" "Error: Test file not found: $test_file"
            exit 1
        fi
    done
    
    # Display test information
    print_color "$BLUE" "Running BATS tests for goto-my-directory"
    print_color "$BLUE" "Test directory: $SCRIPT_DIR"
    print_color "$BLUE" "Project directory: $PROJECT_DIR"
    print_color "$BLUE" "BATS executable: $BATS_EXECUTABLE"
    
    if [[ ${#test_files[@]} -gt 0 ]]; then
        print_color "$BLUE" "Test files:"
        for test_file in "${test_files[@]}"; do
            echo "  - $(basename "$test_file")"
        done
    fi
    
    echo
    
    # Change to project directory for tests
    cd "$PROJECT_DIR"
    
    # Run the tests
    if $verbose; then
        print_color "$GREEN" "Running tests in verbose mode..."
        echo
        "$BATS_EXECUTABLE" "${bats_args[@]}" "${test_files[@]}" --verbose-run
    else
        "$BATS_EXECUTABLE" "${bats_args[@]}" "${test_files[@]}"
    fi
    
    local exit_code=$?
    
    # Display results
    echo
    if [[ $exit_code -eq 0 ]]; then
        print_color "$GREEN" "✅ All tests passed!"
    else
        print_color "$RED" "❌ Some tests failed (exit code: $exit_code)"
    fi
    
    return $exit_code
}

# Main execution
main() {
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    # Find BATS executable
    if ! find_bats; then
        print_color "$RED" "BATS testing framework not found!"
        install_bats
    else
        print_color "$GREEN" "Found BATS: $BATS_EXECUTABLE"
    fi
    
    # Verify we're in a goto-my-directory project
    if [[ ! -f "$PROJECT_DIR/goto.sh" ]]; then
        print_color "$RED" "Error: This doesn't appear to be a goto-my-directory project directory"
        print_color "$RED" "Expected to find goto.sh in: $PROJECT_DIR"
        exit 1
    fi
    
    # Run tests with all arguments
    run_tests "$@"
}

# Handle special cases for direct argument processing
case "${1:-}" in
    --help|-h)
        show_usage
        exit 0
        ;;
    --list)
        list_test_files
        exit 0
        ;;
    --install-bats)
        find_bats || install_bats
        exit 0
        ;;
esac

# Run main function with all arguments
main "$@"