# Changelog

## 8.0.0

### ⬆️ Breaking Changes & Dependencies
- **sqlite3**: Upgraded to `sqflite_common_ffi` 2.4, `sqflite_common_ffi_web` 1.2 and `sqlite3` 3, which bundle SQLite with the app by hooks and choose the SQLite library per platform by the `hooks` of the `pubspec.yaml` (bundled, system or encrypted builds) instead of `sqlite3_flutter_libs`. The bundled builds don't support FTS3 and FTS4, which `@Fts3` and `@Fts4` entities require, see [Platform Support](https://wilinz.github.io/froom/platform-support/)
- **sqlite3**: sqlite3 bundles SQLite on Android and iOS too, even for apps only using the sqflite plugin there, which can avoid it with `source: system` for these platforms, see [Platform Support](https://wilinz.github.io/froom/platform-support/#choosing-the-sqlite-library)
- **sdk**: Minimum Dart SDK of `froom`, `froom_ffi` and the example raised to `>=3.12.0`, as required by the sqflite packages
- **froom_generator**: Minimum Dart SDK raised to `>=3.10.0`, as required by the versions of dart_style supporting analyzer 11
- **sqlparser**: Upgraded to `^0.45.1` in `froom_common` and `froom_generator`, raising the minimum Dart SDK of `froom_common` to `>=3.10.0`
- **froom_generator**: Supports analyzer `>=11.0.0 <15.0.0` and build `>=4.0.0 <6.0.0`, so it works with the latest build_runner, freezed and json_serializable

### ✨ Features
- **fts**: Add `@fts5`/`@Fts5()` entities stored in FTS5 tables, which the SQLite builds bundled by sqlite3 support, with `tokenizer`, `tokenizerArgs`, `prefixes` and `notIndexed`; their primary key is the `rowid`, which queries have to select explicitly, as the code generation checks
- **froom_ffi**: Databases generated with `froom_ffi` compile, as `getDatabasePath()` of their builders moved to `froom_common`
- **database**: Opening a database fails with a `MissingSqliteModuleException` explaining how to fix it when the SQLite library lacks a module like FTS4
- **encryption**: Encrypt databases with `password()` of their builder, using encrypted builds of SQLite like SQLite3MultipleCiphers or SQLCipher; opening fails with a `DatabaseEncryptionException` for wrong passwords, unencrypted databases and SQLite builds without encryption, and with an `ArgumentError` for empty passwords, which would store the database unencrypted
- **database**: Choose the sqflite `DatabaseFactory` of a database with `databaseFactory()` of its builder, e.g. the FFI one on Android and iOS instead of the sqflite plugin
- **database**: Opening a database on Android and iOS without the sqflite plugin or another database factory fails with a message explaining how to fix it instead of `databaseFactory not initialized`
- **database**: Import the sqflite API of the generated code with `import 'package:froom/sqflite.dart' as sqflite;` instead of depending on `sqflite`
- **web**: Support Flutter for the web, storing databases in IndexedDB with sqflite_common_ffi_web, compiled to JavaScript or WebAssembly; the default database factory is chosen by conditional imports instead of `dart:io`, so `froom` compiles for the web
- **migrations**: Add automatic migrations like Room's `@AutoMigration`, generated from the schemas exported to `froom_schemas` (with automatic migrations or `@Database(exportSchema: true)`), including `@RenameTable`, `@RenameColumn`, `@DeleteTable` and `@DeleteColumn` specs, `AutoMigrationSpec.onPostMigrate` and `@providedAutoMigrationSpec`

## 7.0.0

### ⬆️ Breaking Changes & Dependencies
- **migrations**: Migrations run with foreign keys disabled, so foreign key actions like `ON DELETE CASCADE` don't run during migrations; opening the database fails if the migrations add foreign key violations ([#178](https://github.com/wilinz/froom/issues/178))
- **migrations**: Like in Room, migrations have to lead from the database version to the current one without gaps, otherwise opening the database fails (or recreates it with `fallbackToDestructiveMigration()`); of several migrations starting at the same version, only the one reaching the highest version runs
- **analyzer**: Bumped to `^11.0.0` for Flutter 3.47 / Dart 3.13
- **froom_generator**: Minimum Dart SDK raised to `>=3.9.0`

### ✨ Features
- **upsert**: Add `@upsert` / `@Upsert` annotation mirroring Room's `@Upsert` ([#2](https://github.com/wilinz/froom/issues/2))
  - Inserts entities and updates them instead on primary key or unique constraint conflicts, without deleting the existing row; conflicts on other unique indices are rethrown
  - Supports multiple parameters, upserted in a single transaction
  - Supports partial entities via `@Upsert(entity: X)`, only inserting or updating the columns they contain
  - Returns the row ids of inserted entities or `-1` for updated ones
  - Upserts returning `void` use batched native `INSERT ... ON CONFLICT DO UPDATE` on SQLite 3.24.0 and above
- **database**: Add `clearAllTables()` to delete all rows of all entity tables, like Room ([#163](https://github.com/wilinz/froom/issues/163))
- **queryable**: Fields not initialized by the constructor are assigned via their setters when reading entities and views ([#164](https://github.com/wilinz/froom/issues/164))
- **column_info**: Add `@ColumnInfo(defaultValue: ...)` for SQL default values of columns, like Room ([#165](https://github.com/wilinz/froom/issues/165))
- **migrations**: Add `fallbackToDestructiveMigration()` to the database builder and `Callback.onDestructiveMigration`, recreating the database when there is no migration, like Room ([#167](https://github.com/wilinz/froom/issues/167))
- **queryable**: Entities and views can use mixins, whose fields become columns ([#171](https://github.com/wilinz/froom/issues/171))
- **index**: Add `Index.where` for partial indices ([#172](https://github.com/wilinz/froom/issues/172))
- **type_converter**: Converters of non-nullable types also convert nullable fields, parameters and query results, keeping `null` as `NULL` ([#174](https://github.com/wilinz/froom/issues/174))
- **entity**: Like Room, `0` of a non-nullable auto generated `int` primary key is treated as unset when inserting ([#177](https://github.com/wilinz/froom/issues/177))
- **type_converter**: Type converters may implement `TypeConverter` or extend it indirectly ([#182](https://github.com/wilinz/froom/issues/182))
- **index**: Support indices on expressions like `lower(email)` ([#194](https://github.com/wilinz/froom/issues/194))

### 🐛 Bug Fixes
- **froom_generator**: Generated code suppresses lints with `// ignore_for_file: type=lint` ([#162](https://github.com/wilinz/froom/issues/162))
- **queryable**: Use the unnamed constructor instead of the first declared one and call named constructors by their name ([#166](https://github.com/wilinz/froom/issues/166))
- **dao**: Query and transaction methods support optional positional and named parameters with default values ([#168](https://github.com/wilinz/froom/issues/168))
- **dao**: `INSERT`, `UPDATE` and `DELETE` statements of `@Query` methods update streams declared in other DAOs too ([#169](https://github.com/wilinz/froom/issues/169))
- **views**: Database views are recreated with their current queries after migrations ([#170](https://github.com/wilinz/froom/issues/170))
- **query**: Query method parameters can be nullable and are bound as `NULL` ([#173](https://github.com/wilinz/froom/issues/173))
- **dao**: Methods overriding methods of DAO supertypes are generated only once ([#175](https://github.com/wilinz/froom/issues/175))
- **entity**: Fields overriding fields of superclasses or interfaces are columns only once ([#176](https://github.com/wilinz/froom/issues/176))
- **migrations**: Migrations run with foreign keys disabled and are checked for violations afterwards, e.g. for recreating tables ([#178](https://github.com/wilinz/froom/issues/178))
- **query**: List parameters can be used as row values like `(a, b) > (:list)`, including `List<Object>` ([#180](https://github.com/wilinz/froom/issues/180))
- **query**: Report unresolved return types of query methods, e.g. due to missing imports, instead of asking for a nullable return type ([#183](https://github.com/wilinz/froom/issues/183))
- **streams**: Closing the database while a stream re-queries no longer throws unhandled exceptions ([#184](https://github.com/wilinz/froom/issues/184))
- **dao**: `@transaction` on query and change methods no longer generates them twice ([#185](https://github.com/wilinz/froom/issues/185))
- **index**: Indices are created with `IF NOT EXISTS` like tables ([#187](https://github.com/wilinz/froom/issues/187))
- **transaction**: `@transaction` methods with nullable return values generate compiling code ([#188](https://github.com/wilinz/froom/issues/188))
- **entity**: Report columns of `@Entity(primaryKeys: ...)` that don't exist instead of ignoring them ([#189](https://github.com/wilinz/froom/issues/189))
- **query**: `double` values are read correctly when SQLite returns integers, e.g. for `COALESCE(SUM(x), 0)` ([#191](https://github.com/wilinz/froom/issues/191))
- **query**: Queries which aren't valid SQL fail the code generation instead of only at runtime ([#192](https://github.com/wilinz/froom/issues/192))
- **streams**: Streams of queries with double quoted or bracketed table names update ([#193](https://github.com/wilinz/froom/issues/193))

### 📝 Documentation
- Document passing an absolute path to `databaseBuilder()` for a custom database location ([#179](https://github.com/wilinz/froom/issues/179))
- Import the entity in the DAO example of the getting started guide ([#181](https://github.com/wilinz/froom/issues/181))
- Document full text search with `@Fts3`/`@Fts4` entities ([#190](https://github.com/wilinz/froom/issues/190))
- Fix the broken link to the integration tests and the syntax of the testing example ([#195](https://github.com/wilinz/froom/issues/195))

## 6.0.0

### ⬆️ Breaking Changes & Dependencies
- **analyzer**: Bumped to `^10.0.0`
- **ci**: Updated CI Docker image from `dart:3.7.2` to `dart:3.9.0`

### 🛠 Maintenance
- **fakes**: Add missing `FieldElement` API stubs for analyzer 10.x compatibility (`declaringFormalParameter`, `isOriginDeclaration`, `isOriginDeclaringFormalParameter`, `isOriginEnumValues`, `isOriginExtensionTypeRecoveryRepresentation`, `isOriginGetterSetter`)

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