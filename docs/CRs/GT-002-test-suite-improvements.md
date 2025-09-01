- **Code**: GT-002
- **Title/Summary**: Complete BATS Test Suite Improvements and Standardization
- **Status**: Proposed
- **Date Created**: 2025-01-28
- **Type**: Technical Debt
- **Priority**: Medium
- **Phase/Epic**: Phase A (Foundation)

## Description

### Problem Statement
The BATS test suite has several incomplete areas and inconsistencies that need to be addressed to ensure comprehensive test coverage and reliability. While core functionality tests are working, there are remaining test files that need fixes and standardization.

### Current State
- Core functionality tests (`test/goto.bats`) are working with `--test` mode
- Several test files still need to be updated to use the new test environment pattern
- Some tests may be failing due to environment variable scoping issues
- Test files are not consistently using the new `GOTO_TEST_MODE=1` and `/tmp` directory patterns

### Desired State  
- All BATS tests should pass reliably using the new test patterns
- Consistent test environment setup across all test files
- Complete test coverage for all functionality areas
- Clean separation between core tests and extended functionality tests

### Rationale
Reliable automated testing is essential for maintaining code quality and preventing regressions. The recent improvements to support test mode (`--test` flag) and proper environment isolation need to be consistently applied across the entire test suite.

### Impact Areas
- Test reliability and CI/CD pipelines
- Developer confidence when making changes
- Code maintenance and regression prevention
- Documentation accuracy for test procedures

## Solution Analysis

### Approaches Considered
1. **Fix tests incrementally** - Update each test file individually as issues are discovered
2. **Complete test audit and fix** - Systematically review and fix all test files at once
3. **Hybrid approach** - Fix critical/core tests first, then address extended tests

### Trade-offs Analysis
- **Incremental fixes**: Lower immediate effort but may leave gaps and inconsistencies
- **Complete audit**: Higher upfront effort but ensures comprehensive coverage and consistency
- **Hybrid approach**: Balances immediate needs with long-term quality

### Decision Factors
- Test reliability is critical for ongoing development
- Consistency in test patterns reduces maintenance burden
- Complete coverage prevents surprises during CI/CD

### Chosen Approach
Hybrid approach: Core tests are already functional, focus on systematically fixing remaining test files using established patterns.

### Rejected Alternatives
- Incremental fixes were rejected due to risk of leaving gaps
- Complete rewrite was rejected as existing test structure is sound

## Implementation Specification

### Technical Requirements

#### Test Environment Standardization
1. **All test files must use:**
   - `export GOTO_TEST_MODE=1` to skip config file sourcing
   - `mktemp -d /tmp/goto-test-XXXXXX` for consistent temp directories
   - Proper variable exports in test environment setup
   - Helper functions where appropriate to reduce duplication

#### Test File Updates Needed
1. **`test/install.bats`** - Update all tests to use `GOTO_TEST_MODE=1` pattern
2. **`test/plugins.bats`** - Fix plugin loading and hook execution tests  
3. **`test/edge-cases.bats`** - Update remaining tests to use new patterns
4. **`test/extended.bats`** - Verify all moved tests work correctly

#### Test Coverage Verification
1. Run full test suite with `bash test/test-runner.sh`
2. Verify all tests pass consistently
3. Check for any missing test coverage areas
4. Update test documentation as needed

### Configuration Changes
- Ensure `_GOTO_MAX_DEPTH=${_GOTO_MAX_DEPTH:-1}` pattern is used consistently
- Verify all environment variables can be overridden for testing
- Update any hardcoded values that prevent test isolation

### Testing Requirements
- All existing functionality must remain working
- New test patterns should not break existing test workflows
- Test runner script should work with all updated test files

## Acceptance Criteria

- [ ] All BATS test files use consistent environment setup patterns
- [ ] `GOTO_TEST_MODE=1` is used in all tests that source goto.sh
- [ ] All temporary directories are created in `/tmp/goto-test-XXXXXX` format
- [ ] `bash test/test-runner.sh` runs without failures
- [ ] All individual test files can be run successfully with `bats test/filename.bats`
- [ ] Test documentation reflects current test organization and patterns
- [ ] No test relies on real user directories or system configuration
- [ ] Test isolation is complete (tests don't affect each other)
- [ ] Helper functions are used consistently where appropriate
- [ ] Test coverage includes all major functionality areas

## Implementation Notes
*(Initially empty - to be filled during/after implementation)*

### Completed Work
- Created `test/core.bats` with essential functionality tests
- Created `test/extended.bats` with advanced functionality tests  
- Updated `test/goto.bats` to contain only core tests with references to other files
- Fixed core test environment variable scoping issues
- Added `GOTO_TEST_MODE=1` support to skip config file sourcing
- Fixed `_GOTO_MAX_DEPTH` variable override issues

### Remaining Work
- Update `test/install.bats` with new environment patterns
- Fix `test/plugins.bats` plugin loading and testing
- Complete `test/edge-cases.bats` environment fixes
- Verify `test/extended.bats` functionality
- Run full test suite validation

## References

### Related Tasks
- Original BATS test implementation
- `--test` and `--verbose` mode implementation
- Test environment isolation improvements

### Code Changes
- `goto.sh`: Added `GOTO_TEST_MODE` support and variable override patterns
- `test/goto.bats`: Reduced to core tests only
- `test/core.bats`: New file with essential tests
- `test/extended.bats`: New file with advanced tests

### Documentation Updates
- `test/README.md`: Should be updated to reflect new test file organization
- Test runner documentation may need updates

### Related CRs
- None currently