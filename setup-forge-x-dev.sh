#!/bin/bash

# Forge-X Development Environment Setup Script
# Run this inside WSL2 Ubuntu after initial setup

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

# Check if running in WSL
if ! grep -q Microsoft /proc/version 2>/dev/null; then
    print_warning "This script is designed for WSL2. Some features may not work correctly on native Linux."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

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
    nano \
    htop

# Install crosstool-ng for custom toolchain building
print_status "Installing crosstool-ng and dependencies..."
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

# Set up workspace
print_status "Setting up workspace..."
cd ~/forge-x-dev/workspace

# Check if we're already in a git repository
if [ -d ".git" ]; then
    print_status "Already in a git repository, using current location"
    REPO_DIR="."
elif [ -d "ff5m" ]; then
    print_status "Repository already exists, updating..."
    cd ff5m
    git pull
    REPO_DIR="ff5m"
else
    print_status "Cloning Forge-X repository..."
    git clone https://github.com/Chadillac12/ff5m.git
    cd ff5m
    REPO_DIR="ff5m"
    
    # Set up git remotes
    git remote add origin-upstream https://github.com/DrA1ex/ff5m.git 2>/dev/null || true
    git fetch origin-upstream
    
    print_success "Repository cloned and remotes configured"
fi

# Build ARM cross-compilation toolchain
print_status "Setting up ARM cross-compilation toolchain..."
cd ~/forge-x-dev/toolchain

# Ask user if they want to build custom toolchain or use system one
echo ""
print_status "Toolchain Options:"
echo "1. Use system cross-compiler (faster, good for most development)"
echo "2. Build custom crosstool-ng toolchain (slower, matches target exactly)"
echo ""
read -p "Choose option (1 or 2): " -n 1 -r TOOLCHAIN_CHOICE
echo ""

if [[ $TOOLCHAIN_CHOICE == "2" ]]; then
    # Build custom toolchain
    print_status "Building custom ARM toolchain..."
    
    # Create crosstool-ng configuration
    if [ ! -f ".config" ]; then
        print_status "Configuring crosstool-ng for ARM..."
        ct-ng arm-unknown-linux-gnueabi
        
        print_warning "You may want to run 'ct-ng menuconfig' to customize the toolchain"
        read -p "Run menuconfig now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ct-ng menuconfig
        fi
    fi

    # Build toolchain (this takes time!)
    if [ ! -d "$HOME/x-tools/arm-unknown-linux-gnueabi" ]; then
        print_status "Building ARM toolchain (this will take 30-60 minutes)..."
        print_warning "Go get coffee! This is a long process..."
        
        ct-ng build
        
        if [ $? -eq 0 ]; then
            print_success "ARM toolchain built successfully!"
        else
            print_error "Toolchain build failed! Check logs in build.log"
            print_status "Falling back to system cross-compiler..."
            TOOLCHAIN_CHOICE="1"
        fi
    else
        print_status "Custom ARM toolchain already exists"
    fi
fi

# Update toolchain configuration
cd ~/forge-x-dev/workspace/$REPO_DIR/.bin/src
if [ -f "toolchain.cmake" ]; then
    print_status "Updating toolchain.cmake for Linux paths..."
    
    # Backup original
    cp toolchain.cmake toolchain.cmake.bak
    
    if [[ $TOOLCHAIN_CHOICE == "2" ]] && [ -d "$HOME/x-tools/arm-unknown-linux-gnueabi" ]; then
        # Use custom toolchain
        cat > toolchain.cmake << EOF
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# Specify the cross-compiler paths for Linux (custom toolchain)
set(TOOLCHAIN "$HOME/x-tools/arm-unknown-linux-gnueabi/bin")
set(CMAKE_C_COMPILER "\${TOOLCHAIN}/arm-unknown-linux-gnueabi-gcc")
set(CMAKE_CXX_COMPILER "\${TOOLCHAIN}/arm-unknown-linux-gnueabi-g++")
set(CMAKE_AR "\${TOOLCHAIN}/arm-unknown-linux-gnueabi-ar")
set(CMAKE_AS "\${TOOLCHAIN}/arm-unknown-linux-gnueabi-as")
set(CMAKE_LD "\${TOOLCHAIN}/arm-unknown-linux-gnueabi-ld")
set(CMAKE_STRIP "\${TOOLCHAIN}/arm-unknown-linux-gnueabi-strip")
set(CMAKE_RANLIB "\${TOOLCHAIN}/arm-unknown-linux-gnueabi-ranlib")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
EOF
        print_success "toolchain.cmake configured for custom toolchain"
    else
        # Use system cross-compiler
        cat > toolchain.cmake << EOF
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# Use system cross-compiler
set(CMAKE_C_COMPILER "arm-linux-gnueabihf-gcc")
set(CMAKE_CXX_COMPILER "arm-linux-gnueabihf-g++")
set(CMAKE_AR "arm-linux-gnueabihf-ar")
set(CMAKE_AS "arm-linux-gnueabihf-as")
set(CMAKE_LD "arm-linux-gnueabihf-ld")
set(CMAKE_STRIP "arm-linux-gnueabihf-strip")
set(CMAKE_RANLIB "arm-linux-gnueabihf-ranlib")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
EOF
        print_success "toolchain.cmake configured for system cross-compiler"
    fi
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
if ! grep -q "# Forge-X Development Environment" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOF'

# Forge-X Development Environment
export FORGE_X_DEV=~/forge-x-dev
export FORGE_X_WORKSPACE=$FORGE_X_DEV/workspace/ff5m
export PATH=$PATH:$HOME/x-tools/arm-unknown-linux-gnueabi/bin

# Forge-X Aliases
alias fx-cd='cd $FORGE_X_WORKSPACE'
alias fx-build='cd $FORGE_X_WORKSPACE/.bin/src && make clean && make'
alias fx-clean='cd $FORGE_X_WORKSPACE/.bin/src && make clean'
alias fx-sync='cd $FORGE_X_WORKSPACE && ./sync.sh'
alias fx-status='cd $FORGE_X_WORKSPACE && git status'
alias fx-log='cd $FORGE_X_WORKSPACE && git log --oneline -10'
alias fx-branch='cd $FORGE_X_WORKSPACE && git branch -a'
alias fx-diff='cd $FORGE_X_WORKSPACE && git diff'

# Quick navigation
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Development helpers
alias fx-ip='echo "Set your printer IP: export PRINTER_IP=192.168.1.xxx"'
alias fx-deploy='fx-sync --host $PRINTER_IP'
EOF
    print_success "Development aliases added to ~/.bashrc"
else
    print_status "Development aliases already present in ~/.bashrc"
fi

# Test build environment
print_status "Testing build environment..."
cd ~/forge-x-dev/workspace/$REPO_DIR/.bin/src

# Test if cross-compiler works
if command_exists arm-linux-gnueabihf-gcc; then
    print_success "ARM cross-compiler is available"
    arm-linux-gnueabihf-gcc --version | head -1
elif command_exists arm-unknown-linux-gnueabi-gcc; then
    print_success "Custom ARM cross-compiler is available"
    arm-unknown-linux-gnueabi-gcc --version | head -1
else
    print_warning "ARM cross-compiler not found in PATH"
fi

# Test CMake configuration with a simple project
if [ -d "demo" ]; then
    print_status "Testing CMake configuration with demo project..."
    cd demo
    mkdir -p build
    cd build
    
    if cmake -DCMAKE_TOOLCHAIN_FILE=../../toolchain.cmake .. && make; then
        print_success "Demo project builds successfully!"
        ls -la
    else
        print_warning "Demo build failed - may need toolchain adjustments"
    fi
    
    cd ../..
fi

# Create validation script
print_status "Creating environment validation script..."
cat > ~/forge-x-dev/validate-environment.sh << 'EOF'
#!/bin/bash

echo "🔍 Validating Forge-X Development Environment"
echo "=============================================="

# Check essential commands
echo ""
echo "📦 Essential Tools:"
COMMANDS=("gcc" "make" "cmake" "git" "ssh" "python3" "pip3")
for cmd in "${COMMANDS[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "✅ $cmd: $(command -v $cmd)"
    else
        echo "❌ $cmd: NOT FOUND"
    fi
done

# Check cross-compiler
echo ""
echo "🔧 Cross-Compilation Tools:"
if command -v arm-linux-gnueabihf-gcc >/dev/null 2>&1; then
    echo "✅ ARM GCC (system): $(arm-linux-gnueabihf-gcc --version | head -1)"
elif command -v arm-unknown-linux-gnueabi-gcc >/dev/null 2>&1; then
    echo "✅ ARM GCC (custom): $(arm-unknown-linux-gnueabi-gcc --version | head -1)"
else
    echo "❌ ARM GCC: NOT FOUND"
fi

# Check repository
echo ""
echo "📁 Repository Status:"
if [ -d "$HOME/forge-x-dev/workspace" ]; then
    cd ~/forge-x-dev/workspace
    if [ -d "ff5m" ]; then
        cd ff5m
        echo "✅ Repository: Present"
        echo "   📍 Current branch: $(git branch --show-current)"
        echo "   📝 Last commit: $(git log --oneline -1)"
        echo "   🔗 Remotes: $(git remote -v | wc -l) configured"
    else
        echo "❌ Repository: ff5m directory not found"
    fi
else
    echo "❌ Repository: Workspace not found"
fi

# Check toolchain
echo ""
echo "🛠️  Toolchain Status:"
if [ -d "$HOME/x-tools/arm-unknown-linux-gnueabi" ]; then
    echo "✅ Custom toolchain: Built and available"
else
    echo "ℹ️  Custom toolchain: Not built (using system cross-compiler)"
fi

# Check build capability
echo ""
echo "🏗️  Build Test:"
if [ -f "$HOME/forge-x-dev/workspace/ff5m/.bin/src/toolchain.cmake" ]; then
    echo "✅ Toolchain configuration: Present"
else
    echo "❌ Toolchain configuration: Missing"
fi

echo ""
echo "🚦 Environment Status: Ready for development!"
echo ""
echo "🎯 Quick Start Commands:"
echo "   source ~/.bashrc   # Load new aliases"
echo "   fx-cd             # Navigate to workspace"  
echo "   fx-build          # Build all projects"
echo "   fx-status         # Git status"
echo "   fx-sync --host IP # Deploy to printer"
echo ""
echo "💡 Set your printer IP: export PRINTER_IP=192.168.1.xxx"
echo "   Then use: fx-deploy"
EOF

chmod +x ~/forge-x-dev/validate-environment.sh

# Create quick build script
print_status "Creating build helper script..."
cat > ~/forge-x-dev/build-all.sh << 'EOF'
#!/bin/bash

cd ~/forge-x-dev/workspace/ff5m/.bin/src

echo "🏗️  Building all Forge-X projects..."

# Clean previous builds
make clean

# Build all projects
if make -j$(nproc); then
    echo "✅ Build successful!"
    echo ""
    echo "📦 Built binaries:"
    find . -name "bin" -type d -exec ls -la {} \;
else
    echo "❌ Build failed!"
    exit 1
fi
EOF

chmod +x ~/forge-x-dev/build-all.sh

# Create development info file
cat > ~/forge-x-dev/README-DEV.md << 'EOF'
# Forge-X Development Environment

## Quick Start
```bash
source ~/.bashrc           # Load development aliases
fx-cd                     # Navigate to workspace  
fx-build                  # Build all projects
~/forge-x-dev/validate-environment.sh  # Validate setup
```

## Development Aliases
- `fx-cd`: Navigate to workspace
- `fx-build`: Clean and build all projects
- `fx-clean`: Clean build artifacts
- `fx-sync`: Deploy to printer
- `fx-status`: Git status
- `fx-log`: Recent commits
- `fx-branch`: List branches
- `fx-diff`: Show changes

## Printer Deployment
```bash
export PRINTER_IP=192.168.1.100
fx-deploy  # Uses saved IP

# Or direct:
fx-sync --host 192.168.1.100 --verbose
```

## Build Individual Projects
```bash
cd ~/.../ff5m/.bin/src/demo
mkdir build && cd build
cmake -DCMAKE_TOOLCHAIN_FILE=../../toolchain.cmake ..
make
```

## Troubleshooting
- Run validation: `~/forge-x-dev/validate-environment.sh`
- Check toolchain: `arm-linux-gnueabihf-gcc --version`
- Rebuild: `fx-clean && fx-build`
EOF

print_success "🎉 Forge-X development environment setup complete!"
echo ""
print_status "📋 Next steps:"
echo "  1. Run: source ~/.bashrc"
echo "  2. Test: ~/forge-x-dev/validate-environment.sh"
echo "  3. Navigate: fx-cd"
echo "  4. Build: fx-build"
echo "  5. Set printer IP: export PRINTER_IP=192.168.1.xxx"
echo ""
print_status "📁 Development files created:"
echo "  ~/forge-x-dev/validate-environment.sh"
echo "  ~/forge-x-dev/build-all.sh"
echo "  ~/forge-x-dev/README-DEV.md"
echo ""
print_success "🚀 You're ready to develop Forge-X!"