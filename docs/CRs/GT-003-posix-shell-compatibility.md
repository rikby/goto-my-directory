- **Code**: GT-003
- **Title/Summary**: Improve POSIX Shell Compatibility and Fix Plugin Function Naming
- **Status**: Proposed
- **Date Created**: 2025-01-28
- **Type**: Technical Debt
- **Priority**: Medium
- **Phase/Epic**: Phase A (Foundation)

## Description

### Problem Statement
The goto.sh script currently has mixed shell compatibility requirements that cause issues in different shell environments. The script uses both POSIX features (marked with `#!/bin/sh` originally) and bash-specific features (arrays, `[[` syntax), creating inconsistency and compatibility issues.

### Current State
- Script shebang was changed from `#!/bin/sh` to `#!/usr/bin/env bash` 
- Plugin system uses function names with dashes (e.g., `venv-activate`) which can cause "invalid identifier" errors in strict modes
- Code mixes POSIX-compliant syntax with bash-specific features
- Shellcheck disable comments indicate awareness of POSIX incompatibility but no clear resolution strategy

### Desired State
- Clear decision on shell compatibility target (full POSIX vs bash-specific)
- Consistent function naming conventions that work across shells
- Plugin system that works reliably in chosen shell environment
- Clear documentation of shell requirements and compatibility

### Rationale
Shell compatibility issues create unpredictable behavior for users across different systems. The current hybrid approach causes confusion and maintenance overhead. A clear compatibility strategy will improve reliability and user experience.

### Impact Areas
- Plugin system reliability
- Cross-platform compatibility (Linux, macOS, BSD)
- Function naming conventions
- Shell feature usage (arrays, conditionals, etc.)
- Installation and deployment scripts

## Solution Analysis

### Approaches Considered

1. **Full POSIX Compatibility**
   - Pros: Maximum compatibility across all POSIX shells
   - Cons: Significant refactoring required, loss of convenient bash features
   - Impact: High development effort, requires rewriting array logic

2. **Full Bash-Specific**
   - Pros: Can use all bash features, simplifies code
   - Cons: Limits compatibility to bash-compatible shells
   - Impact: Requires fixing plugin function naming and shell strictness issues

3. **Hybrid with Clear Boundaries**
   - Pros: POSIX-compliant core with optional bash enhancements
   - Cons: Complex to maintain, dual code paths
   - Impact: Moderate effort, requires careful feature detection

### Trade-offs Analysis
- **POSIX compatibility** provides broader system support but limits feature richness
- **Bash-specific** allows modern shell features but reduces portability
- **Hybrid approach** offers flexibility but increases complexity

### Decision Factors
- Current codebase already uses bash features extensively (arrays, `[[` conditionals)
- Target users likely have bash available on modern systems
- Plugin system benefits from bash features
- Maintenance overhead of dual compatibility is significant

### Chosen Approach
**Full Bash-Specific with Compatibility Documentation**: Embrace bash as the target shell, fix bash compatibility issues, and clearly document bash requirement.

### Rejected Alternatives
- Full POSIX compatibility rejected due to extensive refactoring required
- Hybrid approach rejected due to maintenance complexity

## Implementation Specification

### Technical Requirements

#### Shell Environment Standardization
1. **Confirm bash requirement:**
   - Keep `#!/usr/bin/env bash` shebang
   - Update documentation to clearly state bash requirement
   - Add bash version requirement (recommend 4.0+ for associative arrays if needed)

2. **Fix function naming:**
   - Rename `venv-activate` to `venv_activate` (underscores are POSIX-compliant)
   - Update all plugin function names to use underscores instead of dashes
   - Update plugin hook registration to use new names

3. **Bash feature optimization:**
   - Embrace bash arrays throughout codebase
   - Use `[[ ]]` conditionals consistently (already partially done)
   - Optimize array handling code for bash-specific features
   - Remove unnecessary POSIX workarounds

#### Plugin System Updates
1. **Function naming convention:**
   - All functions: `snake_case` format
   - Plugin hooks: `__goto_plugin_name_before_cd` and `__goto_plugin_name_after_cd`
   - Utility functions: `venv_activate`, etc.

2. **Plugin loading robustness:**
   - Add error handling for plugin loading failures
   - Validate function names before registration
   - Provide clear error messages for plugin issues

#### Documentation Updates
1. **Requirements documentation:**
   - Bash 4.0+ requirement
   - Installation instructions for bash on different systems
   - Compatibility notes for different operating systems

2. **Plugin development guide:**
   - Updated function naming conventions
   - Best practices for bash-specific features
   - Plugin testing guidelines

### Configuration Changes
- No configuration file changes required
- Plugin naming convention changes only

### Testing Requirements
- Verify functionality in bash 4.x and 5.x
- Test plugin loading and function execution
- Validate error handling for malformed plugins
- Test on macOS, Linux, and WSL environments

## Acceptance Criteria

- [ ] Script explicitly requires and uses bash (documented shebang and requirements)
- [ ] All plugin functions use underscore naming convention (no dashes)
- [ ] `venv-activate` renamed to `venv_activate` throughout codebase
- [ ] Plugin hook registration uses updated function names
- [ ] No "invalid identifier" errors when loading plugins
- [ ] All existing functionality works in bash 4.0+
- [ ] Documentation clearly states bash requirement and version
- [ ] Plugin development guide updated with naming conventions
- [ ] Error handling provides clear messages for plugin loading failures
- [ ] BATS tests pass with updated plugin naming
- [ ] Installation process validates bash availability where possible

## Implementation Notes
*(Initially empty - to be filled during/after implementation)*

### Root Cause Analysis
The "invalid identifier" error occurs because:
1. Function names with dashes (`venv-activate`) are not valid identifiers in strict shell modes
2. The script changed from `#!/bin/sh` to `#!/usr/bin/env bash` but retained POSIX-style function naming
3. Bash in strict mode or certain contexts rejects dash-containing function names

### Current Plugin Issues
- `venv-activate.sh` defines `venv-activate()` function with dash in name
- Plugin loading occurs during script initialization, causing immediate error
- Error prevents proper script initialization and usage

## References

### Related Tasks
- Plugin system development and testing
- Shell compatibility testing across platforms
- Documentation updates for installation requirements

### Code Changes
- `plugins/venv-activate.sh`: Function name changes
- `goto.sh`: Plugin loading and hook registration updates
- Documentation files: Requirements and compatibility notes

### Documentation Updates
- `README.md`: Add bash requirement to prerequisites
- `PLUGIN_DEVELOPMENT.md`: Update naming conventions
- Installation documentation: Bash availability validation

### Related CRs
- GT-002: Test suite improvements (may need updates for new function names)
- Future: Plugin system enhancements may build on this foundation