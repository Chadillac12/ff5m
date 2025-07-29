# Git Workflow Guide for Forge-X Development

## Repository Configuration

This repository is configured with two remotes:
- **`origin`**: `https://github.com/Chadillac12/ff5m.git` (your development fork)
- **`upstream`**: `https://github.com/DrA1ex/ff5m.git` (original Forge-X repository)

## Core Workflow Principles

### 1. Atomic Commits
- **One logical change per commit**
- **Descriptive commit messages** explaining WHY, not just WHAT
- **Test before committing** - ensure changes don't break functionality

### 2. Feature-Based Development
- **Create feature branches** for each significant change
- **Regular commits** during development to preserve work
- **Clean up history** before pushing to upstream

### 3. Meaningful Commit Messages
```
Format: <type>(<scope>): <description>

Examples:
feat(ad5x): add multi-color stepper motor configuration
fix(sync): resolve SSH connection timeout in sync.sh
docs(architecture): update AD5X porting guide with hardware specs
refactor(macros): consolidate G-code macro definitions
test(backup): add validation for cfg_backup.py restore function
```

## Daily Development Workflow

### Starting New Work

```bash
# 1. Ensure you're on main and up to date
git checkout main
git pull origin main

# 2. Create feature branch
git checkout -b feature/descriptive-name
# Examples:
# git checkout -b feature/ad5x-multicolor-support
# git checkout -b fix/sync-script-timeout
# git checkout -b docs/installation-guide-update
```

### During Development

```bash
# Make frequent, logical commits as you work
git add <specific-files>  # Stage only related files
git commit -m "feat(scope): add specific functionality"

# Examples of good development commits:
git commit -m "feat(ad5x): add stepper motor definitions for multi-color system"
git commit -m "config(ad5x): update thermal limits for 300°C operation"
git commit -m "docs(ad5x): document clutch mechanism control implementation"
git commit -m "test(ad5x): add hardware validation scripts"
```

### When to Commit

**✅ COMMIT when you have:**
- Added a complete function or macro
- Fixed a specific bug or issue
- Completed documentation for a feature
- Made configuration changes that work
- Added or updated tests
- Reached a stable checkpoint in development

**❌ DON'T COMMIT when:**
- Code doesn't compile or has syntax errors
- Tests are failing (unless it's a WIP commit)
- You're in the middle of refactoring
- Changes are incomplete or experimental

### Preparing Features for Upstream

```bash
# 1. Review your commit history
git log --oneline

# 2. If needed, clean up commits with interactive rebase
git rebase -i HEAD~n  # where n is number of commits to review

# 3. Ensure all tests pass and configuration is valid
# Run any validation scripts or manual testing

# 4. Push feature branch to upstream
git push upstream feature/descriptive-name

# 5. Create Pull Request via GitHub interface
# Target: original repository (DrA1ex/ff5m)
# Source: your fork (Chadillac12/ff5m)
```

## Specific Scenarios

### Major Analysis or Documentation

```bash
# Example: Architecture analysis work
git checkout -b docs/zmod-architecture-analysis

# During work - commit major milestones
git commit -m "docs(analysis): add ZMOD repository structure analysis"
git commit -m "docs(analysis): document AD5X multi-color implementation"
git commit -m "docs(analysis): create comprehensive comparison matrix"
git commit -m "docs(analysis): add recommendations for Forge-X development"

# When complete
git push upstream docs/zmod-architecture-analysis
```

### Configuration Changes

```bash
# Example: AD5X support implementation
git checkout -b feature/ad5x-support

# Incremental commits
git commit -m "config(ad5x): add dual MCU configuration"
git commit -m "feat(ad5x): implement filament switching macros"
git commit -m "config(ad5x): update thermal management for 300°C"
git commit -m "docs(ad5x): add configuration guide and examples"
git commit -m "test(ad5x): add hardware validation scripts"

# Final push
git push upstream feature/ad5x-support
```

### Bug Fixes

```bash
# Example: Sync script issues
git checkout -b fix/sync-script-improvements

# Focused commits
git commit -m "fix(sync): resolve SSH timeout in slow networks"
git commit -m "fix(sync): improve error handling for missing dependencies"
git commit -m "docs(sync): update troubleshooting guide"

# Push when complete
git push upstream fix/sync-script-improvements
```

## Commit Message Guidelines

### Types
- **feat**: New feature or enhancement
- **fix**: Bug fix
- **docs**: Documentation changes
- **config**: Configuration file changes
- **refactor**: Code restructuring without functionality change
- **test**: Adding or updating tests
- **chore**: Maintenance tasks (dependency updates, etc.)

### Scopes (Examples)
- **ad5x**: AD5X-specific changes
- **ad5m**: AD5M-specific changes
- **sync**: Sync script related
- **macros**: G-code macros
- **config**: Configuration management
- **backup**: Backup/restore functionality
- **docs**: Documentation
- **architecture**: System architecture

### Good Commit Messages

```bash
✅ "feat(ad5x): implement dual MCU configuration for multi-color printing"
✅ "fix(sync): resolve connection timeout for slow SSH connections"
✅ "docs(architecture): add comprehensive ZMOD vs Forge-X comparison"
✅ "config(macros): consolidate G-code macros into modular structure"
✅ "test(backup): add automated validation for configuration restore"
```

### Poor Commit Messages

```bash
❌ "updated files"
❌ "fix stuff"
❌ "work in progress"
❌ "changes"
❌ "forgot to add this"
```

## Syncing with Original Repository

```bash
# Regularly sync with original repository
git checkout main
git pull origin main
git push upstream main

# Update feature branches if needed
git checkout feature/your-branch
git rebase main  # or git merge main if you prefer
```

## Branch Management

### Branch Naming Convention
```
feature/descriptive-name    # New features
fix/issue-description       # Bug fixes  
docs/documentation-update   # Documentation
config/configuration-change # Configuration updates
refactor/code-cleanup      # Code refactoring
```

### Cleaning Up Branches

```bash
# After feature is merged, clean up
git checkout main
git pull origin main
git branch -d feature/completed-feature
git push upstream :feature/completed-feature  # Delete remote branch
```

## Emergency Fixes

```bash
# For critical fixes that need immediate attention
git checkout main
git pull origin main
git checkout -b hotfix/critical-issue

# Make minimal, focused changes
git commit -m "fix(critical): resolve printer bricking issue in sync script"

# Push immediately
git push upstream hotfix/critical-issue
# Create urgent PR
```

## Best Practices Summary

### ✅ DO
- **Commit frequently** during development with meaningful messages
- **Test before committing** to avoid broken states
- **Use descriptive branch names** that explain the work
- **Keep commits atomic** - one logical change per commit
- **Write commit messages** that explain WHY, not just WHAT
- **Clean up commit history** before pushing to upstream
- **Push completed features** to upstream for integration

### ❌ DON'T
- **Commit broken code** unless explicitly marked as WIP
- **Use generic commit messages** like "update" or "fix"
- **Mix unrelated changes** in a single commit
- **Force push to shared branches** (main, dev)
- **Leave branches unfinished** for extended periods
- **Commit sensitive information** (passwords, API keys, etc.)

## Integration with Development Tools

### VS Code Integration
```json
// .vscode/settings.json
{
    "git.enableCommitSigning": true,
    "git.confirmSync": false,
    "git.autofetch": true,
    "git.showPushSuccessNotification": true
}
```

### Git Hooks (Optional)
```bash
# Pre-commit hook to validate configuration files
#!/bin/sh
# .git/hooks/pre-commit
if [ -f "printer.cfg" ]; then
    echo "Validating Klipper configuration..."
    # Add validation logic here
fi
```

## Troubleshooting

### Common Issues

**Merge Conflicts:**
```bash
git status  # See conflicted files
# Edit files to resolve conflicts
git add <resolved-files>
git commit -m "resolve merge conflicts in feature integration"
```

**Accidental Commits:**
```bash
# Undo last commit but keep changes
git reset --soft HEAD~1

# Undo last commit and discard changes
git reset --hard HEAD~1
```

**Need to Update Commit Message:**
```bash
# Last commit only
git commit --amend -m "corrected commit message"

# Multiple commits
git rebase -i HEAD~n
```

This workflow ensures clean git history while maintaining rapid development velocity and proper documentation of all changes.