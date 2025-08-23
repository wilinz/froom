# Reverse Migration Script: Froom to Floor (PowerShell)
# This script is for testing purposes - converts Froom project back to Floor

param(
    [switch]$Backup,
    [switch]$Yes,
    [switch]$Help,
    [string]$Path = ""
)

if ($Help) {
    Write-Host "Usage: .\migrate_froom_to_floor.ps1 [OPTIONS] [-Path PROJECT_PATH]"
    Write-Host "Options:"
    Write-Host "  -Backup             Create backup before migration"
    Write-Host "  -Yes                Skip confirmation prompts"
    Write-Host "  -Path PROJECT_PATH  Specify project path (default: current directory)"
    Write-Host "  -Help               Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\migrate_froom_to_floor.ps1                      # Migrate current directory"
    Write-Host "  .\migrate_froom_to_floor.ps1 -Path C:\MyProject   # Migrate specific directory"
    Write-Host ""
    Write-Host "⚠️  This is a reverse migration script for testing purposes only!"
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

Write-Host "🔄 Starting reverse migration from Froom to Floor (for testing)..." -ForegroundColor Green
Write-Host "📍 Working in: $ProjectRoot" -ForegroundColor Cyan

# Change to project root
Set-Location $ProjectRoot

# Handle backup creation
if ($Backup) {
    $BackupDir = "$ProjectRoot/backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Write-Host "📦 Creating backup in $BackupDir..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
    Copy-Item -Path "$ProjectRoot\*" -Destination $BackupDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Backup created successfully" -ForegroundColor Green
}
elseif (-not $Yes) {
    Write-Host "⚠️  This script will modify your project files (reverse migration for testing)." -ForegroundColor Yellow
    $response = Read-Host "🤔 Create a backup before proceeding? (Y/n)"
    if ($response -match "^[Nn]$") {
        Write-Host "⚠️  Proceeding without backup..." -ForegroundColor Yellow
    }
    else {
        $BackupDir = "$ProjectRoot/backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Write-Host "📦 Creating backup in $BackupDir..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
        Copy-Item -Path "$ProjectRoot\*" -Destination $BackupDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Backup created successfully" -ForegroundColor Green
    }
}
else {
    Write-Host "⚠️  Proceeding without backup (-Yes flag used)..." -ForegroundColor Yellow
}

# Step 1: Update imports in Dart files
Write-Host "🔄 Updating import statements..." -ForegroundColor Cyan
$DartFiles = Get-ChildItem -Path "." -Name "*.dart" -Recurse | Where-Object {
    $_ -notmatch "\\build\\" -and 
    $_ -notmatch "\\.dart_tool\\" -and 
    ($BackupDir -eq $null -or $_ -notmatch [regex]::Escape($BackupDir))
}

foreach ($file in $DartFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
        if ($content -and $content -match "package:froom") {
            $newContent = $content -replace "import 'package:froom/froom\.dart';", "import 'package:floor/floor.dart';"
            $newContent = $newContent -replace 'import "package:froom/froom\.dart";', "import 'package:floor/floor.dart';"
            Set-Content -Path $file -Value $newContent -NoNewline
        }
    }
}

# Step 2: Replace class names
Write-Host "🔄 Updating class names..." -ForegroundColor Cyan
foreach ($file in $DartFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
        if ($content -and ($content -match "FroomDatabase" -or $content -match "\\\$Froom")) {
            $newContent = $content -replace "FroomDatabase", "FloorDatabase"
            $newContent = $newContent -replace "\\\$Froom", '$Floor'
            Set-Content -Path $file -Value $newContent -NoNewline
        }
    }
}

# Step 3: Update pubspec.yaml - Remove Froom dependencies and add Floor ones
Write-Host "📝 Updating pubspec.yaml dependencies..." -ForegroundColor Cyan
if (Test-Path "pubspec.yaml") {
    $DepsToRemove = @()
    $DepsToAdd = @()
    
    $pubspecContent = Get-Content "pubspec.yaml" -Raw
    
    # Check what needs to be removed and what to add
    if ($pubspecContent -match "froom:") {
        Write-Host "  🗑️  Removing froom dependency" -ForegroundColor Gray
        $DepsToRemove += "froom"
        $DepsToAdd += "floor"
    }
    
    if ($pubspecContent -match "froom_generator:") {
        Write-Host "  🗑️  Removing froom_generator dependency" -ForegroundColor Gray
        $DepsToRemove += "froom_generator"
        $DepsToAdd += "dev:floor_generator"
    }
    
    # Remove old dependencies
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
        
        # Add specific Floor versions for testing
        Write-Host "  ✅ Adding Floor dependencies with specific versions..." -ForegroundColor Gray
        try {
            if (Get-Command dart -ErrorAction SilentlyContinue) {
                & dart pub add "floor:^1.4.2" "dev:floor_generator:^1.4.2"
            }
            elseif (Get-Command flutter -ErrorAction SilentlyContinue) {
                & flutter pub add "floor:^1.4.2" "dev:floor_generator:^1.4.2"
            }
            else {
                Write-Host "  ⚠️  Neither dart nor flutter command found. Please manually run:" -ForegroundColor Yellow
                Write-Host "      dart pub add floor:^1.4.2 dev:floor_generator:^1.4.2" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "  ⚠️  Error adding dependencies. Please run manually:" -ForegroundColor Yellow
            Write-Host "      dart pub add floor:^1.4.2 dev:floor_generator:^1.4.2" -ForegroundColor Yellow
        }
    }
}

# Step 4: Clean old generated files
Write-Host "🧹 Cleaning old generated files..." -ForegroundColor Cyan
$GeneratedFiles = Get-ChildItem -Path "." -Name "*.g.dart" -Recurse | Where-Object {
    $_ -notmatch "\\build\\" -and 
    $_ -notmatch "\\.dart_tool\\" -and 
    ($BackupDir -eq $null -or $_ -notmatch [regex]::Escape($BackupDir))
}

foreach ($file in $GeneratedFiles) {
    Remove-Item $file -Force -ErrorAction SilentlyContinue
}

# Step 5: Clean and get dependencies
Write-Host "📦 Getting new dependencies..." -ForegroundColor Cyan
try {
    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        & flutter clean
        & flutter pub get
    }
    else {
        & dart pub get
    }
}
catch {
    Write-Host "⚠️  Error getting dependencies. Please run manually." -ForegroundColor Yellow
}

Write-Host "✅ Reverse migration completed!" -ForegroundColor Green
if ($BackupDir) {
    Write-Host "📁 Backup created in: $BackupDir" -ForegroundColor Gray
}
Write-Host "🔧 Run the following to regenerate Floor code:" -ForegroundColor Cyan
Write-Host "   flutter pub run build_runner build --delete-conflicting-outputs" -ForegroundColor Gray
Write-Host ""
Write-Host "⚠️  This script is for testing purposes only!" -ForegroundColor Yellow
Write-Host "🔄 To migrate back to Froom, run: .\migrate_floor_to_froom.ps1" -ForegroundColor Gray