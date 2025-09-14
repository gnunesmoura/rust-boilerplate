---
mode: 'agent'
tools: ['GitHubCopilotTools']
description: 'Identify and solve a single code duplication from the CPD check results'
---

# Code Duplication Solver Agent

Your goal is to identify one code duplication from the CPD check results and systematically solve it by refactoring the duplicated code into a shared implementation.

## Step-by-Step Process

### 1. Run CPD Check and Analyze Results

- Execute the CPD check: `./scripts/quality-check.sh --only 08-cpd`
- Examine the output to identify duplications
- Choose one duplication to solve based on:
  - **Impact**: Duplications affecting multiple files or core functionality
  - **Type**: Prefer duplications that can be solved by creating an domain-specific helper function, macro, or module

### 2. Analyze the Chosen Duplication

- Read the CPD log file (`target/quality-logs/<timestamp>/cpd.txt`) to see the exact duplicated code
- Identify the files involved and the line ranges
- Understand what the duplicated code does:
  - Test setup/initialization
  - Data formatting or validation
  - Configuration building
  - Assertion patterns
  - Utility functions

### 3. Design the Refactoring Solution

Choose the appropriate refactoring strategy based on the duplication type:

#### For Test Setup Duplications
- Extract into a shared test helper function
- Create a test fixture or setup module
- Use parameterized tests if applicable

#### For Data Formatting Duplications
- Create a utility function in a shared module
- Use builder patterns for complex object construction
- Extract common validation logic

#### For Configuration Duplications
- Create builder methods or factory functions
- Extract common setup patterns into helper functions
- Use configuration templates

#### For Assertion Duplications
- Create custom assertion macros
- Extract assertion helper functions
- Use test helper traits

### 4. Implement the Solution

- Create the shared implementation (helper function, module, or macro)
- Replace the duplicated code in all affected files
- Ensure proper imports and dependencies
- Maintain identical functionality

### 5. Verify the Solution

- Run `cargo check` to ensure compilation
- Run relevant tests to verify functionality is preserved
- Re-run the CPD check (`./scripts/quality-check.sh --only 08-cpd`) to confirm the duplication is resolved
- Run `./scripts/quality-check.sh` to ensure no regressions

### 6. Document and Commit

- Add appropriate documentation for the new shared code
- Commit the changes with a clear message describing the refactoring
- Update any relevant comments or documentation

## Success Criteria

- The chosen duplication is completely eliminated
- All affected files compile successfully
- All tests pass
- CPD check shows reduced duplication count
- Code is more maintainable and follows DRY principles
- No functional changes to the codebase

## Notes

- Start with smaller, simpler duplications for easier wins
- Prefer extracting functions over macros when possible
- Ensure the shared code is placed in the appropriate module/crate
- Test thoroughly to avoid introducing bugs during refactoring
