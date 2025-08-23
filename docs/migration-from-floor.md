# Migration from Floor to Froom

This guide will help you migrate your existing Floor project to Froom. Froom is built as a modern replacement for Floor, offering better compatibility with current Flutter versions and additional features.

## Version Compatibility

Before migrating, ensure you're using the correct Froom version based on your dependencies:

| source_gen Version | Froom Version |
|--------------------|---------------|
| 3.x.x and above   | 3.x.x         |
| 2.x.x             | 2.0.4         |

## ⚠️ Important: Backup Your Project

**Before starting the migration, always create a complete backup of your project!**

You can create a backup by:
```bash
# Create a backup directory
cp -r your_project_directory your_project_directory_backup

# Or use git to commit your current state
git add .
git commit -m "Backup before Floor to Froom migration"
```

The automated migration script will also create a backup automatically, but it's always safer to have your own backup.

## Migration Steps

### 1. Update Dependencies

Replace Floor dependencies with Froom in your `pubspec.yaml`:

**Before (Floor):**
```yaml
dependencies:
  floor: ^1.4.2

dev_dependencies:
  floor_generator: ^1.4.2
  build_runner: ^2.1.2
```

**After (Froom):**
```yaml
dependencies:
  froom: ^x.x.x

dev_dependencies:
  froom_generator: ^x.x.x
  build_runner: ^x.x.x
```

**💡 Tip: Use command for easier installation:**
```bash
dart pub add froom dev:froom_generator dev:build_runner
```
This command automatically adds the latest compatible versions without manually editing `pubspec.yaml`.

### 2. Update Import Statements

Replace all Floor package imports with Froom imports:

**Before:**
```dart
import 'package:floor/floor.dart';
import 'package:floor_annotation/floor_annotation.dart';
```

**After:**
```dart
import 'package:froom/froom.dart';
import 'package:froom_annotation/froom_annotation.dart';
```

### 3. Update Database Class

Update your database class to extend `FroomDatabase` instead of `FloorDatabase`:

**Before:**
```dart
@Database(version: 1, entities: [Person])
abstract class AppDatabase extends FloorDatabase {
  PersonDao get personDao;
}
```

**After:**
```dart
@Database(version: 1, entities: [Person])
abstract class AppDatabase extends FroomDatabase {
  PersonDao get personDao;
}
```

### 4. Update Database Builder

Update the database builder class name:

**Before:**
```dart
final database = await $FloorAppDatabase.databaseBuilder('app_database.db').build();
```

**After:**
```dart
final database = await $FroomAppDatabase.databaseBuilder('app_database.db').build();
```

### 5. Regenerate Code

After making these changes, regenerate your database code:

```bash
flutter packages pub run build_runner clean
flutter packages pub run build_runner build
```

## Automated Migration Scripts

We provide migration scripts for different platforms to automate most of the migration process:

**📁 Script Location:** All migration scripts can be found in the [scripts directory](https://github.com/wilinz/froom/tree/main/scripts) of this repository.

### Linux/macOS (Bash)

```bash
# Make script executable
chmod +x scripts/migrate_floor_to_froom.sh

# Interactive mode (default) - asks before creating backup
./scripts/migrate_floor_to_froom.sh

# Force create backup without asking
./scripts/migrate_floor_to_froom.sh --backup

# Skip all confirmations (no backup)
./scripts/migrate_floor_to_froom.sh --yes

# Create backup and skip confirmations
./scripts/migrate_floor_to_froom.sh --backup --yes

# Specify project path (multiple ways)
./scripts/migrate_floor_to_froom.sh /path/to/project              # Positional argument
./scripts/migrate_floor_to_froom.sh --path /path/to/project       # Named option
./scripts/migrate_floor_to_froom.sh -p /path/to/project           # Short option

# Combined options
./scripts/migrate_floor_to_froom.sh --path /path/to/project --backup --yes

# Show help
./scripts/migrate_floor_to_froom.sh --help
```

### Windows (PowerShell)

**⚠️ PowerShell Execution Policy Notice:**

Windows PowerShell may restrict script execution due to security policies. If you encounter execution policy errors, you have several options:

**Option 1: Use the batch launcher (Recommended for most users)**
```cmd
# This automatically handles execution policy issues
.\scripts\run_migration.bat
```

**Option 2: Temporarily bypass execution policy**
```powershell
# Run migration with bypassed policy (one-time)
PowerShell -ExecutionPolicy Bypass -File ".\scripts\migrate_floor_to_froom.ps1"
```

**Option 3: Change execution policy (Requires Administrator)**
```powershell
# Open PowerShell as Administrator and run:
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or for system-wide (requires elevated permissions):
Set-ExecutionPolicy RemoteSigned -Force
```

**Option 4: Unrestricted execution (Less secure, not recommended)**
```powershell
# Temporarily allow all scripts (use with caution)
Set-ExecutionPolicy Unrestricted -Scope CurrentUser

# Remember to revert after migration:
Set-ExecutionPolicy Restricted -Scope CurrentUser
```

**Regular Usage (after policy is configured):**
```powershell
# Interactive mode (default) - asks before creating backup
.\scripts\migrate_floor_to_froom.ps1

# Force create backup without asking
.\scripts\migrate_floor_to_froom.ps1 -Backup

# Skip all confirmations (no backup)
.\scripts\migrate_floor_to_froom.ps1 -Yes

# Create backup and skip confirmations
.\scripts\migrate_floor_to_froom.ps1 -Backup -Yes

# Specify project path
.\scripts\migrate_floor_to_froom.ps1 -Path "C:\path\to\project"

# Combined options
.\scripts\migrate_floor_to_froom.ps1 -Path "C:\path\to\project" -Backup -Yes

# Show help
.\scripts\migrate_floor_to_froom.ps1 -Help
```

### Windows (Batch Launcher)

For Windows users who may have PowerShell execution policy restrictions:

```cmd
# GUI launcher that handles PowerShell execution policy automatically
.\scripts\run_migration.bat
```

The batch launcher will:
- Check PowerShell execution policy
- Offer to bypass or change policy if needed
- Provide an interactive menu to select migration scripts
- Handle script arguments through prompts

### Available Options

**Bash Scripts:**
| Option | Short | Description |
|--------|-------|-------------|
| `--backup` | `-b` | Create backup before migration |
| `--yes` | `-y` | Skip confirmation prompts |
| `--path PATH` | `-p PATH` | Specify project path |
| `--help` | `-h` | Show help message |

**PowerShell Scripts:**
| Parameter | Description |
|-----------|-------------|
| `-Backup` | Create backup before migration |
| `-Yes` | Skip confirmation prompts |
| `-Path "PATH"` | Specify project path |
| `-Help` | Show help message |

### What the Script Does
- Update all Floor imports to Froom imports
- Replace `FloorDatabase` with `FroomDatabase`
- Replace `$Floor` prefixes with `$Froom`
- Update your `pubspec.yaml` dependencies
- Clean old generated files

**Note:** The script can create automatic backups and provides interactive confirmations for safe migration.

## Manual Review Required

After running the automated migration, you should manually review:

1. **pubspec.yaml** - Ensure correct version numbers
2. **Generated files** - Delete old `.g.dart` files and regenerate
3. **Custom code** - Check any custom Floor-specific code that might need updates
4. **Tests** - Update any tests that reference Floor classes

## Key Differences

While Froom maintains API compatibility with Floor, there are some key improvements:

1. **Better analyzer support** - Compatible with analyzer 7.x
2. **Modern dependencies** - Updated to work with latest Flutter versions
3. **Improved error handling** - Better debugging experience
4. **Active maintenance** - Regular updates and bug fixes

## Troubleshooting

### Common Issues

1. **Build errors after migration**
   - Clean and rebuild: `flutter packages pub run build_runner clean && flutter packages pub run build_runner build`
   - Delete existing `.g.dart` files manually if needed

2. **Import errors**
   - Ensure all Floor imports are replaced with Froom imports
   - Check that you're using the correct Froom version

3. **Database builder errors**
   - Verify all `$Floor` prefixes are changed to `$Froom`

4. **PowerShell execution policy errors (Windows)**
   - Use the batch launcher: `.\scripts\run_migration.bat`
   - Or temporarily bypass: `PowerShell -ExecutionPolicy Bypass -File ".\scripts\migrate_floor_to_froom.ps1"`
   - Or check current policy: `Get-ExecutionPolicy`

### Getting Help

If you encounter issues during migration:

- Check [GitHub Issues](https://github.com/wilinz/froom/issues) for known issues
- Ask questions in [GitHub Discussions](https://github.com/wilinz/froom/discussions)
- Review the complete [Froom documentation](https://wilinz.github.io/froom/)

## Migration Checklist

- [ ] Update `pubspec.yaml` dependencies
- [ ] Replace all Floor imports with Froom imports
- [ ] Update database class to extend `FroomDatabase`
- [ ] Update database builder class names
- [ ] Run migration script (optional)
- [ ] Clean and regenerate code
- [ ] Test your application thoroughly
- [ ] Update any documentation references