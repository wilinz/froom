# Changelog

## [Unreleased]

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
