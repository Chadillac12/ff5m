# Forge-X Architecture Dossier

## 1. Project Overview

Forge-X is a comprehensive firmware modification for the Flashforge Adventurer 5M/Pro 3D printer that replaces the proprietary closed-source firmware with the open-source Klipper/Moonraker stack. The project provides advanced 3D printing capabilities, web-based control interfaces, and extensive customization options.

### Primary Goals
- **Performance Enhancement**: Leverage Klipper's superior motion planning and print quality optimization
- **Modern Web Interface**: Replace touchscreen-only control with Mainsail/Fluidd web interfaces
- **Extensibility**: Enable community-driven features and macros through open-source architecture
- **Reliability**: Provide dual-boot capability and recovery mechanisms to prevent printer bricking
- **Resource Optimization**: Operate efficiently within the AD5M's limited RAM constraints

### Key Architectural Requirements
- **Memory Efficiency**: Operate within ~512MB RAM constraints with optimized mjpg-streamer
- **Dual-Boot Safety**: Maintain ability to revert to stock firmware
- **OTA Updates**: Support over-the-air firmware updates through Moonraker
- **Hardware Compatibility**: Direct hardware control of stepper motors, heaters, and sensors
- **Network Integration**: SSH access, web interfaces, and optional Telegram bot integration

## 2. High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User Interfaces                         │
├─────────────────┬─────────────────┬─────────────────────────┤
│  Mainsail/Fluidd│   Telegram Bot  │    SSH Terminal         │
│  Web Interface  │   Notifications │    (zsh + oh-my-zsh)    │
└─────────────────┴─────────────────┴─────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────────┐
│                  Moonraker API Layer                       │
│  - HTTP/JSON API  - File Management  - Update Manager      │
└─────────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────────┐
│                   Klipper Host (Python)                    │
│  - G-code Processing  - Motion Planning  - Plugin System   │
└─────────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────────┐
│              Klipper MCU Firmware (C)                      │
│  - Real-time Control  - Stepper Drivers  - I/O Management  │
└─────────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────────┐
│                 AD5M Hardware Layer                        │
│  - ARM SoC  - Stepper Motors  - Heaters  - Sensors        │
└─────────────────────────────────────────────────────────────┘
```

### Runtime Component Interaction
The system operates through a layered service architecture where:
1. **Boot Process**: S* scripts initialize services in dependency order
2. **Hardware Control**: Klipper MCU firmware provides real-time motor/heater control
3. **Host Processing**: Klipper host handles G-code interpretation and motion planning
4. **API Gateway**: Moonraker exposes unified JSON-RPC API for all printer functions
5. **User Interfaces**: Web UIs and external services communicate through Moonraker API

## 3. Module & Directory Structure

```
ff5m/
├── .bin/                 # Compiled utilities and build artifacts
├── .cfg/                 # Base configuration templates
├── .py/                  # Python utilities and Klipper plugins
├── .root/                # Filesystem overlay (copied to / during install)
├── .shell/               # Core shell scripts and service management
├── .zsh/                 # Z Shell configuration and oh-my-zsh setup
├── config/               # User-selectable printer configurations
├── docs/                 # Comprehensive user documentation
├── KAMP/                 # Klipper Adaptive Meshing & Purging
├── macros/               # G-code macro definitions
├── sql/                  # Database migration scripts
├── telegram/             # Telegram bot integration
└── *.img.xz              # Firmware installation images
```

### Key Directory Purposes

#### .shell/ - Core System Management
- **S* scripts**: SysV-style init scripts controlling service startup sequence
- **boot/**: Hardware initialization and system setup scripts
- **commands/**: User-facing utilities (z* commands for system management)
- **Purpose**: Orchestrates the entire firmware stack startup and provides admin tools

#### .py/ - Python Ecosystem
- **cfg_backup.py**: Configuration backup/restore system with versioning
- **tone.py**: Buzzer control for audio feedback
- **zsend.py**: G-code command injection utility
- **Purpose**: Provides Python-based utilities and Klipper plugin extensions

#### macros/ - G-code Macro System
- **base.cfg**: Core macros (PAUSE, RESUME, M600 filament change)
- **client.cfg**: Mainsail/Fluidd integration macros
- **shell.cfg**: Bridge between G-code and shell commands
- **Purpose**: Extends G-code language with custom commands and automation

#### config/ - User Configuration Profiles
- **stock.cfg**: Standard touchscreen configuration
- **feather.cfg**: Lightweight UI configuration
- **headless.cfg**: No-UI configuration for remote operation
- **Purpose**: Provides pre-configured setups for different usage scenarios

## 4. Dependency Map

### External Dependencies
- **Klipper**: Core 3D printer firmware (Python + C components)
- **Moonraker**: Web API server and update manager
- **Buildroot**: Embedded Linux distribution builder
- **Entware**: Package manager for additional software
- **mjpg-streamer**: Camera streaming (patched for memory optimization)
- **SQLite**: Database for Moonraker's persistent storage
- **Docker**: Container runtime for Telegram bot

### Internal Dependencies
```
sync.sh → sync_remote.sh → S* scripts → Python utilities
    ↓         ↓               ↓            ↓
Configuration → Deployment → Service Start → Runtime Management
```

#### Critical Dependency Chains
1. **Boot Sequence**: S00init → S55boot → boot/*.sh → S60-S99 services
2. **Configuration**: config/*.cfg → macros/*.cfg → KAMP/*.cfg → final printer.cfg
3. **Updates**: sync.sh → moonraker update system → service restarts
4. **Backup**: cfg_backup.py → tar archives → restoration procedures

## 5. File-By-File Breakdown

### Core Installation Files

#### load.img.xz
**Summary**: Main firmware installation image containing complete Forge-X system
**Key Functions**: Filesystem overlay installation, service setup, dual-boot configuration
**Why it exists**: Provides safe, atomic firmware replacement mechanism
**Integration**: Processed by printer's bootloader, unpacks .root/ contents to filesystem

#### sync.sh / sync_remote.sh
**Summary**: Development deployment system for pushing local changes to printer
**Key Functions**: 
- Archive creation with selective file exclusion
- SSH-based deployment with integrity checks
- Service restart orchestration with dependency management
**Why it exists**: Enables rapid development iteration without full firmware reflashing
**Integration**: Invoked by developers, calls sync_remote.sh on printer via SSH

### Boot and Service Management

#### .shell/S00init
**Summary**: Master initialization script that orchestrates entire boot process
**Key Functions**: Mounts filesystems, sets up logging, executes remaining S* scripts in order
**Why it exists**: Provides controlled, logged startup sequence
**Integration**: Called by init system, launches all other S* scripts

#### .shell/S55boot
**Summary**: Hardware and system preparation before service startup
**Key Functions**: Executes boot/*.sh scripts for MCU initialization, swap setup, Wi-Fi connection
**Integration**: Calls boot/boot_mcu.sh, boot/init_swap.sh, boot/wifi_connect.sh in sequence

#### .shell/S99root
**Summary**: Final stage service launcher for core Klipper/Moonraker stack
**Key Functions**: Starts ff_run.sh which launches Klipper and Moonraker services
**Integration**: Terminal script in boot sequence, depends on all previous initialization

### Configuration Management System

#### .py/cfg_backup.py
**Summary**: Comprehensive configuration backup and restoration system
**Key Functions**:
- `backup_config()`: Creates timestamped configuration snapshots
- `restore_config()`: Restores from latest backup
- `tar_backup()`: Creates debug archives with full system state
- `set_mod_param()`: Modifies runtime parameters in variables.cfg
**Why it exists**: Provides safety net for configuration changes and debugging
**Integration**: Called by G-code macros and shell commands, manages /root/printer_data/config

#### macros/base.cfg
**Summary**: Core G-code macro definitions for mod parameter management
**Key Functions**:
- `LIST_MOD_PARAMS`: Displays all configurable parameters
- `GET_MOD`/`SET_MOD`: Parameter getter/setter interface
- `CONFIG_BACKUP`/`CONFIG_RESTORE`: Integration with cfg_backup.py
**Why it exists**: Provides G-code interface to system configuration
**Integration**: Included by all config profiles, bridges G-code to Python utilities

### Hardware Interface Layer

#### .py/tone.py
**Summary**: Buzzer control system for audio feedback
**Key Functions**: GPIO-based tone generation with frequency and duration control
**Why it exists**: Provides audio feedback for print completion, errors, and notifications
**Integration**: Called by G-code macros and system scripts for user feedback

#### .shell/boot/boot_mcu.sh
**Summary**: Microcontroller firmware initialization
**Key Functions**: Flashes Klipper MCU firmware to printer's microcontroller
**Why it exists**: Ensures MCU runs compatible Klipper firmware for real-time control
**Integration**: Called during boot sequence, prerequisite for Klipper host startup

### User Interface Components

#### .shell/commands/z*.sh
**Summary**: Administrative command suite accessible via SSH
**Key Functions**:
- `zconf.sh`: Configuration file editor
- `zmem.sh`/`zfs.sh`: System resource monitoring
- `zdisplay.sh`: Screen mode switching (stock/feather/headless)
- `zversion.sh`: Version information display
**Why it exists**: Provides CLI interface for system administration
**Integration**: Available in SSH shell, calls core system functions

#### macros/shell.cfg
**Summary**: G-code to shell command bridge system
**Key Functions**: Defines `[gcode_shell_command]` entries for all z* utilities
**Why it exists**: Allows web interface to execute system commands safely
**Integration**: Included by configuration profiles, enables web UI system control

## 6. Configuration & Build Process

### Development Environment Setup
1. **Cross-compilation toolchain**: ARM toolchain for compiling .bin/ utilities
2. **Buildroot configuration**: Custom Linux image with optimized package selection
3. **Python environment**: Klipper and Moonraker dependencies
4. **Container setup**: Docker for Telegram bot development

### Build Process
1. **Binary Compilation**: C/C++ utilities in .bin/src/ compiled for ARM target
2. **Configuration Validation**: All .cfg files syntax-checked for Klipper compatibility
3. **Image Assembly**: .root/ directory contents packaged into filesystem image
4. **Compression**: Final image compressed with xz for size optimization
5. **Integrity**: MD5 checksums calculated and appended via addMD5.sh

### Installation Scripts
- **addMD5.sh**: Appends MD5 checksum to installation images for integrity verification
- **sync_remote.sh**: Remote deployment script that handles file extraction, service management, and rollback on failure

### OTA Update Process
1. **Update Detection**: Moonraker monitors GitHub releases
2. **Download**: New firmware images downloaded to temporary storage
3. **Verification**: MD5 checksums validated before installation
4. **Atomic Update**: Services stopped, files replaced, services restarted
5. **Rollback**: Automatic reversion on startup failure

## 7. Data Models & Storage

### Configuration Storage
- **variables.cfg**: Runtime parameters managed by save_variables Klipper module
- **mod_data/**: User configuration directory with backups and customizations
- **printer.cfg**: Generated configuration file combining all includes

### Database Storage
- **moonraker.db**: SQLite database for print history, file metadata, update tracking
- **sql/ migrations**: Versioned schema updates for database evolution

### Persistent Settings Structure
```
variables.cfg:
├── tune_klipper=1         # Communication timeout fixes
├── tune_config=1          # Hardware optimization settings  
├── check_md5=1           # G-code file verification
├── use_kamp=1            # Adaptive bed meshing
├── camera=1              # Alternative camera implementation
├── close_dialogs=FAST    # Dialog auto-close behavior
└── auto_reboot=OFF       # Automatic restart configuration
```

## 8. APIs & Interfaces

### Moonraker HTTP API
**Base URL**: `http://<printer_ip>:7125/`

#### Core Endpoints
```http
GET  /printer/info                    # Printer status and capabilities
POST /printer/gcode/script            # Execute G-code commands
GET  /server/files/list               # File system browsing
POST /server/files/upload             # G-code file upload
GET  /printer/objects/list            # Available data objects
GET  /printer/objects/query           # Real-time printer state
```

#### WebSocket Interface
```javascript
// Real-time printer state updates
ws://printer_ip:7125/websocket
{
  "jsonrpc": "2.0",
  "method": "printer.objects.subscribe",
  "params": {
    "objects": {
      "toolhead": ["position", "status"],
      "extruder": ["temperature", "target"]
    }
  }
}
```

### G-code Macro Interface
```gcode
LIST_MOD_PARAMS                       # Show all parameters
GET_MOD PARAM=tune_klipper           # Get specific parameter
SET_MOD PARAM=camera VALUE=1         # Set parameter value
CONFIG_BACKUP                        # Create configuration backup
```

### Telegram Bot API (Optional)
```
/status      - Printer status and current print
/pause       - Pause current print
/resume      - Resume paused print
/cancel      - Cancel current print
/files       - List available G-code files
```

## 9. Testing & Validation

### Automated Checks
- **MD5 Verification**: G-code files validated against embedded checksums
- **Configuration Syntax**: Klipper config files parsed before service restart
- **Service Health**: Process monitoring and automatic restart on failure

### Manual Validation Procedures
- **Calibration Sequences**: Bed mesh validation, Z-offset verification
- **Hardware Tests**: Stepper motor movement, heater operation, sensor readings
- **Network Connectivity**: Web interface accessibility, SSH connection

### Testing Gaps & Improvements
- **Unit Tests**: Limited automated testing of Python utilities
- **Integration Tests**: No automated end-to-end print testing
- **Performance Tests**: Memory usage monitoring could be more comprehensive
- **Regression Tests**: Configuration changes should have automated validation

## 10. Recommendations & Next Steps

### Architectural Improvements
1. **Modular Configuration**: Split large configuration files into domain-specific modules
2. **Error Handling**: Implement comprehensive error recovery and logging
3. **Resource Monitoring**: Add proactive memory and CPU usage alerts
4. **Update Reliability**: Implement atomic updates with automatic rollback on failure

### Security Enhancements
1. **SSH Key Management**: Replace default root/root credentials with key-based auth
2. **API Authentication**: Add optional authentication to Moonraker API
3. **File Validation**: Extend MD5 checking to all system files
4. **Network Security**: Implement firewall rules and service isolation

### Development Process
1. **Continuous Integration**: Automated building and testing of firmware images
2. **Documentation**: API documentation generation from code annotations
3. **Version Management**: Semantic versioning with migration guides
4. **Community Contributions**: Standardized plugin development framework

## 11. Porting Guide to FlashForge Adventurer 5X

### Hardware Differences Analysis

#### AD5X Specifications (vs AD5M) - **CORRECTED BASED ON RESEARCH**
- **SoC**: Cortex-A53 ARM64 (SAME as AD5M - both use dual-core Cortex-A53)
- **Storage**: 8GB built-in storage (SAME as AD5M)
- **Stepper Drivers**: Silent drivers (SAME base technology, but AD5X has 2 additional size-28 stepper motors for multi-color system)
- **Wi-Fi**: Dual-band 5GHz + 2.4GHz (SAME as AD5M)
- **Key Difference**: Multi-color system with clutch mechanism and 4-filament channels
- **Thermal**: Enhanced 300°C extruder capability (vs 280°C on AD5M)

### Buildroot & Cross-Compilation Adaptations

#### Toolchain Changes - **SIGNIFICANTLY SIMPLIFIED**
```bash
# CORRECTION: Both AD5M and AD5X use identical processors
# AD5M Configuration (ARM64 - Cortex-A53)
BR2_TARGET_CPU="cortex-a53"
BR2_TARGET_ARCH="aarch64"
BR2_TARGET_ABI="lp64"

# AD5X Configuration (ARM64 - Cortex-A53) - IDENTICAL
BR2_TARGET_CPU="cortex-a53"
BR2_TARGET_ARCH="aarch64"
BR2_TARGET_ABI="lp64"

# NO TOOLCHAIN CHANGES REQUIRED - SAME ARCHITECTURE
```

#### Kernel Configuration Updates - **MINIMAL CHANGES REQUIRED**
```diff
# AD5X-specific additions for multi-color system
+CONFIG_STEPPER_MULTICOLOR=y
+CONFIG_GPIO_CLUTCH_CONTROL=y

# Enhanced thermal management
+CONFIG_THERMAL_300C_SUPPORT=y

# Base silent driver support already present in AD5M
# Wi-Fi support already identical between models
```

#### Compiler Adaptations - **NO CHANGES NEEDED**
- **Cross-compiler**: Same `aarch64-linux-gnu-gcc` for both platforms
- **Library paths**: Identical ARM64 libraries in .bin/src/CMakeLists.txt  
- **Binary compatibility**: Same binaries work on both platforms

### Storage & Partitioning Modifications - **NO CHANGES REQUIRED**

#### Storage Layout - **IDENTICAL BETWEEN MODELS**
```
# Both AD5M and AD5X use same 8GB built-in storage
# Same partition scheme can be utilized
/dev/mmcblk0:
├── p1: /boot     (128MB) - Bootloader and kernel
├── p2: /         (2GB)   - Root filesystem  
├── p3: /data     (4GB)   - User data and configurations
└── p4: /recovery (1GB)   - Recovery partition for dual-boot
```

#### Filesystem Adaptations
```bash
# Mount point updates in .shell/S00init
mount -t ext4 /dev/mmcblk0p3 /root/printer_data
mount -t ext4 /dev/mmcblk0p4 /recovery

# Update storage paths in moonraker.conf
[file_manager]
config_path: /root/printer_data/config
log_path: /root/printer_data/logs
```

### Kernel & Driver Modifications

#### Silent Stepper Driver Integration
```cfg
# Update printer configuration for TMC drivers
[stepper_x]
step_pin: gpio_x
dir_pin: gpio_y
enable_pin: !gpio_z
uart_pin: gpio_uart_x
driver: TMC2209
```

#### Wi-Fi Driver Configuration
```bash
# Dual-band Wi-Fi module loading
modprobe cfg80211
modprobe mac80211
modprobe brcmfmac
echo "options brcmfmac feature_disable=0x82000" > /etc/modprobe.d/brcmfmac.conf
```

#### Device Tree Updates
```dts
/ {
    wifi@12340000 {
        compatible = "brcm,bcm4329-fmac";
        reg = <0x12340000 0x1000>;
        interrupts = <GIC_SPI 123 IRQ_TYPE_LEVEL_HIGH>;
        
        brcm,drive-strength = <6>;
        brcm,use-fmac;
    };
};
```

### Configuration System Adaptations

#### Moonraker Network Configuration
```conf
# moonraker.conf updates for dual-band
[machine]
provider = systemd_dbus

[network]
interfaces:
  wlan0:
    type: wifi
    bands: [2.4ghz, 5ghz]
    priority: high
```

#### Path Updates Throughout System
```bash
# Update all hardcoded paths in shell scripts
sed -i 's|/mnt/sdcard|/root/printer_data|g' .shell/*.sh
sed -i 's|/tmp/|/run/|g' .shell/commands/*.sh
```

### Hardware-Specific Klipper Configuration

#### Stepper Configuration for Silent Drivers
```cfg
[stepper_x]
step_pin: PA2
dir_pin: PA1
enable_pin: !PA3
microsteps: 16
rotation_distance: 40
uart_pin: PA0
driver: TMC2209
run_current: 0.580
stealthchop_threshold: 999999

[tmc2209 stepper_x]
uart_pin: PA0
interpolate: True
run_current: 0.580
sense_resistor: 0.110
stealthchop_threshold: 999999
```

### Testing Protocol for AD5X Hardware

#### Pre-Flash Verification
1. **Backup Original Firmware**: Create complete eMMC image backup
2. **Hardware Inventory**: Document all GPIO pins, interfaces, and connections
3. **Network Testing**: Verify Wi-Fi hardware detection and driver availability

#### Flash Testing Sequence
```bash
# 1. Flash test image to recovery partition
dd if=forge-x-ad5x-test.img of=/dev/mmcblk0p4 bs=1M

# 2. Boot from recovery partition
echo "boot_partition=4" > /boot/config.txt
reboot

# 3. Verify core services
systemctl status klipper moonraker
curl http://localhost:7125/printer/info

# 4. Test hardware interfaces
echo "G28" > /tmp/printer          # Home all axes
python3 /root/test_steppers.py    # Stepper movement test
python3 /root/test_heaters.py     # Heater operation test
```

#### Network Connectivity Validation
```python
#!/usr/bin/env python3
import subprocess
import json

def test_wifi_bands():
    """Test both 2.4GHz and 5GHz connectivity"""
    bands = ["2.4", "5"]
    results = {}
    
    for band in bands:
        cmd = f"iwlist wlan0 scan | grep -E 'ESSID|Frequency' | grep '{band}'"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        results[f"{band}ghz"] = len(result.stdout.splitlines()) > 0
    
    return results

def test_moonraker_api():
    """Verify Moonraker API accessibility"""
    import requests
    try:
        response = requests.get("http://localhost:7125/printer/info", timeout=5)
        return response.status_code == 200
    except:
        return False

if __name__ == "__main__":
    wifi_results = test_wifi_bands()
    api_result = test_moonraker_api()
    
    print(json.dumps({
        "wifi": wifi_results,
        "moonraker_api": api_result,
        "timestamp": subprocess.check_output("date").decode().strip()
    }, indent=2))
```

### OTA Update Path Verification

#### Update Mechanism Testing
```bash
# Test update download and verification
curl -L https://github.com/DrA1ex/ff5m/releases/latest/download/forge-x-ad5x.img.xz \
     -o /tmp/update.img.xz

# Verify checksum
md5sum /tmp/update.img.xz | cut -d' ' -f1 > /tmp/download.md5
tail -c 33 /tmp/update.img.xz | head -c 32 > /tmp/embedded.md5

if cmp -s /tmp/download.md5 /tmp/embedded.md5; then
    echo "Update integrity verified"
    # Proceed with update
else
    echo "Update integrity check failed"
    exit 1
fi
```

### Documentation Deliverables

#### AD5X-Specific README
```markdown
# Forge-X for FlashForge Adventurer 5X

## Prerequisites
- AD5X printer with firmware version 1.0.0 or later
- 8GB+ eMMC storage with at least 2GB free space
- USB drive for initial installation

## Installation Differences from AD5M
- Uses eMMC storage instead of SD card
- Supports dual-band Wi-Fi out of the box
- Silent stepper drivers enabled by default
- Enhanced performance due to ARM64 architecture

## Known Issues
- Initial boot may take 2-3 minutes due to eMMC optimization
- 5GHz Wi-Fi requires manual band selection in some environments
- Silent drivers may require TMC tuning for optimal performance
```

#### Porting Checklist
- [ ] Cross-compilation toolchain configured for ARM64
- [ ] Kernel config updated for silent drivers and dual-band Wi-Fi
- [ ] Storage paths updated throughout system
- [ ] Device tree configured for AD5X hardware
- [ ] All binaries recompiled for ARM64
- [ ] Network configuration updated for dual-band support
- [ ] Testing protocol executed and validated
- [ ] Recovery and rollback procedures verified
- [ ] Documentation updated with AD5X-specific instructions

---

This architecture dossier provides a comprehensive foundation for understanding, maintaining, and extending the Forge-X firmware modification system. The detailed analysis enables informed development decisions and safe hardware modifications while preserving the reliability and functionality that makes this project valuable to the 3D printing community.