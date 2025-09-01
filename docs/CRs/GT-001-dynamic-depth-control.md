- **Code**: GT-001
- **Title/Summary**: Add dynamic depth control with -N flags
- **Status**: Proposed
- **Date Created**: 2025-09-01
- **Type**: Feature Enhancement
- **Priority**: Medium
- **Phase/Epic**: Phase A (Foundation)

## Description

### Problem Statement
Currently, the goto tool uses a fixed maximum depth setting (`_GOTO_MAX_DEPTH`) that applies to all searches. Users cannot adjust search depth on a per-command basis, which limits flexibility when searching in directory structures of varying depths.

### Current State
- Search depth is controlled by global `_GOTO_MAX_DEPTH` configuration variable (default: 1)
- Users must modify config file to change search depth
- All goto commands use the same depth setting

### Desired State
- Support dynamic depth control via command-line flags: `-2`, `-5`, `-10`, etc.
- Special `-0` flag for infinite depth (removes maxdepth constraint)
- Maintain backward compatibility with existing configuration
- Allow combining depth flags with existing custom directory feature

### Rationale
- Improves user experience by allowing ad-hoc depth adjustments
- Eliminates need to modify configuration for one-off deeper searches
- Maintains consistency with other command-line tools that use numbered flags
- Essential for navigating complex project structures with varying depths

### Impact Areas
- Argument parsing logic in `goto()` function
- Help documentation and examples
- Integration with existing custom directory path feature (`goto name /path`)

## Solution Analysis

### Approaches Considered

1. **Flag-based approach with -N syntax** (Chosen)
   - Use `-2`, `-5`, `-0` style flags
   - Simple to parse and understand
   - Consistent with common CLI patterns

2. **--depth=N option**
   - More verbose but explicit
   - Requires more complex parsing
   - Less concise for frequent use

3. **Positional depth parameter**
   - Would break existing API
   - Less intuitive than flags

### Trade-offs Analysis
- **Chosen approach benefits**: Concise, intuitive, matches user request exactly
- **Chosen approach drawbacks**: Slightly more complex argument parsing
- **Decision factors**: User preference, simplicity, CLI convention alignment

### Chosen Approach
Implement `-N` flag parsing that:
- Extracts numeric flags during argument processing
- Sets `_GOTO_MAX_DEPTH` dynamically for the current command
- Handles `-0` as special case for infinite depth
- Integrates with existing custom directory feature

### Rejected Alternatives
- Long-form `--depth` option: Too verbose for frequent use
- Environment variable: Less discoverable and requires export

## Implementation Specification

### Technical Requirements

1. **Argument Parsing Enhancement**
   - Parse `-[0-9]*` patterns as depth flags
   - Extract numeric value and set `_GOTO_MAX_DEPTH` temporarily
   - Handle `-0` by setting `_GOTO_MAX_DEPTH` to empty string (removes constraint)
   - Support combinations like `goto proj -3 /custom/path`

2. **Function Modifications**
   - Update `goto()` function argument processing loop
   - Add depth flag detection and parsing
   - Modify `__goto_find_dirs()` to handle empty maxdepth for infinite search

3. **Integration Points**
   - Works with existing custom directory feature
   - Maintains compatibility with fzf and base matching
   - Preserves all current functionality

### API Changes
New usage patterns:
- `goto projectname -2` - Search with depth 2
- `goto projectname -5 /custom/path` - Search in custom path with depth 5  
- `goto projectname -0` - Search with infinite depth

### Configuration
- No configuration file changes required
- Dynamic depth overrides configured `_GOTO_MAX_DEPTH` for single command
- Original config value preserved for subsequent commands

## Acceptance Criteria

- [ ] `-N` flags (e.g., `-2`, `-5`) set search depth for current command only
- [ ] `-0` flag enables infinite depth search (removes maxdepth constraint)
- [ ] Depth flags work in combination with custom directory paths
- [ ] All existing functionality remains unchanged
- [ ] Help text documents new depth flag options
- [ ] Invalid depth values show appropriate error messages
- [ ] Multiple depth flags use the last one specified
- [ ] Works with both fzf and base selection interfaces

## Implementation Notes
(To be filled during/after implementation)

## References
- **Related Tasks**: Original custom path feature implementation
- **Code Changes**: `goto.sh` argument parsing section (lines ~84-103)
- **Documentation Updates**: Help text in `show_help()` function
- **Related CRs**: None