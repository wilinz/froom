# Floor to Froom Migration Script (PowerShell)
# This script automates the migration from Floor to Froom

param(
    [switch]$Backup,
    [switch]$Yes,
    [switch]$Help,
    [string]$Path = ""
)

if ($Help) {
    Write-Host "Usage: .\migrate_floor_to_froom.ps1 [OPTIONS] [-Path PROJECT_PATH]"
    Write-Host "Options:"
    Write-Host "  -Backup             Create backup before migration"
    Write-Host "  -Yes                Skip confirmation prompts"
    Write-Host "  -Path PROJECT_PATH  Specify project path (default: current directory)"
    Write-Host "  -Help               Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\migrate_floor_to_froom.ps1                      # Migrate current directory"
    Write-Host "  .\migrate_floor_to_froom.ps1 -Path C:\MyProject   # Migrate specific directory"
    Write-Host "  .\migrate_floor_to_froom.ps1 -Backup -Yes         # Automated migration with backup"
    exit 0
}

# Determine project root
if ($Path -eq "") {
    # No path specified, ask user or use current directory
    if (-not $Yes) {
        Write-Host "📍 No project path specified." -ForegroundColor Cyan
        $UserInput = Read-Host "🤔 Enter project path (press Enter for current directory)"
        if ($UserInput -ne "") {
            $ProjectRoot = $UserInput
        } else {
            $ProjectRoot = Get-Location
        }
    } else {
        $ProjectRoot = Get-Location
    }
} else {
    $ProjectRoot = $Path
}

# Convert to absolute path and validate
try {
    $ProjectRoot = Resolve-Path $ProjectRoot -ErrorAction Stop
} catch {
    Write-Host "❌ Error: Invalid project path '$ProjectRoot'" -ForegroundColor Red
    exit 1
}

Write-Host "🚀 Starting Floor to Froom migration..." -ForegroundColor Green
Write-Host "📍 Working in: $ProjectRoot" -ForegroundColor Cyan

# Change to project root
Set-Location $ProjectRoot

# Check if we're in a Flutter/Dart project
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "❌ Error: pubspec.yaml not found in $ProjectRoot. Please ensure the script is in your project root directory." -ForegroundColor Red
    exit 1
}

# Handle backup creation
if ($Backup) {
    $BackupDir = "$ProjectRoot/floor_to_froom_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Write-Host "📦 Creating backup in $BackupDir..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
    Copy-Item -Path "$ProjectRoot\*" -Destination $BackupDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Backup created successfully" -ForegroundColor Green
}
elseif (-not $Yes) {
    Write-Host "⚠️  This script will modify your project files." -ForegroundColor Yellow
    $response = Read-Host "🤔 Create a backup before proceeding? (Y/n)"
    if ($response -match "^[Nn]$") {
        Write-Host "⚠️  Proceeding without backup..." -ForegroundColor Yellow
    }
    else {
        $BackupDir = "$ProjectRoot/floor_to_froom_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Write-Host "📦 Creating backup in $BackupDir..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
        Copy-Item -Path "$ProjectRoot\*" -Destination $BackupDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Backup created successfully" -ForegroundColor Green
    }
}
else {
    Write-Host "⚠️  Proceeding without backup (-Yes flag used)..." -ForegroundColor Yellow
}

# Find all Dart files (excluding generated files and build directories)
$DartFiles = Get-ChildItem -Path "." -Name "*.dart" -Recurse | Where-Object {
    $_ -notmatch "\\build\\" -and 
    $_ -notmatch "\\.dart_tool\\" -and 
    $_ -notmatch "\\.*" -and 
    $_ -notmatch "\\.g\\.dart$" -and 
    $_ -notmatch "\\.freezed\\.dart$"
}

if (-not $DartFiles) {
    Write-Host "❌ No Dart files found to migrate" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Found $($DartFiles.Count) Dart files to process" -ForegroundColor Cyan

# Counter for changes
$ChangesMade = 0

# Function to replace in file and count changes
function Replace-InFile {
    param(
        [string]$FilePath,
        [string]$Pattern,
        [string]$Replacement,
        [string]$Description
    )
    
    if (Test-Path $FilePath) {
        $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
        if ($content -and $content -match $Pattern) {
            Write-Host "  📝 $Description in $(Split-Path -Leaf $FilePath)" -ForegroundColor Gray
            $newContent = $content -replace $Pattern, $Replacement
            Set-Content -Path $FilePath -Value $newContent -NoNewline
            $script:ChangesMade++
        }
    }
}

# Process each Dart file
Write-Host "🔄 Processing Dart files..." -ForegroundColor Cyan
foreach ($file in $DartFiles) {
    if (Test-Path $file -and (Get-Item $file).Length -gt 0) {
        # Replace Floor imports with Froom imports
        Replace-InFile $file "import 'package:floor/floor\.dart';" "import 'package:froom/froom.dart';" "Replacing Floor import"
        Replace-InFile $file "import 'package:floor_annotation/floor_annotation\.dart';" "import 'package:froom/froom.dart';" "Replacing Floor annotation import"
        Replace-InFile $file 'import "package:floor/floor\.dart";' "import 'package:froom/froom.dart';" "Replacing Floor import (double quotes)"
        Replace-InFile $file 'import "package:floor_annotation/floor_annotation\.dart";' "import 'package:froom/froom.dart';" "Replacing Floor annotation import (double quotes)"
        
        # Replace FloorDatabase with FroomDatabase
        Replace-InFile $file "extends FloorDatabase" "extends FroomDatabase" "Replacing FloorDatabase extension"
        
        # Replace $Floor prefixes with $Froom
        Replace-InFile $file "\\\$Floor" '$Froom' "Replacing `$Floor prefix"
        
        # Replace any remaining Floor references in class names
        Replace-InFile $file "FloorDatabase" "FroomDatabase" "Replacing FloorDatabase class references"
    }
}

# Process pubspec.yaml - Remove old dependencies and add new ones
Write-Host "📦 Updating pubspec.yaml dependencies..." -ForegroundColor Cyan
if (Test-Path "pubspec.yaml") {
    $DepsToRemove = @()
    $DepsToAdd = @()
    
    $pubspecContent = Get-Content "pubspec.yaml" -Raw
    
    # Check what needs to be removed and what to add
    if ($pubspecContent -match "floor:") {
        Write-Host "  🗑️  Removing floor dependency" -ForegroundColor Gray
        $DepsToRemove += "floor"
        $DepsToAdd += "froom"
        $ChangesMade++
    }
    
    if ($pubspecContent -match "floor_generator:") {
        Write-Host "  🗑️  Removing floor_generator dependency" -ForegroundColor Gray
        $DepsToRemove += "floor_generator"
        $DepsToAdd += "dev:froom_generator"
        $ChangesMade++
    }
    
    # Remove old dependencies and add new ones
    if ($DepsToRemove.Count -gt 0) {
        Write-Host "  📝 Removing old dependencies..." -ForegroundColor Gray
        foreach ($dep in $DepsToRemove) {
            try {
                if (Get-Command dart -ErrorAction SilentlyContinue) {
                    & dart pub remove $dep 2>$null
                }
                elseif (Get-Command flutter -ErrorAction SilentlyContinue) {
                    & flutter pub remove $dep 2>$null
                }
            }
            catch {
                # Ignore errors
            }
        }
        
        # Add new dependencies
        Write-Host "  ✅ Adding new dependencies..." -ForegroundColor Gray
        try {
            if (Get-Command dart -ErrorAction SilentlyContinue) {
                & dart pub add froom dev:froom_generator
            }
            elseif (Get-Command flutter -ErrorAction SilentlyContinue) {
                & flutter pub add froom dev:froom_generator
            }
            else {
                Write-Host "  ⚠️  Neither dart nor flutter command found. Please manually run:" -ForegroundColor Yellow
                Write-Host "      dart pub add froom dev:froom_generator" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "  ⚠️  Error adding dependencies. Please run manually:" -ForegroundColor Yellow
            Write-Host "      dart pub add froom dev:froom_generator" -ForegroundColor Yellow
        }
    }
}
else {
    Write-Host "⚠️  Warning: pubspec.yaml not found" -ForegroundColor Yellow
}

# Clean generated files
Write-Host "🧹 Cleaning generated files..." -ForegroundColor Cyan
$GeneratedFiles = Get-ChildItem -Path "." -Name "*.g.dart" -Recurse | Where-Object {
    $_ -notmatch "\\build\\" -and $_ -notmatch "\\.dart_tool\\"
}

if ($GeneratedFiles) {
    Write-Host "  🗑️  Removing old generated files..." -ForegroundColor Gray
    foreach ($file in $GeneratedFiles) {
        Remove-Item $file -Force -ErrorAction SilentlyContinue
    }
    Write-Host "  ✅ Removed $($GeneratedFiles.Count) generated files" -ForegroundColor Green
}
else {
    Write-Host "  ℹ️  No generated files found to clean" -ForegroundColor Gray
}

# Summary
Write-Host ""
Write-Host "✨ Migration completed!" -ForegroundColor Green
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "   • Made $ChangesMade file modifications" -ForegroundColor Gray
if ($BackupDir) {
    Write-Host "   • Backup created in: $BackupDir" -ForegroundColor Gray
}
Write-Host ""
Write-Host "🔧 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Run 'flutter packages pub run build_runner build' to regenerate code" -ForegroundColor Gray
Write-Host "   2. Test your application thoroughly" -ForegroundColor Gray
Write-Host "   3. Review the changes and remove backup if everything works" -ForegroundColor Gray
Write-Host ""
Write-Host "📚 For more information, see: docs/migration-from-floor.md" -ForegroundColor Gray

# Optional: Run build_runner automatically
if (-not $Yes) {
    $response = Read-Host "🤔 Would you like to regenerate code with build_runner now? (y/n)"
    if ($response -match "^[Yy]$") {
        Write-Host "🔨 Running build_runner..." -ForegroundColor Yellow
        try {
            if (Get-Command flutter -ErrorAction SilentlyContinue) {
                & flutter packages pub run build_runner build --delete-conflicting-outputs
            }
            else {
                & dart run build_runner build --delete-conflicting-outputs
            }
            Write-Host "✅ Code regenerated" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠️  Error running build_runner. Please run manually." -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "🎉 Floor to Froom migration script completed!" -ForegroundColor Green
Write-Host "⚠️  Remember to test your application and review all changes before proceeding." -ForegroundColor Yellow