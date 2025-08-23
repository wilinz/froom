# Froom Migration Script - One Command Migration (PowerShell)
# This script handles the complete migration from older versions to v3.0.0

Write-Host "🚀 Starting Froom migration to v3.0.0..." -ForegroundColor Green

# Step 1: Update dependencies
Write-Host "📦 Updating dependencies..." -ForegroundColor Cyan
try {
    & flutter pub add froom
    & flutter pub add --dev froom_generator
    & flutter pub add --dev build_runner
}
catch {
    Write-Host "⚠️ Error updating dependencies. Please check your network connection and try again." -ForegroundColor Yellow
    exit 1
}

# Step 2: Clean and get dependencies
Write-Host "🧹 Cleaning and getting dependencies..." -ForegroundColor Cyan
try {
    & flutter clean
    & flutter pub get
}
catch {
    Write-Host "⚠️ Error cleaning/getting dependencies." -ForegroundColor Yellow
}

# Step 3: Run code generation
Write-Host "⚙️ Running code generation..." -ForegroundColor Cyan
try {
    & flutter pub run build_runner build --delete-conflicting-outputs
}
catch {
    Write-Host "⚠️ Error running code generation." -ForegroundColor Yellow
}

# Step 4: Run tests (optional)
Write-Host "🧪 Running tests..." -ForegroundColor Cyan
try {
    & flutter test
}
catch {
    Write-Host "⚠️ Some tests failed, please check manually" -ForegroundColor Yellow
}

Write-Host "✅ Migration completed successfully!" -ForegroundColor Green
Write-Host "📖 Please check the CHANGELOG.md for breaking changes and update your code accordingly." -ForegroundColor Gray
Write-Host "💡 If you encounter issues, refer to the migration guide in docs/migration-from-floor.md" -ForegroundColor Gray