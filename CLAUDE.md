# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flashforge Forge-X is a firmware modification for the Flashforge Adventurer 5M (Pro) 3D printer that replaces stock firmware with Klipper, Moonraker, Mainsail, and Fluidd. This enables advanced 3D printing features and web-based control.

**CRITICAL**: This firmware directly controls 3D printer hardware including stepper motors, heaters, and sensors. Incorrect modifications can damage the printer or void warranties.

## Key Commands

### Deployment
```bash
# Deploy changes to printer (most common command)
./sync.sh --host <printer_ip>

# Deploy without restarting services (faster for config changes)
./sync.sh --host <printer_ip> --skip-restart

# Deploy only macros (quickest for macro development)  
./sync.sh --host <printer_ip> --profile macros
```

### G-code Processing
```bash
# Add MD5 checksum to G-code files for verification
./addMD5.sh your_file.gcode
```

## Architecture

The mod consists of configuration files that control printer behavior:

- **Klipper configs (.cfg)**: Hardware control, motion planning, macros
- **Moonraker config**: Web API server configuration  
- **Shell scripts**: Development and deployment utilities
- **SQL migrations**: Database schema updates for new features

### Configuration Structure
- `config/` - Screen variants (stock/feather/headless)
- `macros/` - G-code macro definitions for printer operations
- `KAMP/` - Adaptive bed meshing configuration
- `tuning.cfg` - Hardware parameter optimizations

## Mod Configuration System

The mod uses G-code macros for runtime configuration:

```gcode
LIST_MOD_PARAMS          # Show all available parameters
GET_MOD PARAM=<name>     # Get current value
SET_MOD PARAM=<name> VALUE=<value>  # Set new value
```

Critical parameters:
- `tune_klipper=1` - Fixes communication timeout errors (E0011/E0017)
- `tune_config=1` - Enables optimized settings (requires full recalibration)
- `check_md5=1` - Enables G-code file verification
- `use_kamp=1` - Enables adaptive bed meshing

## Development Workflow

1. Modify configuration files locally
2. Deploy using `sync.sh` with appropriate profile
3. Test through web interfaces or printer screen
4. **Mandatory**: Recalibrate bed mesh and Z-offset after hardware changes

## Access Points
- Moonraker: `http://<printer_ip>:7125/`
- Fluidd: `http://<printer_ip>/fluidd/`  
- Mainsail: `http://<printer_ip>/mainsail/`
- SSH: `root/root`

## Safety Notes

- Always backup configurations before changes
- Hardware control changes require printer restart and recalibration
- The mod includes dual-boot and recovery mechanisms
- Test changes incrementally, never in bulk

## Git Workflow Integration

This repository uses a dual-remote setup for development:
- **origin**: https://github.com/Chadillac12/ff5m.git (your development fork)  
- **upstream**: https://github.com/DrA1ex/ff5m.git (original repository)

### Commit Guidelines
- **Frequent commits**: Make atomic commits for each logical change
- **Descriptive messages**: Use format `type(scope): description`
- **Feature branches**: Create branches for significant changes
- **Clean history**: Rebase/squash before pushing to upstream

### When to Commit
✅ **DO commit when:**
- Configuration changes work and are tested
- Documentation sections are complete
- Bug fixes are validated
- Features reach stable checkpoints

❌ **DON'T commit when:**
- Code has syntax errors or doesn't work
- Changes are incomplete or experimental
- Tests are failing (unless WIP)

### Push to Upstream
```bash
# After feature completion
git push upstream feature/branch-name
# Then create PR to original repository
```

See `GIT_WORKFLOW_GUIDE.md` for comprehensive workflow instructions.

# Using Gemini CLI for Large Codebase Analysis

When analyzing large codebases or multiple files that might exceed context limits, use the Gemini CLI with its massive
context window. Use `gemini -p` to leverage Google Gemini's large context capacity.

## File and Directory Inclusion Syntax

Use the `@` syntax to include files and directories in your Gemini prompts. The paths should be relative to WHERE you run the
  gemini command:

### Examples:

**Single file analysis:**
gemini -p "@src/main.py Explain this file's purpose and structure"

Multiple files:
gemini -p "@package.json @src/index.js Analyze the dependencies used in the code"

Entire directory:
gemini -p "@src/ Summarize the architecture of this codebase"

Multiple directories:
gemini -p "@src/ @tests/ Analyze test coverage for the source code"

Current directory and subdirectories:
gemini -p "@./ Give me an overview of this entire project"

# Or use --all_files flag:
gemini --all_files -p "Analyze the project structure and dependencies"

Implementation Verification Examples

Check if a feature is implemented:
gemini -p "@src/ @lib/ Has dark mode been implemented in this codebase? Show me the relevant files and functions"

Verify authentication implementation:
gemini -p "@src/ @middleware/ Is JWT authentication implemented? List all auth-related endpoints and middleware"

Check for specific patterns:
gemini -p "@src/ Are there any React hooks that handle WebSocket connections? List them with file paths"

Verify error handling:
gemini -p "@src/ @api/ Is proper error handling implemented for all API endpoints? Show examples of try-catch blocks"

Check for rate limiting:
gemini -p "@backend/ @middleware/ Is rate limiting implemented for the API? Show the implementation details"

Verify caching strategy:
gemini -p "@src/ @lib/ @services/ Is Redis caching implemented? List all cache-related functions and their usage"

Check for specific security measures:
gemini -p "@src/ @api/ Are SQL injection protections implemented? Show how user inputs are sanitized"

Verify test coverage for features:
gemini -p "@src/payment/ @tests/ Is the payment processing module fully tested? List all test cases"

When to Use Gemini CLI

Use gemini -p when:
- Analyzing entire codebases or large directories
- Comparing multiple large files
- Need to understand project-wide patterns or architecture
- Current context window is insufficient for the task
- Working with files totaling more than 100KB
- Verifying if specific features, patterns, or security measures are implemented
- Checking for the presence of certain coding patterns across the entire codebase

Important Notes

- Paths in @ syntax are relative to your current working directory when invoking gemini
- The CLI will include file contents directly in the context
- No need for --yolo flag for read-only analysis
- Gemini's context window can handle entire codebases that would overflow Claude's context
- When checking implementations, be specific about what you're looking for to get accurate results