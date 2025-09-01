# Test Suite for goto-my-directory

This directory contains a comprehensive test suite for the goto-my-directory project using the [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core) framework.

## Test Files

### Core Test Files

- **`goto.bats`** - Core essential tests: help system, basic directory finding, test mode functionality
- **`extended.bats`** - Advanced functionality tests: choice validation, plugin hooks, depth handling, _GOTO_DIRS arrays
- **`install.bats`** - Tests installation and configuration functionality including script copying, RC file modification, and config file creation  
- **`plugins.bats`** - Tests the plugin system including plugin loading, hook registration, and the venv-activate plugin
- **`edge-cases.bats`** - Tests edge cases and error handling including special characters, boundary conditions, and error scenarios

### Test Runner

- **`test-runner.sh`** - Comprehensive test runner script with options for verbose output, parallel execution, and test selection
- **`README.md`** - This documentation file

## Quick Start

### Prerequisites

The tests require BATS to be installed. The test runner can automatically install BATS if it's not found:

```bash
# Install BATS automatically
./test/test-runner.sh --install-bats

# Or install manually:
# On macOS with Homebrew:
brew install bats-core

# On Ubuntu/Debian:
sudo apt-get install bats

# With npm:
npm install -g bats
```

### Running Tests

```bash
# Run all tests
./test/test-runner.sh

# Run specific test file
./test/test-runner.sh goto.bats

# Run multiple specific test files
./test/test-runner.sh goto.bats install.bats

# Run tests in verbose mode
./test/test-runner.sh -v

# Run tests in parallel (faster execution)
./test/test-runner.sh --jobs 4

# List available test files
./test/test-runner.sh --list
```

### Alternative: Direct BATS Execution

If you have BATS installed, you can run tests directly:

```bash
# Run all tests
bats test/*.bats

# Run specific test file
bats test/goto.bats

# Run with verbose output
bats test/*.bats --verbose-run
```

## Test Structure

### Setup and Teardown

Each test file includes:
- **setup()** - Creates temporary test environment with mock directory structures
- **teardown()** - Cleans up temporary files and directories after each test

### Test Environment

Tests run in isolated temporary directories to avoid affecting the actual system:
- `TEST_HOME` - Temporary home directory for tests
- `TEST_CONFIG_DIR` - Temporary config directory
- Mock directory structures with various naming patterns and edge cases

### Mocking Strategy

Tests use mocking to avoid side effects:
- Override `cd` command to prevent actual directory changes
- Mock external dependencies like `fzf`
- Create isolated temporary file systems
- Override environment variables for testing

## Test Coverage

### goto.bats
- ✅ Help functionality (`-h`, `--help`, no args)
- ✅ Directory finding with `__goto_find_dirs`
- ✅ Single directory matching and auto-selection
- ✅ Custom search path functionality
- ✅ Multiple directory configuration (`_GOTO_DIRS`)
- ✅ Base matching without fzf
- ✅ Input validation and choice checking
- ✅ Error codes and return values
- ✅ Configuration file creation
- ✅ Plugin hook system basics

### install.bats
- ✅ Installation directory and config file creation
- ✅ RC file modification and source line addition
- ✅ Script copying to config directory
- ✅ Plugin directory copying
- ✅ Force update functionality
- ✅ Shell type detection (bash, zsh, etc.)
- ✅ Command line flag processing (`--install`, `--config`, etc.)
- ✅ Error handling for invalid paths

### plugins.bats
- ✅ Plugin loading from `.plugin.sh` files
- ✅ Plugin hook registration system
- ✅ Hook execution during directory changes
- ✅ venv-activate plugin functionality
- ✅ Plugin error handling and isolation
- ✅ Hook naming conventions and filtering
- ✅ Multiple plugin support

### edge-cases.bats
- ✅ Special characters in directory names (spaces, unicode, symbols)
- ✅ Case-insensitive directory matching
- ✅ Symbolic link handling (valid and broken)
- ✅ File vs directory filtering
- ✅ Boundary conditions (empty strings, very long names)
- ✅ Maximum depth handling and validation
- ✅ Permission errors and filesystem issues
- ✅ Configuration file edge cases (missing, corrupted, empty)
- ✅ Input validation for all parameters
- ✅ Shell compatibility scenarios
- ✅ Resource exhaustion scenarios (many matches, deep structures)

## Test Configuration

### Environment Variables

Tests override these variables to create isolated environments:
- `TEST_HOME` - Temporary test directory
- `_GOTO_DIR` - Root directory for testing
- `_GOTO_CONFIG_DIR` - Config directory location
- `_GOTO_CONFIG_FILE` - Config file path
- `_GOTO_MAX_DEPTH` - Search depth limit
- `_GOTO_AUTOSELECT_SINGLE_RESULT` - Auto-selection behavior

### Mock Directory Structure

Tests create standardized directory structures:
```
TEST_HOME/
├── normal-dir/
├── dir with spaces/
├── dir-with-dashes/
├── UPPERCASE-DIR/
├── projects/
│   ├── myproject/
│   └── project-web/
├── work/
│   └── client-project/
└── very/deeply/nested/directory/structure/
```

## Continuous Integration

The test suite is designed to work in CI environments:
- No external dependencies beyond BATS
- Self-contained temporary environments
- No network requirements
- Cross-platform compatibility (Linux, macOS, Windows with WSL)

### Example GitHub Actions Integration

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install BATS
        run: sudo apt-get update && sudo apt-get install -y bats
      - name: Run tests
        run: ./test/test-runner.sh
```

## Contributing to Tests

### Adding New Tests

1. **Choose the appropriate test file** based on functionality area
2. **Follow naming conventions** - test names should be descriptive
3. **Use setup/teardown** for proper test isolation  
4. **Mock external dependencies** to avoid side effects
5. **Test both success and failure cases**

### Test Writing Guidelines

```bash
@test "descriptive test name that explains what is being tested" {
    # Arrange - set up test conditions
    cd "${TEST_HOME}"
    
    # Act - execute the functionality being tested
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../goto.sh'
        goto 'test-input'
    "
    
    # Assert - verify expected outcomes
    [ "$status" -eq 0 ]
    [[ "$output" =~ "expected output pattern" ]]
}
```

### Best Practices

- **Isolation** - Each test should be independent
- **Clarity** - Test names should clearly describe what is being tested
- **Coverage** - Test both positive and negative scenarios
- **Mocking** - Avoid side effects by mocking system interactions
- **Documentation** - Add comments for complex test scenarios

## Troubleshooting

### Common Issues

**BATS not found**
```bash
# Install BATS using the test runner
./test/test-runner.sh --install-bats
```

**Tests failing due to permissions**
```bash
# Ensure test runner is executable
chmod +x ./test/test-runner.sh
```

**Temporary directory cleanup issues**
```bash
# Manually clean up if tests are interrupted
rm -rf /tmp/tmp.* 2>/dev/null || true
```

**Tests failing on different shells**
```bash
# Run tests with bash specifically
bash ./test/test-runner.sh
```

## Performance

The test suite is optimized for performance:
- **Parallel execution** supported with `--jobs` flag
- **Minimal disk I/O** using temporary filesystems
- **Fast setup/teardown** with efficient directory creation
- **Selective testing** allows running specific test files

Typical execution times:
- All tests: ~30-60 seconds
- Individual test files: ~5-15 seconds each
- Parallel execution: ~15-30 seconds (with `--jobs 4`)