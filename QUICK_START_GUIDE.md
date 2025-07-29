# Forge-X Development Quick Start Guide

## Prerequisites Check

**✅ You need:**
- Windows 10 (version 2004+) or Windows 11
- WSL2 enabled with Ubuntu 22.04 LTS
- At least 8GB RAM and 20GB free disk space

## 1. Enable WSL2 (One-time setup)

**In PowerShell as Administrator:**
```powershell
wsl --install -d Ubuntu-22.04
```

**Restart your computer when prompted.**

## 2. Initial Ubuntu Setup

When Ubuntu starts for the first time:
```bash
# Create username and password when prompted
# Update system (this may take a few minutes)
sudo apt update && sudo apt upgrade -y
```

## 3. Automated Environment Setup

**Download and run the setup script:**
```bash
# Download setup script
wget https://raw.githubusercontent.com/Chadillac12/ff5m/main/setup-forge-x-dev.sh

# Make executable
chmod +x setup-forge-x-dev.sh

# Run setup (will take 15-30 minutes)
./setup-forge-x-dev.sh
```

**During setup, you'll be asked to choose:**
- **Option 1**: System cross-compiler (recommended for beginners)
- **Option 2**: Custom toolchain build (advanced, takes 30-60 minutes)

## 4. Load Development Environment

```bash
# Load new aliases and environment
source ~/.bashrc

# Validate setup
~/forge-x-dev/validate-environment.sh
```

## 5. Quick Development Test

```bash
# Navigate to workspace
fx-cd

# Build all projects
fx-build

# Check build output
ls .bin/src/*/bin/ 2>/dev/null || echo "No binaries built yet"
```

## 6. Configure for Your Printer

```bash
# Set your printer's IP address
export PRINTER_IP=192.168.1.100  # Replace with your printer's IP

# Test connection (optional)
ping -c 3 $PRINTER_IP

# Set up SSH key for easy deployment
ssh-keygen -t ed25519
ssh-copy-id root@$PRINTER_IP
```

## 7. First Deployment Test

```bash
# Test deployment (without restart for safety)
fx-sync --host $PRINTER_IP --skip-restart --verbose

# Or use the quick alias (after setting PRINTER_IP)
fx-deploy
```

## Development Aliases Reference

After running setup, these aliases are available:

| Alias | Function |
|-------|----------|
| `fx-cd` | Navigate to workspace |
| `fx-build` | Clean and build all projects |
| `fx-clean` | Clean build artifacts |
| `fx-sync --host IP` | Deploy to printer |
| `fx-deploy` | Deploy using saved PRINTER_IP |
| `fx-status` | Git status |
| `fx-log` | Show recent commits |
| `fx-branch` | List all branches |
| `fx-diff` | Show working changes |

## Common Commands

### Git Workflow
```bash
fx-cd                              # Go to workspace
fx-status                          # Check status
git checkout -b feature/my-feature # Create feature branch
# ... make changes ...
git add .
git commit -m "feat(scope): description"
git push upstream feature/my-feature
```

### Build and Deploy
```bash
fx-build                          # Build everything
fx-deploy                         # Deploy to printer
fx-sync --host IP --profile light # Deploy without heavy files
```

### Troubleshooting
```bash
~/forge-x-dev/validate-environment.sh  # Check environment
fx-clean && fx-build                   # Clean rebuild
git status                             # Check repository state
```

## Troubleshooting Common Issues

### WSL2 Issues
```powershell
# In PowerShell as Administrator
wsl --shutdown
wsl --set-default-version 2
wsl --list --verbose
```

### Build Failures
```bash
# Check cross-compiler
arm-linux-gnueabihf-gcc --version

# Rebuild toolchain config
cd ~/.../ff5m/.bin/src
# Edit toolchain.cmake if needed

# Clean rebuild
fx-clean && fx-build
```

### SSH Connection Issues
```bash
# Test SSH connection
ssh root@$PRINTER_IP

# If connection fails, check:
# 1. Printer IP is correct
# 2. Printer is on same network
# 3. SSH is enabled on printer
```

### Environment Validation Failed
```bash
# Re-run setup for missing components
./setup-forge-x-dev.sh

# Or install missing packages manually:
sudo apt install build-essential cmake gcc-arm-linux-gnueabihf
```

## Development Workflow

### Starting New Feature
```bash
fx-cd
git checkout main
git pull origin main
git checkout -b feature/descriptive-name
```

### Regular Development
```bash
# Make changes to files
fx-build                    # Test build
fx-deploy                   # Test on printer
git add changed-files
git commit -m "feat(scope): description"
```

### Completing Feature
```bash
fx-build                    # Final build test
git push upstream feature/descriptive-name
# Create PR via GitHub web interface
```

## Next Steps

1. **Read the documentation**: `DEVELOPMENT_ENVIRONMENT_SETUP.md`
2. **Explore the codebase**: `FORGE-X_ARCHITECTURE_DOSSIER.md`
3. **Understand git workflow**: `GIT_WORKFLOW_GUIDE.md`
4. **Check current issues**: GitHub Issues tab
5. **Join development**: Create your first feature branch!

## Getting Help

- **Environment issues**: Run `~/forge-x-dev/validate-environment.sh`
- **Build problems**: Check `DEVELOPMENT_ENVIRONMENT_SETUP.md`
- **Git workflow**: See `GIT_WORKFLOW_GUIDE.md`
- **Architecture questions**: Read `FORGE-X_ARCHITECTURE_DOSSIER.md`

**You're ready to develop Forge-X! 🚀**