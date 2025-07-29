#!/bin/bash

echo "🔍 Validating Forge-X Development Environment"
echo "=============================================="

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_check() {
    if [ $1 -eq 0 ]; then
        echo -e "✅ $2"
    else
        echo -e "❌ $2"
    fi
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check WSL environment
echo ""
echo "🖥️  Environment:"
if grep -q Microsoft /proc/version 2>/dev/null; then
    echo "✅ Running in WSL2"
    print_info "WSL Version: $(cat /proc/version | grep -o 'Microsoft.*')"
else
    echo "ℹ️  Running on native Linux"
fi

# Check essential commands
echo ""
echo "📦 Essential Tools:"
COMMANDS=("gcc" "make" "cmake" "git" "ssh" "python3" "pip3" "wget" "curl")
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
FOUND_CROSS=0
if command -v arm-linux-gnueabihf-gcc >/dev/null 2>&1; then
    echo "✅ ARM GCC (system): $(arm-linux-gnueabihf-gcc --version | head -1)"
    FOUND_CROSS=1
fi

if command -v arm-unknown-linux-gnueabi-gcc >/dev/null 2>&1; then
    echo "✅ ARM GCC (custom): $(arm-unknown-linux-gnueabi-gcc --version | head -1)"
    FOUND_CROSS=1
fi

if [ $FOUND_CROSS -eq 0 ]; then
    echo "❌ ARM GCC: NOT FOUND"
    echo "   Install with: sudo apt install gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf"
fi

# Check repository
echo ""
echo "📁 Repository Status:"
if [ -d ".git" ]; then
    echo "✅ Repository: Present (current directory)"
    echo "   📍 Current branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
    echo "   📝 Last commit: $(git log --oneline -1 2>/dev/null || echo 'unknown')"
    
    # Check remotes
    REMOTES=$(git remote -v 2>/dev/null | wc -l)
    if [ $REMOTES -gt 0 ]; then
        echo "   🔗 Remotes configured: $((REMOTES/2))"
        git remote -v | sed 's/^/      /'
    else
        echo "   ⚠️  No remotes configured"
    fi
elif [ -d "~/forge-x-dev/workspace/ff5m" ]; then
    cd ~/forge-x-dev/workspace/ff5m
    echo "✅ Repository: Found in ~/forge-x-dev/workspace/ff5m"
    echo "   📍 Current branch: $(git branch --show-current)"
    echo "   📝 Last commit: $(git log --oneline -1)"
else
    echo "❌ Repository: NOT FOUND"
    echo "   Expected in current directory or ~/forge-x-dev/workspace/ff5m"
fi

# Check build configuration
echo ""
echo "🏗️  Build Configuration:"
if [ -f ".bin/src/toolchain.cmake" ]; then
    echo "✅ Toolchain configuration: Present"
    
    # Check what type of toolchain is configured
    if grep -q "arm-linux-gnueabihf" .bin/src/toolchain.cmake; then
        echo "   🔧 Type: System cross-compiler"
    elif grep -q "arm-unknown-linux-gnueabi" .bin/src/toolchain.cmake; then
        echo "   🔧 Type: Custom crosstool-ng"
    else
        echo "   ⚠️  Type: Unknown configuration"
    fi
else
    echo "❌ Toolchain configuration: Missing (.bin/src/toolchain.cmake)"
fi

# Check CMake build capability
if [ -d ".bin/src/demo" ]; then
    echo ""
    echo "🧪 Build Test (demo project):"
    cd .bin/src/demo
    
    if [ ! -d "build" ]; then
        mkdir build
    fi
    
    cd build
    
    if cmake -DCMAKE_TOOLCHAIN_FILE=../../toolchain.cmake .. >/dev/null 2>&1; then
        echo "✅ CMake configuration: Success"
        
        if make >/dev/null 2>&1; then
            echo "✅ Compilation: Success"
            if [ -f "demo" ]; then
                echo "✅ Binary output: Generated"
                echo "   📦 Binary: $(ls -la demo | awk '{print $5" bytes"}')"
            fi
        else
            echo "❌ Compilation: Failed"
        fi
    else
        echo "❌ CMake configuration: Failed"
    fi
    
    cd - >/dev/null
fi

# Check custom toolchain
echo ""
echo "🛠️  Toolchain Status:"
if [ -d "$HOME/x-tools/arm-unknown-linux-gnueabi" ]; then
    echo "✅ Custom toolchain: Built and available"
    TOOLCHAIN_SIZE=$(du -sh "$HOME/x-tools/arm-unknown-linux-gnueabi" 2>/dev/null | cut -f1)
    echo "   📊 Size: $TOOLCHAIN_SIZE"
else
    echo "ℹ️  Custom toolchain: Not built (using system cross-compiler)"
fi

# Check Python development packages
echo ""
echo "🐍 Python Development:"
PYTHON_PACKAGES=("pyserial" "matplotlib" "numpy" "requests")
for pkg in "${PYTHON_PACKAGES[@]}"; do
    if python3 -c "import $pkg" 2>/dev/null; then
        echo "✅ $pkg: Available"
    else
        echo "❌ $pkg: Not installed (pip3 install --user $pkg)"
    fi
done

# Check development aliases
echo ""
echo "🔗 Development Aliases:"
if grep -q "# Forge-X Development Environment" ~/.bashrc 2>/dev/null; then
    echo "✅ Development aliases: Configured in ~/.bashrc"
    echo "   💡 Run 'source ~/.bashrc' to load them"
else
    echo "❌ Development aliases: Not configured"
fi

# Network connectivity test
echo ""
echo "🌐 Network Connectivity:"
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "✅ Internet: Connected"
else
    echo "❌ Internet: No connectivity"
fi

if command -v ssh >/dev/null 2>&1; then
    echo "✅ SSH client: Available"
    if [ -f "$HOME/.ssh/id_rsa" ] || [ -f "$HOME/.ssh/id_ed25519" ]; then
        echo "✅ SSH keys: Present"
    else
        echo "ℹ️  SSH keys: Not found (generate with: ssh-keygen -t ed25519)"
    fi
else
    echo "❌ SSH client: Not available"
fi

# Summary
echo ""
echo "📊 Environment Summary:"
TOTAL_CHECKS=0
PASSED_CHECKS=0

# Count essential tools
for cmd in gcc make cmake git; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if command -v "$cmd" >/dev/null 2>&1; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
done

# Count cross-compiler
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ $FOUND_CROSS -eq 1 ]; then
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi

# Count repository
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ -d ".git" ] || [ -d "~/forge-x-dev/workspace/ff5m" ]; then
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi

PERCENTAGE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

if [ $PERCENTAGE -ge 80 ]; then
    echo -e "${GREEN}✅ Environment Status: Ready ($PASSED_CHECKS/$TOTAL_CHECKS checks passed - $PERCENTAGE%)${NC}"
elif [ $PERCENTAGE -ge 60 ]; then
    echo -e "${YELLOW}⚠️  Environment Status: Mostly Ready ($PASSED_CHECKS/$TOTAL_CHECKS checks passed - $PERCENTAGE%)${NC}"
else
    echo -e "${RED}❌ Environment Status: Needs Setup ($PASSED_CHECKS/$TOTAL_CHECKS checks passed - $PERCENTAGE%)${NC}"
fi

echo ""
echo "🎯 Quick Start Commands:"
if grep -q "# Forge-X Development Environment" ~/.bashrc 2>/dev/null; then
    echo "   source ~/.bashrc   # Load development aliases"
    echo "   fx-cd             # Navigate to workspace"
    echo "   fx-build          # Build all projects"
    echo "   fx-status         # Git status"  
    echo "   fx-sync --host IP # Deploy to printer"
else
    echo "   cd path/to/ff5m   # Navigate to repository"
    echo "   cd .bin/src && make  # Build projects"
    echo "   ./sync.sh --host IP  # Deploy to printer"
fi

echo ""
echo "💡 Tips:"
echo "   • Set printer IP: export PRINTER_IP=192.168.1.xxx"
echo "   • Run setup script: ./setup-forge-x-dev.sh"
echo "   • For help: cat DEVELOPMENT_ENVIRONMENT_SETUP.md"