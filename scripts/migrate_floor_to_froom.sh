#!/bin/bash

# Floor to Froom Migration Script
# This script automates the migration from Floor to Froom

set -e  # Exit on any error

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
            echo "  $0 --backup --yes            # Automated migration with backup"
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

echo "🚀 Starting Floor to Froom migration..."
echo "📍 Working in: $PROJECT_ROOT"

# Change to project root
cd "$PROJECT_ROOT"

# Check if we're in a Flutter/Dart project
if [ ! -f "$PROJECT_ROOT/pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found in $PROJECT_ROOT. Please ensure the script is in your project root directory."
    exit 1
fi

# Handle backup creation
if [ "$CREATE_BACKUP" = true ]; then
    BACKUP_DIR="$PROJECT_ROOT/floor_to_froom_backup_$(date +%Y%m%d_%H%M%S)"
    echo "📦 Creating backup in $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$PROJECT_ROOT"/* "$BACKUP_DIR/" 2>/dev/null || true
    echo "✅ Backup created successfully"
elif [ "$SKIP_CONFIRMATION" = false ]; then
    echo "⚠️  This script will modify your project files."
    read -p "🤔 Create a backup before proceeding? (Y/n): " -r
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "⚠️  Proceeding without backup..."
    else
        BACKUP_DIR="$PROJECT_ROOT/floor_to_froom_backup_$(date +%Y%m%d_%H%M%S)"
        echo "📦 Creating backup in $BACKUP_DIR..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$PROJECT_ROOT"/* "$BACKUP_DIR/" 2>/dev/null || true
        echo "✅ Backup created successfully"
    fi
else
    echo "⚠️  Proceeding without backup (--yes flag used)..."
fi

# Find all Dart files (excluding generated files and build directories)
DART_FILES=$(find . -name "*.dart" -not -path "./build/*" -not -path "./.dart_tool/*" -not -path "*/.*" -not -name "*.g.dart" -not -name "*.freezed.dart")

if [ -z "$DART_FILES" ]; then
    echo "❌ No Dart files found to migrate"
    exit 1
fi

echo "🔍 Found $(echo "$DART_FILES" | wc -l) Dart files to process"

# Counter for changes
CHANGES_MADE=0

# Function to replace in file and count changes
replace_in_file() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    local description="$4"
    
    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo "  📝 $description in $(basename "$file")"
        # Use temporary file approach to avoid .bak files
        sed "s|$pattern|$replacement|g" "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
        CHANGES_MADE=$((CHANGES_MADE + 1))
    fi
}

# Process each Dart file
echo "🔄 Processing Dart files..."
for file in $DART_FILES; do
    if [ -f "$file" ]; then
        # Skip if file is empty or unreadable
        if [ ! -s "$file" ]; then
            continue
        fi
        
        # Replace Floor imports with Froom imports
        replace_in_file "$file" "import 'package:floor/floor\.dart';" "import 'package:froom/froom.dart';" "Replacing Floor import"
        replace_in_file "$file" "import 'package:floor_annotation/floor_annotation\.dart';" "import 'package:froom/froom.dart';" "Replacing Floor annotation import"
        replace_in_file "$file" "import \"package:floor/floor\.dart\";" "import 'package:froom/froom.dart';" "Replacing Floor import (double quotes)"
        replace_in_file "$file" "import \"package:floor_annotation/floor_annotation\.dart\";" "import 'package:froom/froom.dart';" "Replacing Floor annotation import (double quotes)"
        
        # Replace FloorDatabase with FroomDatabase
        replace_in_file "$file" "extends FloorDatabase" "extends FroomDatabase" "Replacing FloorDatabase extension"
        
        # Replace $Floor prefixes with $Froom
        replace_in_file "$file" "\\\$Floor" "\$Froom" "Replacing \$Floor prefix"
        
        # Replace any remaining Floor references in class names
        replace_in_file "$file" "FloorDatabase" "FroomDatabase" "Replacing FloorDatabase class references"
    fi
done

# Process pubspec.yaml - Remove old dependencies and add new ones
echo "📦 Updating pubspec.yaml dependencies..."
if [ -f "pubspec.yaml" ]; then
    local deps_to_remove=()
    local deps_to_add=()
    
    # Check what needs to be removed and what to add
    if grep -q "floor:" "pubspec.yaml"; then
        echo "  🗑️  Removing floor dependency"
        deps_to_remove+=("floor")
        deps_to_add+=("froom")
        CHANGES_MADE=$((CHANGES_MADE + 1))
    fi
    
    if grep -q "floor_generator:" "pubspec.yaml"; then
        echo "  🗑️  Removing floor_generator dependency"
        deps_to_remove+=("floor_generator")
        deps_to_add+=("dev:froom_generator")
        CHANGES_MADE=$((CHANGES_MADE + 1))
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
        
        # Add new dependencies
        echo "  ✅ Adding new dependencies..."
        if command -v dart &> /dev/null; then
            dart pub add "${deps_to_add[@]}"
        elif command -v flutter &> /dev/null; then
            flutter pub add "${deps_to_add[@]}"
        else
            echo "  ⚠️  Neither dart nor flutter command found. Please manually run:"
            echo "      dart pub add ${deps_to_add[*]}"
        fi
    fi
else
    echo "⚠️  Warning: pubspec.yaml not found"
fi

# Clean generated files
echo "🧹 Cleaning generated files..."
GENERATED_FILES=$(find . -name "*.g.dart" -not -path "./build/*" -not -path "./.dart_tool/*")
if [ ! -z "$GENERATED_FILES" ]; then
    echo "  🗑️  Removing old generated files..."
    echo "$GENERATED_FILES" | xargs rm -f
    echo "  ✅ Removed $(echo "$GENERATED_FILES" | wc -l) generated files"
else
    echo "  ℹ️  No generated files found to clean"
fi

# Summary
echo ""
echo "✨ Migration completed!"
echo "📊 Summary:"
echo "   • Made $CHANGES_MADE file modifications"
if [ -n "${BACKUP_DIR:-}" ]; then
    echo "   • Backup created in: $BACKUP_DIR"
fi
echo ""
echo "🔧 Next steps:"
echo "   1. Run 'flutter packages pub run build_runner build' to regenerate code"
echo "   2. Test your application thoroughly" 
echo "   3. Review the changes and remove backup if everything works"
echo ""
echo "📚 For more information, see: docs/migration-from-floor.md"

# Optional: Run build_runner automatically
read -p "🤔 Would you like to regenerate code with build_runner now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔨 Running build_runner..."
    if command -v flutter &> /dev/null; then
        flutter packages pub run build_runner build --delete-conflicting-outputs
    else
        dart run build_runner build --delete-conflicting-outputs
    fi
    echo "✅ Code regenerated"
fi

# Clean up any leftover temporary files
find . -name "*.tmp" -not -path "$BACKUP_DIR/*" -delete 2>/dev/null || true

echo ""
echo "🎉 Floor to Froom migration script completed!"
echo "⚠️  Remember to test your application and review all changes before proceeding."