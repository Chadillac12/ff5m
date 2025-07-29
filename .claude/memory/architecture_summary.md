# Forge-X Architecture Memory

## System Overview
- **Core**: Klipper (MCU firmware) + Moonraker (API) + Web UI stack
- **Platform**: Embedded Linux on ARM SoC (AD5M hardware)
- **Constraints**: ~512MB RAM, SD card storage, embedded environment

## Component Architecture

### Boot Sequence (Critical)
```
S00init → S55boot → boot/*.sh → S60-S99 services → S99root (Klipper/Moonraker)
```

### Configuration Hierarchy
```
config/*.cfg → macros/*.cfg → KAMP/*.cfg → final printer.cfg
```

### Deployment Chain
```
sync.sh → SSH → sync_remote.sh → service restart → validation
```

## Key Abstraction Layers
1. **Hardware**: ARM SoC, steppers, heaters, sensors
2. **MCU Firmware**: Real-time control (Klipper C code)
3. **Host Software**: Motion planning (Klipper Python)
4. **API Layer**: HTTP/WebSocket interface (Moonraker)
5. **User Interface**: Web-based control (Mainsail/Fluidd)

## Critical Integration Points
- **G-code Macros**: Bridge between web UI and system functions
- **Configuration Management**: cfg_backup.py provides versioning/rollback
- **Service Management**: Shell scripts coordinate service lifecycle
- **Parameter System**: variables.cfg stores runtime configuration

## Memory Patterns
- **Layered Configuration**: Include-based config composition
- **Service Orchestration**: Dependency-aware startup sequence  
- **Safety Mechanisms**: Backup/restore and dual-boot recovery
- **Development Support**: Live deployment without reflashing

## Architectural Strengths
- Modular, include-based configuration system
- Safe deployment with rollback capabilities
- Comprehensive backup/restore mechanisms
- Developer-friendly update process

## Architectural Risks
- Complex boot dependency chain
- Multiple configuration sources can create conflicts
- Shell script heavy (potential reliability issues)
- Limited automated testing coverage