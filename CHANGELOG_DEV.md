# Changelog

## [Unreleased]

## [4.0.0] - 2025-09-10

### 🔄 Breaking Changes
- **froom_generator**: Migrated from analyzer element2 API to element API (b1d050e)

### ⬆️ Dependencies
- **analyzer**: Bumped to version 8.1.1 in example projects (566fe11)
- **build**: Updated dependency versions in froom and froom_common (6e3522b)
- **source_gen**: Updated dependency versions in froom and froom_common (6e3522b)

### ✨ Features
- **query_adapter**: Added custom SqlParseException for invalid SQL statements (2b8f8b7)
- **ci**: Added workflow to sync upstream issues with enhanced functionality (9cb165a, 74a0b04, 047374f)
  - Fetch 150 upstream issues, sort by newest and log count (01fcdff)
  - Replace inline node script with sync_issues.js
  - Add label creation, dedupe by upstream ref, comment sync and improved error handling
- **ci**: Added workflow to delete upstream-synced issues with dry-run and confirmation (f83dcb2)

### 🐛 Bug Fixes
- **ci**: Fixed upstream issues sync workflow scheduling and validation (2664eb4)
- **ci**: Fixed sorting of upstream issues by oldest first (40f03c0, 4507b3c)

### 🔧 Chores
- **scripts**: Removed explicit package versions and normalized /ignore/ entry in migrate.sh (647a590)
- **gitignore**: Added /ignore/ entry to .gitignore (ac8d241)
- **ci**: Updated ci.yml configuration (4b3d0da)

### 📝 All Commits Since v3.0.2
- 6533150: Merge pull request #158 from wilinz/feature/update-deps-4.0.0
- 566fe11: ⬆️ deps(example): bump analyzer to 8.1.1 and update dev/transitive dependencies in example pubspecs
- 6e3522b: ⬆️ chore(pubspec.lock): bump dependency versions in froom and froom_common (analyzer, build, source_gen)
- b1d050e: ♻️ refactor(froom_generator): migrate from analyzer element2 API to element API and update deps
- 647a590: 🔧 chore(scripts/migrate.sh, .gitignore): remove explicit package versions and normalize /ignore/ entry
- ac8d241: 🧹 chore(.gitignore): add /ignore/ entry to .gitignore
- 2b8f8b7: ✨ feat(query_adapter): add custom SqlParseException for invalid SQL statements
- 2664eb4: 🐛 fix(.github/workflows/sync-upstream-issues.yml): disable schedule; validate and extract new issue number from create output
- 40f03c0: 🐛 fix(.github/workflows/sync-upstream-issues.yml): sort upstream issues by oldest first
- 4507b3c: 🐛 fix(.github/workflows/sync-upstream-issues.yml): sort upstream issues by oldest first
- f83dcb2: 👷 ci(.github/workflows/delete-upstream-issues.yml): add workflow to delete upstream-synced issues with dry-run and confirmation
- 01fcdff: ✨ feat(.github/workflows/sync-upstream-issues.yml): fetch 150 upstream issues, sort by newest and log count
- 9cb165a: ✨ feat(.github/workflows/sync-upstream-issues.yml): replace inline node script with sync_issues.js; add label creation, dedupe by upstream ref, comment sync and improved error handling
- 74a0b04: ✨ feat(.github/workflows/sync-upstream-issues.yml): replace inline node script with sync_issues.js; add label creation, dedupe by upstream ref, comment sync and improved error handling
- 047374f: ✨ feat(.github/workflows): add daily workflow to sync upstream issues
- dca2e89: ✨ feat(.github/workflows): add daily workflow to sync upstream issues
- 4b3d0da: Update ci.yml

## 3.0.0

### 🐛 Bug Fixes
- **publish_kit**: Fix root path detection by resolving script location instead of current directory
- **publish_kit**: Remove 'publish_to' field from pubspec using yaml_edit for proper field cleanup

### ♻️ Refactoring
- **analyzer**: Migrate to analyzer 7.x and element2 API throughout codebase
- **type_utils**: Use TypeChecker.typeNamed instead of fromRuntime
- **dart_type_extension**: Add getDisplayStringCompat for analyzer 7.x compatibility and update usages
- **test**: Add readAllSourcesFromFilesystem param to resolveSource in all test helpers and test cases

### ⬆️ Dependencies & Build
- **deps**: Update Dart SDK and multiple dependencies to latest versions across all packages
- **deps**: Update dependencies and lockfiles for publish-kit and example to latest compatible versions
- **macos**: Update macOS deployment target to 10.15 and integrate CocoaPods in Xcode project
- **macos/Podfile.lock**: Add Podfile.lock with FlutterMacOS and sqflite_darwin dependencies for macOS example

### 🧹 Maintenance
- **pubspec**: Add publish_to: none to prevent accidental publishing of packages
- **ci**: Remove --fatal-infos flag from analyzer step in CI workflow
- **ci**: Remove 'develop' branch restriction from push trigger in GitHub Actions workflow
- **lints**: Comment out prefer_single_quotes, sort_pub_dependencies, unnecessary_brace_in_string_interps
- **deps**: Remove unused collection and analyzer imports

### 📝 Documentation
- **README**: Add build_runner example command to example/README.md
- **pubspec**: Add publish_to: none to prevent accidental publishing

### 🛠️ Workflow
- Update deploy-website.yml
