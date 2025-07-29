# Forge-X Development Environment Setup

## Environment Choice: WSL2 vs Git Bash

**⚠️ RECOMMENDATION: Use WSL2 with Ubuntu**

| Requirement | Git Bash | WSL2 Ubuntu |
|-------------|----------|-------------|
| **Cross-compilation toolchain** | ❌ Complex/problematic | ✅ Native support |
| **ARM GCC toolchain** | ❌ Windows binaries limited | ✅ Full Linux toolchain |
| **CMake + Make** | ⚠️ Requires manual setup | ✅ Native package manager |
| **SSH deployment** | ✅ Works | ✅ Works better |
| **Shell scripting** | ⚠️ Limited compatibility | ✅ Full bash support |
| **Buildroot (future)** | ❌ Not supported | ✅ Full support |
| **Development workflow** | ⚠️ Windows/Linux path issues | ✅ Seamless |

**Verdict**: WSL2 is essential for serious Forge-X development due to cross-compilation requirements.

## Prerequisites

### 1. Windows Requirements
- Windows 10 version 2004+ or Windows 11
- Virtualization enabled in BIOS/UEFI
- At least 8GB RAM (16GB recommended)
- 20GB free disk space for development environment

### 2. Enable WSL2 (Manual Steps Required)

**Option A: Via PowerShell (Recommended)**
```powershell
# Run as Administrator
wsl --install -d Ubuntu-22.04
```

**Option B: Manual Installation**
```powershell
# Run as Administrator
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Restart computer, then:
wsl --set-default-version 2
```

### 3. Install Ubuntu 22.04 LTS
```bash
# In PowerShell
wsl --install -d Ubuntu-22.04
# Or download from Microsoft Store
```

## Automated Setup Script

**IMPORTANT**: Run this script inside WSL2 Ubuntu after initial setup.

### Setup Script: `setup-forge-x-dev.sh`

```bash
#!/bin/bash

# Forge-X Development Environment Setup Script
# Run this inside WSL2 Ubuntu

set -e  # Exit on any error

echo "🔧 Setting up Forge-X development environment..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential build tools
print_status "Installing essential build tools..."
sudo apt install -y \
    build-essential \
    cmake \
    gcc-arm-linux-gnueabi \
    g++-arm-linux-gnueabi \
    gcc-arm-linux-gnueabihf \
    g++-arm-linux-gnueabihf \
    crossbuild-essential-armhf \
    git \
    wget \
    curl \
    unzip \
    python3 \
    python3-pip \
    openssh-client \
    rsync \
    tree \
    vim \
    nano

# Install crosstool-ng for custom toolchain building
print_status "Installing crosstool-ng..."
sudo apt install -y \
    crosstool-ng \
    gawk \
    texinfo \
    help2man \
    libtool-bin \
    libncurses5-dev \
    unzip \
    autoconf \
    automake \
    flex \
    bison \
    gperf

# Create development directory structure
print_status "Creating development directory structure..."
mkdir -p ~/forge-x-dev/{toolchain,builds,workspace}
cd ~/forge-x-dev

# Clone repository (if not already present)
if [ ! -d "workspace/ff5m" ]; then
    print_status "Cloning Forge-X repository..."
    cd workspace
    git clone https://github.com/Chadillac12/ff5m.git
    cd ff5m
    
    # Set up git remotes
    git remote add origin-upstream https://github.com/DrA1ex/ff5m.git
    git fetch origin-upstream
    
    print_success "Repository cloned and remotes configured"
else
    print_status "Repository already exists, updating..."
    cd workspace/ff5m
    git pull
fi

# Build ARM cross-compilation toolchain
print_status "Setting up ARM cross-compilation toolchain..."
cd ~/forge-x-dev/toolchain

# Create crosstool-ng configuration
if [ ! -f ".config" ]; then
    print_status "Configuring crosstool-ng for ARM..."
    ct-ng arm-unknown-linux-gnueabi
    
    # Apply recommended configuration changes
    cat >> .config << 'EOF'
# Target architecture: ARM
CT_ARCH_ARM=y
CT_ARCH_USE_MMU=y

# Use EABI
CT_ARCH_ABI="eabi"

# Floating point: Software (for compatibility)
CT_ARCH_FLOAT_SW=y

# Libraries configuration
CT_LIBC_GLIBC=y
CT_LIBC_GLIBC_V_2_25=y

# Linux Kernel version
CT_KERNEL_LINUX=y
CT_KERNEL_V_5_3=y

# GCC version (compatible with target)
CT_CC_GCC_V_7=y
EOF

    print_warning "Toolchain configuration created. You may need to run 'ct-ng menuconfig' for custom settings."
fi

# Build toolchain (this takes time!)
if [ ! -d "~/x-tools/arm-unknown-linux-gnueabi" ]; then
    print_status "Building ARM toolchain (this will take 30-60 minutes)..."
    print_warning "Go get coffee! This is a long process..."
    
    # Create symbolic link for toolchain path compatibility
    sudo mkdir -p /home/$USER/x-tools
    sudo ln -sf /home/$USER/x-tools /Volumes/x-tools 2>/dev/null || true
    
    ct-ng build
    
    if [ $? -eq 0 ]; then
        print_success "ARM toolchain built successfully!"
    else
        print_error "Toolchain build failed! Check logs in build.log"
        exit 1
    fi
else
    print_status "ARM toolchain already exists"
fi

# Update toolchain paths for Linux
cd ~/forge-x-dev/workspace/ff5m/.bin/src
if [ -f "toolchain.cmake" ]; then
    print_status "Updating toolchain.cmake for Linux paths..."
    
    # Create Linux-compatible toolchain.cmake
    cat > toolchain.cmake << 'EOF'
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# Specify the cross-compiler paths for Linux
set(TOOLCHAIN "/home/ENV{USER}/x-tools/arm-unknown-linux-gnueabi/bin")
set(CMAKE_C_COMPILER "${TOOLCHAIN}/arm-unknown-linux-gnueabi-gcc")
set(CMAKE_CXX_COMPILER "${TOOLCHAIN}/arm-unknown-linux-gnueabi-g++")
set(CMAKE_AR "${TOOLCHAIN}/arm-unknown-linux-gnueabi-ar")
set(CMAKE_AS "${TOOLCHAIN}/arm-unknown-linux-gnueabi-as")
set(CMAKE_LD "${TOOLCHAIN}/arm-unknown-linux-gnueabi-ld")
set(CMAKE_STRIP "${TOOLCHAIN}/arm-unknown-linux-gnueabi-strip")
set(CMAKE_RANLIB "${TOOLCHAIN}/arm-unknown-linux-gnueabi-ranlib")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
EOF

    # Replace ENV{USER} with actual username
    sed -i "s/ENV{USER}/$USER/g" toolchain.cmake
    
    print_success "toolchain.cmake updated for Linux"
fi

# Install Python dependencies for development
print_status "Installing Python development dependencies..."
pip3 install --user \
    pyserial \
    matplotlib \
    numpy \
    requests

# Create useful aliases and environment setup
print_status "Creating development aliases..."
cat >> ~/.bashrc << 'EOF'

# Forge-X Development Environment
export FORGE_X_DEV=~/forge-x-dev
export FORGE_X_WORKSPACE=$FORGE_X_DEV/workspace/ff5m
export CROSS_COMPILE=/home/$USER/x-tools/arm-unknown-linux-gnueabi/bin/arm-unknown-linux-gnueabi-
export PATH=$PATH:/home/$USER/x-tools/arm-unknown-linux-gnueabi/bin

# Forge-X Aliases
alias fx-cd='cd $FORGE_X_WORKSPACE'
alias fx-build='cd $FORGE_X_WORKSPACE/.bin/src && make'
alias fx-clean='cd $FORGE_X_WORKSPACE/.bin/src && make clean'
alias fx-sync='cd $FORGE_X_WORKSPACE && ./sync.sh'
alias fx-status='cd $FORGE_X_WORKSPACE && git status'
alias fx-log='cd $FORGE_X_WORKSPACE && git log --oneline -10'

# Quick navigation
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
EOF

# Test build environment
print_status "Testing build environment..."
cd ~/forge-x-dev/workspace/ff5m/.bin/src

# Test if cross-compiler works
if command_exists arm-unknown-linux-gnueabi-gcc; then
    print_success "ARM cross-compiler is available"
    arm-unknown-linux-gnueabi-gcc --version | head -1
else
    print_warning "ARM cross-compiler not in PATH, but may be available in toolchain directory"
fi

# Test CMake configuration
if [ -d "demo" ]; then
    print_status "Testing CMake configuration with demo project..."
    cd demo
    
    if cmake -DCMAKE_TOOLCHAIN_FILE=../toolchain.cmake . && make; then
        print_success "Demo project builds successfully!"
    else
        print_warning "Demo build failed - may need toolchain path adjustments"
    fi
    
    cd ..
fi

# Create validation script
print_status "Creating environment validation script..."
cat > ~/forge-x-dev/validate-environment.sh << 'EOF'
#!/bin/bash

echo "🔍 Validating Forge-X Development Environment"

# Check essential commands
COMMANDS=("gcc" "make" "cmake" "git" "ssh" "python3" "pip3")
for cmd in "${COMMANDS[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "✅ $cmd: $(command -v $cmd)"
    else
        echo "❌ $cmd: NOT FOUND"
    fi
done

# Check cross-compiler
if command -v arm-unknown-linux-gnueabi-gcc >/dev/null 2>&1; then
    echo "✅ ARM GCC: $(arm-unknown-linux-gnueabi-gcc --version | head -1)"
else
    echo "❌ ARM GCC: NOT FOUND"
fi

# Check repository
if [ -d "$HOME/forge-x-dev/workspace/ff5m" ]; then
    echo "✅ Repository: Present"
    cd ~/forge-x-dev/workspace/ff5m
    echo "   Current branch: $(git branch --show-current)"
    echo "   Last commit: $(git log --oneline -1)"
else
    echo "❌ Repository: NOT FOUND"
fi

# Check toolchain
if [ -d "$HOME/x-tools/arm-unknown-linux-gnueabi" ]; then
    echo "✅ Custom toolchain: Built and available"
else
    echo "⚠️  Custom toolchain: Not built (using system cross-compiler)"
fi

echo ""
echo "🎯 Quick Start Commands:"
echo "   fx-cd          # Navigate to workspace"
echo "   fx-build       # Build all projects"
echo "   fx-sync        # Deploy to printer"
echo "   fx-status      # Git status"
EOF

chmod +x ~/forge-x-dev/validate-environment.sh

print_success "🎉 Forge-X development environment setup complete!"
print_status "Next steps:"
echo "  1. Run: source ~/.bashrc"
echo "  2. Test: ~/forge-x-dev/validate-environment.sh"
echo "  3. Navigate: fx-cd"
echo "  4. Build: fx-build"
echo ""
print_status "Useful commands added to your shell:"
echo "  fx-cd, fx-build, fx-clean, fx-sync, fx-status, fx-log"
```

## Manual Installation Steps

### Step 1: Enable WSL2 (PowerShell as Administrator)
```powershell
wsl --install -d Ubuntu-22.04
# Restart when prompted
```

### Step 2: Initial Ubuntu Setup
```bash
# Set username and password when prompted
# Update system
sudo apt update && sudo apt upgrade -y
```

### Step 3: Run Automated Setup
```bash
# Download and run setup script
wget https://raw.githubusercontent.com/your-repo/ff5m/main/setup-forge-x-dev.sh
chmod +x setup-forge-x-dev.sh
./setup-forge-x-dev.sh
```

### Step 4: Manual Toolchain Configuration (if needed)
```bash
cd ~/forge-x-dev/toolchain
ct-ng menuconfig  # Optional: customize toolchain
ct-ng build       # If not already built
```

## Alternative: Quick Setup (System Cross-Compiler)

If you want to start developing immediately without building a custom toolchain:

```bash
# Install system cross-compiler (faster but less optimized)
sudo apt update
sudo apt install -y \
    build-essential \
    cmake \
    gcc-arm-linux-gnueabihf \
    g++-arm-linux-gnueabihf \
    git \
    openssh-client

# Clone repository
git clone https://github.com/Chadillac12/ff5m.git
cd ff5m

# Update toolchain.cmake for system compiler
cat > .bin/src/toolchain.cmake << 'EOF'
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

set(CMAKE_C_COMPILER "arm-linux-gnueabihf-gcc")
set(CMAKE_CXX_COMPILER "arm-linux-gnueabihf-g++")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
EOF

# Test build
cd .bin/src/demo
cmake -DCMAKE_TOOLCHAIN_FILE=../toolchain.cmake .
make
```

## Validation and Testing

### Environment Validation Script
```bash
# Run validation
~/forge-x-dev/validate-environment.sh
```

### Build Test
```bash
# Navigate to workspace
fx-cd

# Build all projects
fx-build

# Check for successful compilation
ls .bin/src/*/bin/
```

### Deployment Test
```bash
# Test sync script (replace with your printer IP)
./sync.sh --host 192.168.1.100 --skip-restart --verbose
```

## Troubleshooting

### Common Issues

**1. WSL2 not enabled:**
```powershell
# In PowerShell as Administrator
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl --set-default-version 2
```

**2. Toolchain build fails:**
```bash
# Check available disk space
df -h
# Ensure at least 5GB free

# Check build log
cd ~/forge-x-dev/toolchain
tail -50 build.log
```

**3. Cross-compilation fails:**
```bash
# Verify toolchain path
ls -la ~/x-tools/arm-unknown-linux-gnueabi/bin/

# Test compiler directly
arm-unknown-linux-gnueabi-gcc --version
```

**4. SSH deployment fails:**
```bash
# Test SSH connection
ssh root@<printer-ip>

# Generate SSH key if needed
ssh-keygen -t rsa -b 4096
ssh-copy-id root@<printer-ip>
```

## Performance Optimization

### WSL2 Configuration
Create or edit `%USERPROFILE%\.wslconfig`:
```ini
[wsl2]
memory=8GB
processors=4
swap=2GB
localhostForwarding=true
```

### Build Performance
```bash
# Use parallel compilation
export MAKEFLAGS="-j$(nproc)"

# Enable compiler cache
sudo apt install ccache
export PATH="/usr/lib/ccache:$PATH"
```

## Development Workflow Integration

### VS Code Integration
```bash
# Install VS Code server
code --install-extension ms-vscode-remote.remote-wsl

# Open workspace in VS Code
cd ~/forge-x-dev/workspace/ff5m
code .
```

### Git Configuration
```bash
# Configure git for development
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global init.defaultBranch main
```

This setup provides a complete, professional development environment for Forge-X with automated toolchain building, proper cross-compilation support, and integrated development workflows.