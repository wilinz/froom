#!/bin/bash

# Reverse Migration Script: Froom to Floor
# This script is for testing purposes - converts Froom project back to Floor

set -e

# Parse command line arguments
CREATE_BACKUP=false
SKIP_CONFIRMATION=false
PROJECT_ROOT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --backup|-b)
            CREATE_BACKUP=true
            shift
            ;;
        --yes|-y)
            SKIP_CONFIRMATION=true
            shift
            ;;
        --path|-p)
            PROJECT_ROOT="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS] [PROJECT_PATH]"
            echo "Options:"
            echo "  --backup, -b           Create backup before migration"
            echo "  --yes, -y              Skip confirmation prompts"
            echo "  --path PATH, -p PATH   Specify project path (default: current directory)"
            echo "  --help, -h             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                           # Migrate current directory"
            echo "  $0 /path/to/project          # Migrate specific directory"
            echo "  $0 --path /path/to/project   # Migrate using --path option"
            echo ""
            echo "⚠️  This is a reverse migration script for testing purposes only!"
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            # If no --path option was used, treat as positional argument
            if [ -z "$PROJECT_ROOT" ]; then
                PROJECT_ROOT="$1"
            else
                echo "Error: Multiple project paths specified"
                exit 1
            fi
            shift
            ;;
    esac
done

# Determine project root
if [ -z "$PROJECT_ROOT" ]; then
    # No path specified, ask user or use current directory
    if [ "$SKIP_CONFIRMATION" = false ]; then
        echo "📍 No project path specified."
        read -p "🤔 Enter project path (press Enter for current directory): " USER_INPUT
        if [ -n "$USER_INPUT" ]; then
            PROJECT_ROOT="$USER_INPUT"
        else
            PROJECT_ROOT="$(pwd)"
        fi
    else
        PROJECT_ROOT="$(pwd)"
    fi
fi

# Convert to absolute path
PROJECT_ROOT="$(cd "$PROJECT_ROOT" 2>/dev/null && pwd)" || {
    echo "❌ Error: Invalid project path '$PROJECT_ROOT'"
    exit 1
}

echo "🔄 Starting reverse migration from Froom to Floor (for testing)..."
echo "📍 Working in: $PROJECT_ROOT"

# Change to project root
cd "$PROJECT_ROOT"

# Handle backup creation
if [ "$CREATE_BACKUP" = true ]; then
    BACKUP_DIR="$PROJECT_ROOT/backup_$(date +%Y%m%d_%H%M%S)"
    echo "📦 Creating backup in $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$PROJECT_ROOT"/* "$BACKUP_DIR/" 2>/dev/null || echo "⚠️  Backup creation had some issues, but continuing..."
    echo "✅ Backup created successfully"
elif [ "$SKIP_CONFIRMATION" = false ]; then
    echo "⚠️  This script will modify your project files (reverse migration for testing)."
    read -p "🤔 Create a backup before proceeding? (Y/n): " -r
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "⚠️  Proceeding without backup..."
    else
        BACKUP_DIR="$PROJECT_ROOT/backup_$(date +%Y%m%d_%H%M%S)"
        echo "📦 Creating backup in $BACKUP_DIR..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$PROJECT_ROOT"/* "$BACKUP_DIR/" 2>/dev/null || echo "⚠️  Backup creation had some issues, but continuing..."
        echo "✅ Backup created successfully"
    fi
else
    echo "⚠️  Proceeding without backup (--yes flag used)..."
fi

# Step 1: Update imports in Dart files
echo "🔄 Updating import statements..."
find . -name "*.dart" -not -path "./build/*" -not -path "./.dart_tool/*" -not -path "$BACKUP_DIR/*" -print0 | \
while IFS= read -r -d '' file; do
    # Use temporary file approach to avoid .bak files
    if grep -q "package:froom" "$file" 2>/dev/null; then
        sed \
            -e "s/import 'package:froom\/froom\.dart';/import 'package:floor\/floor.dart';/g" \
            -e "s/import \"package:froom\/froom\.dart\";/import \"package:floor\/floor.dart\";/g" \
            "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    fi
done

# Step 2: Replace class names
echo "🔄 Updating class names..."
find . -name "*.dart" -not -path "./build/*" -not -path "./.dart_tool/*" -not -path "$BACKUP_DIR/*" -print0 | \
while IFS= read -r -d '' file; do
    if grep -q -E "(FroomDatabase|\\\$Froom)" "$file" 2>/dev/null; then
        sed \
            -e "s/FroomDatabase/FloorDatabase/g" \
            -e "s/\\\$Froom/\$Floor/g" \
            "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    fi
done

# Step 3: Update pubspec.yaml - Remove Froom dependencies and add Floor ones
echo "📝 Updating pubspec.yaml dependencies..."
if [ -f "pubspec.yaml" ]; then
    local deps_to_remove=()
    local deps_to_add=()
    
    # Check what needs to be removed and what to add
    if grep -q "froom:" "pubspec.yaml"; then
        echo "  🗑️  Removing froom dependency"
        deps_to_remove+=("froom")
        deps_to_add+=("floor")
    fi
    
    if grep -q "froom_generator:" "pubspec.yaml"; then
        echo "  🗑️  Removing froom_generator dependency"
        deps_to_remove+=("froom_generator")
        deps_to_add+=("dev:floor_generator")
    fi
    
    # Remove old dependencies
    if [ ${#deps_to_remove[@]} -gt 0 ]; then
        echo "  📝 Removing old dependencies..."
        for dep in "${deps_to_remove[@]}"; do
            if command -v dart &> /dev/null; then
                dart pub remove "$dep" 2>/dev/null || true
            elif command -v flutter &> /dev/null; then
                flutter pub remove "$dep" 2>/dev/null || true
            fi
        done
        
        # Add specific Floor versions for testing
        echo "  ✅ Adding Floor dependencies with specific versions..."
        if command -v dart &> /dev/null; then
            dart pub add floor:^1.4.2 dev:floor_generator:^1.4.2
        elif command -v flutter &> /dev/null; then
            flutter pub add floor:^1.4.2 dev:floor_generator:^1.4.2
        else
            echo "  ⚠️  Neither dart nor flutter command found. Please manually run:"
            echo "      dart pub add floor:^1.4.2 dev:floor_generator:^1.4.2"
        fi
    fi
fi

# Step 4: Clean old generated files
echo "🧹 Cleaning old generated files..."
find . -name "*.g.dart" -not -path "./build/*" -not -path "./.dart_tool/*" -not -path "$BACKUP_DIR/*" -delete

# Step 5: Clean and get dependencies
echo "📦 Getting new dependencies..."
if command -v flutter &> /dev/null; then
    flutter clean
    flutter pub get
else
    dart pub get
fi

# Clean up any leftover temporary files
find . -name "*.tmp" -not -path "$BACKUP_DIR/*" -delete 2>/dev/null || true

echo "✅ Reverse migration completed!"
echo "📁 Backup created in: $BACKUP_DIR"
echo "🔧 Run the following to regenerate Floor code:"
echo "   flutter pub run build_runner build --delete-conflicting-outputs"
echo ""
echo "⚠️  This script is for testing purposes only!"
echo "🔄 To migrate back to Froom, run: ./migrate_floor_to_froom.sh"