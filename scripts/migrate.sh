#!/bin/bash

# Froom Migration Script - One Command Migration
# This script handles the complete migration from older versions to v3.0.0

set -e

echo "🚀 Starting Froom migration to v3.0.0..."

# Step 1: Update dependencies
echo "📦 Updating dependencies..."
flutter pub add froom
flutter pub add --dev froom_generator
flutter pub add --dev build_runner

# Step 2: Clean and get dependencies
echo "🧹 Cleaning and getting dependencies..."
flutter clean
flutter pub get

# Step 3: Run code generation
echo "⚙️ Running code generation..."
flutter pub run build_runner build --delete-conflicting-outputs

# Step 4: Run tests (optional)
echo "🧪 Running tests..."
flutter test || echo "⚠️ Some tests failed, please check manually"

echo "✅ Migration completed successfully!"
echo "📖 Please check the CHANGELOG.md for breaking changes and update your code accordingly."
echo "💡 If you encounter issues, refer to the migration guide in docs/migration-from-floor.md"