# Changelog

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