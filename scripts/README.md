# Froom Migration Scripts

This directory contains automated migration scripts to help you migrate from Floor to Froom across different platforms.

## Available Scripts

### Linux/macOS (Bash)
- **`migrate_floor_to_froom.sh`** - Main migration script from Floor to Froom
- **`migrate_froom_to_floor.sh`** - Reverse migration script for testing purposes
- **`migrate.sh`** - Simple version update script

### Windows (PowerShell)
- **`migrate_floor_to_froom.ps1`** - PowerShell version of main migration script
- **`migrate_froom_to_floor.ps1`** - PowerShell version of reverse migration script  
- **`migrate.ps1`** - PowerShell version of simple update script

### Windows (Batch)
- **`run_migration.bat`** - Interactive launcher that handles PowerShell execution policy

## Quick Start

### Linux/macOS
```bash
# Make executable
chmod +x scripts/migrate_floor_to_froom.sh

# Run migration
./scripts/migrate_floor_to_froom.sh
```

### Windows (PowerShell)
```powershell
# Run migration
.\scripts\migrate_floor_to_froom.ps1
```

### Windows (Easy Mode)
```cmd
# Launch interactive migration tool
.\scripts\run_migration.bat
```

## Script Options

### Bash Scripts (`migrate_floor_to_froom.sh`, `migrate_froom_to_floor.sh`)
| Option | Short | Description |
|--------|-------|-------------|
| `--backup` | `-b` | Create backup before migration |
| `--yes` | `-y` | Skip confirmation prompts |
| `--path PATH` | `-p PATH` | Specify project path |
| `--help` | `-h` | Show help message |

**Examples:**
```bash
./scripts/migrate_floor_to_froom.sh --backup --yes               # Automated with backup
./scripts/migrate_floor_to_froom.sh --yes                        # Quick migration
./scripts/migrate_floor_to_froom.sh                              # Interactive mode
./scripts/migrate_floor_to_froom.sh /path/to/project             # Specify path (positional)
./scripts/migrate_floor_to_froom.sh --path /path/to/project      # Specify path (named)
./scripts/migrate_floor_to_froom.sh -p /path/to/project --backup # Specify path with backup
```

### PowerShell Scripts (`migrate_floor_to_froom.ps1`, `migrate_froom_to_floor.ps1`)
| Parameter | Description |
|-----------|-------------|
| `-Backup` | Create backup before migration |
| `-Yes` | Skip confirmation prompts |
| `-Path "PATH"` | Specify project path |
| `-Help` | Show help message |

**Examples:**
```powershell
.\scripts\migrate_floor_to_froom.ps1 -Backup -Yes                      # Automated with backup
.\scripts\migrate_floor_to_froom.ps1 -Yes                              # Quick migration
.\scripts\migrate_floor_to_froom.ps1                                   # Interactive mode
.\scripts\migrate_floor_to_froom.ps1 -Path "C:\path\to\project"        # Specify path
.\scripts\migrate_floor_to_froom.ps1 -Path "C:\MyProject" -Backup -Yes # Specify path with backup
```

## What the Migration Scripts Do

1. **Dependency Management**
   - Remove Floor dependencies (`floor`, `floor_generator`)
   - Add Froom dependencies (`froom`, `froom_generator`)
   - Use latest compatible versions automatically

2. **Code Updates**
   - Replace `import 'package:floor/floor.dart'` → `import 'package:froom/froom.dart'`
   - Replace `import 'package:floor_annotation/floor_annotation.dart'` → `import 'package:froom/froom.dart'`
   - Replace `FloorDatabase` → `FroomDatabase`
   - Replace `$Floor` → `$Froom`

3. **Cleanup**
   - Remove old generated `.g.dart` files
   - Optional: Run `build_runner` to regenerate code

4. **Backup (Optional)**
   - Create timestamped backup directory
   - Copy entire project before making changes

## Special Features

### Windows Batch Launcher (`run_migration.bat`)

The batch launcher provides a user-friendly interface for Windows users and handles PowerShell execution policy issues:

- **Execution Policy Detection** - Automatically detects current PowerShell execution policy
- **Policy Resolution** - Offers to bypass or change restrictive policies
- **Interactive Menu** - Provides GUI-like selection of migration scripts
- **Argument Handling** - Prompts for script options through user-friendly interface

### Reverse Migration

For testing purposes, we provide reverse migration scripts that convert Froom projects back to Floor:

```bash
# Bash
./scripts/migrate_froom_to_floor.sh

# PowerShell  
.\scripts\migrate_froom_to_floor.ps1
```

**⚠️ Note:** Reverse migration uses specific Floor versions (`^1.4.2`) for testing consistency.

## Troubleshooting

### Linux/macOS Issues
- **Permission denied**: Run `chmod +x scripts/*.sh` to make scripts executable
- **Script not found**: Ensure you're in the project root directory

### Windows Issues
- **PowerShell execution policy**: Use `run_migration.bat` or run PowerShell as administrator
- **Script not recognized**: Ensure you're using PowerShell, not Command Prompt

### General Issues
- **Dependency errors**: Ensure `dart` or `flutter` command is available in PATH
- **Build failures**: Run `flutter clean && flutter pub get` after migration
- **Import errors**: Manually verify all Floor imports are replaced with Froom imports

## Manual Migration

If you prefer manual migration, see the [Migration Guide](../docs/migration-from-floor.md) for step-by-step instructions.

## Support

- [GitHub Issues](https://github.com/wilinz/froom/issues) - Report bugs
- [GitHub Discussions](https://github.com/wilinz/froom/discussions) - Ask questions
- [Documentation](https://wilinz.github.io/froom/) - Full documentation