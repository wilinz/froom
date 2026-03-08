# Changelog

## 5.0.0

### ⬆️ Breaking Changes & Dependencies
- **analyzer**: Bumped to version 9.0.0 (breaking major version bump) with comprehensive dependency updates
- **froom_generator**: Updated fakes for analyzer 9.x API compatibility (`isDeprecatedWithKind`)
- **Dart SDK**: Minimum requirement raised to `>=3.9.0`
- **build**: Updated to 4.0.4
- **build_runner**: Updated to 2.11.1
- **source_gen**: Updated to 4.2.0
- **mockito**: Updated to 5.6.3

### 🐛 Bug Fixes
- **query_method_writer**: Accept backtick-quoted table names for `queryableName` ([#161](https://github.com/wilinz/froom/pull/161))

## 4.0.0

### ⬆️ Breaking Changes & Dependencies
- **froom_generator**: Migrated from analyzer element2 API to element API for improved compatibility
- **analyzer**: Bumped to version 8.1.1 with comprehensive dependency updates
- **build & source_gen**: Updated to latest versions across froom and froom_common packages

### ✨ Features
- **query_adapter**: Added custom SqlParseException for better error handling of invalid SQL statements

## 3.0.2

### 🔧 Improvements
- **dependencies**: Remove unnecessary Flutter and flutter_test dependencies from pubspec.yaml

## 3.0.1

### 🔧 Improvements
- **platform_detection**: Replace kIsWeb with custom _kIsWeb for better platform detection in sqflite database factory
- **code_quality**: Add braces to single-line if statements for improved readability

### 📝 Documentation
- **pubspec**: Add supported platforms section (Android, iOS, Linux, macOS, Windows)
- **dependencies**: Remove unnecessary Flutter and flutter_test dependencies from pubspec.yaml

### 🛠 Maintenance  
- **ci**: Disable fatal warnings in Dart analyze steps for froom_annotation and froom_generator
- **formatting**: Format removePublishToField parameters for improved readability
- **ci**: Remove --fatal-infos/warnings from analyze, fix publish_to removal signature

## 3.0.0

### ⬆️ Dependencies & Breaking Changes
- **source_gen**: Upgrade to source_gen 3.x.x with modern TypeChecker API migration
- **analyzer**: Migrate to analyzer 7.x and element2 API throughout codebase
- **deps**: Update Dart SDK and multiple dependencies to latest versions across all packages
- **type_utils**: Use TypeChecker.typeNamed instead of deprecated fromRuntime for improved compatibility

### 🔧 Improvements
- **dart_type_extension**: Add getDisplayStringCompat for analyzer 7.x compatibility
- **macos**: Update macOS deployment target to 10.15 and integrate CocoaPods support

### 📝 Documentation
- **README**: Add build_runner example command to example/README.md

## 2.0.4

### Changes
* Update README.md

## 2.0.3

### Fix

* Fix [froom_common](froom_common) meta version

### Changes

* Update readme.md

## 2.0.2

### Changes

* add publish-kit

## 2.0.0

### Changes

* Initial release of froom_common package