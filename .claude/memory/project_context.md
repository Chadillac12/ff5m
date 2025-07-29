# Forge-X Project Memory Bank

## Project Identity
- **Name**: Flashforge Forge-X Firmware Modification
- **Target**: Adventurer 5M/Pro 3D Printers
- **Architecture**: Klipper/Moonraker-based firmware replacement
- **Language Stack**: Shell scripts, Python, C/C++, G-code macros
- **Repository**: https://github.com/DrA1ex/ff5m

## Current Session Context
- **Date**: 2025-01-29
- **Primary Task**: Created comprehensive architecture dossier
- **Files Created**:
  - `CLAUDE.md` - Claude Code guidance document
  - `FORGE-X_ARCHITECTURE_DOSSIER.md` - Complete technical analysis
- **Analysis Completed**: Full repository architecture review using Gemini CLI

## Key Technical Insights
1. **Boot Process**: S* scripts manage service initialization in SysV style
2. **Configuration System**: Layered .cfg files with include hierarchy
3. **Deployment**: sync.sh orchestrates SSH-based development updates
4. **Hardware Control**: Direct stepper/heater control via Klipper MCU firmware
5. **Safety**: Dual-boot capability prevents bricking

## Critical Files Identified
- `.shell/S00init` - Master boot orchestrator
- `sync.sh/sync_remote.sh` - Development deployment system
- `.py/cfg_backup.py` - Configuration management
- `macros/base.cfg` - Core G-code macro definitions
- `config/*.cfg` - User-selectable printer profiles

## Development Workflow
1. Local modifications in repository
2. Deploy via `./sync.sh --host <printer_ip>`
3. Test through web interfaces (Mainsail/Fluidd)
4. Backup configurations via G-code macros
5. Validate hardware operation after changes

## Safety Considerations
- Hardware control changes require full recalibration
- Always backup before modifications
- Test incrementally, never in bulk
- Dual-boot recovery available if needed

## Next Session Priorities
- Monitor for architecture evolution
- Track new feature development
- Update documentation as system evolves
- Maintain awareness of porting opportunities (AD5X)