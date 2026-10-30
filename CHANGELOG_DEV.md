# Changelog

## [Unreleased]

### 🔄 Breaking Changes
- **analyzer**: Bumped from `^10.0.0` to `^11.0.0` in `froom_generator` (Flutter 3.47.x / Dart 3.13.x)
- **froom_generator**: Dart SDK lower bound raised from `>=3.0.0` to `>=3.9.0`, as required by analyzer 11
- **example**: Removed the explicit `analyzer` dev dependency

### ✨ Features
- **upsert**: Add `@upsert` / `@Upsert` annotation mirroring Room's `@Upsert` (#2)
  - `froom_annotation`: `Upsert` with optional `entity` target for partial entities
  - `froom_common`: `UpsertionAdapter` inserts first and updates by primary key on unique constraint conflicts (checked by message and result codes `1555` / `2067`, like Room); every upsert runs in a transaction
  - `froom_generator`: `UpsertionMethodProcessor`, `PartialEntityProcessor`, `UpsertionMethodWriter`; multiple parameters are upserted in one transaction, return types follow Room (`void` for multiple parameters, `int` for a single item, `List<int>` for a single list)
  - Partial entities are validated like Room: matching column names and types, primary key columns unless auto generated, and all non-nullable columns; fields of non-nullable columns must be non-nullable
  - Partial entities use exactly the type converters of their target entity columns (DAO level converters unknown to the entity are ignored); fields must have the same Dart type as their column and must not declare another converter; adapters of partial entities are named after their target entity, so one partial entity class can target several entities
  - Nullable parameters and list items are rejected, as are partial entities mapping two fields to the same column
  - Virtual tables (FTS) don't enforce unique primary keys, so their entities are updated by primary key first and only inserted when no row got updated, instead of inserting duplicate rows
  - Unlike Room, a conflict that leaves no row to update by primary key (e.g. on another unique index) rethrows the original exception instead of silently dropping the item
  - Performance: `void` upserts use one batch of native `INSERT ... ON CONFLICT(pk) DO UPDATE` statements when SQLite >= 3.24.0 and the table is not virtual (FTS doesn't support UPSERT), checked once per database and table; methods returning ids keep the Room approach, as native upserts can't tell inserted from updated rows. 10k existing rows with FFI: 180–506 ms → 43–56 ms
- **database**: Add `FroomDatabase.clearAllTables()`, deleting all rows of all entity tables in one transaction with deferred foreign keys and resetting `sqlite_sequence`; the generated database provides `entityTableNames` (#163, upstream floor#166, floor#834)
- **queryable_processor**: Assign fields not initialized by the constructor via setters (`Entity()..field = value`) when mapping rows (#164, upstream floor#175, floor#839)
- **column_info**: Add `ColumnInfo.defaultValue`, added as `DEFAULT` to the column definition; text values are quoted (and escaped) unless SQLite constants or parenthesized expressions, `NULL` for non-nullable fields is an error, and partial entities may omit columns with default values (#165, upstream floor#256, floor#611, floor#849)
- **migrations**: Add `fallbackToDestructiveMigration()` to the builder; without a migration path on upgrade, and on downgrade, `MigrationAdapter.dropAllTables` drops all views and tables (virtual tables first) with deferred foreign keys and the schema gets recreated; `MigrationAdapter.hasMigrationPath` and `Callback.onDestructiveMigration` added, the generated `open` creates the schema in a local `createSchema` (#167, upstream floor#356, floor#566, floor#614, floor#853)
- **queryable_processor**: Allow mixins on entities and views (removed `prohibitedMixinUsage`); their fields are columns like fields of superclasses (#171, upstream floor#495)
- **index**: Add `Index.where`, appended as `WHERE` clause to `CREATE INDEX` for partial indices (#172, upstream floor#497)
- **type_converter**: `getClosestOrNullForNullable` falls back to the converter of the non-nullable type for nullable types; encoding, decoding, query parameters and single query results bypass it for `null` (with an explicit type argument for `query<T?>`) (#174, upstream floor#508)
- **entity_processor**: Generate `Entity.insertionValueMapping`, mapping `0` of a non-nullable auto generated `int` primary key to `NULL`, used by insertion and upsertion adapters (#177, upstream floor#527, floor#571)
- **type_converter**: Recognize converters by any `TypeConverter` supertype of froom_annotation (`typeConverterSupertype`), not only the direct superclass (#182, upstream floor#670)

### 🐛 Bug Fixes
- **insertion_method_processor**: Reject `Future<List<void>>` return types, which generated non-compiling code
- **generator**: Emit `// ignore_for_file: type=lint` (plus `unused_element` with type converters) at the top of generated code (ee30abd, #162)
- **queryable_processor**: Prefer the unnamed constructor (named `new`) over named ones declared before it, and call named constructors with their name instead of the unnamed syntax (#166, upstream floor#275, floor#644)
- **query_method_writer, transaction_method_writer**: Keep optional positional and named parameters with their default values in generated overrides and pass named arguments by name (`MethodParametersExtension.addParametersOf`, `getArgumentsOf`) (#168, upstream floor#371)
- **dao_writer**: Pass the change listener to `QueryAdapter` whenever the database has streams, so changes of `@Query` statements notify streams of other DAOs (#169, upstream floor#383, floor#603)
- **database_writer**: Drop and recreate the declared views after running migrations, so changed view queries take effect (#170, upstream floor#400)
- **query_processor, query_method_writer**: Allow nullable scalar query parameters (nullable lists are still rejected), bound as `NULL`; nullable `bool`/enum parameters and nullable parameters with a converter of the non-nullable type map `null` to `NULL`; `QueryAdapter` takes `List<Object?>` arguments (#173, upstream floor#507)
- **dao_processor**: Collect DAO methods from the closest to the most distant supertype (mixins in reverse order) and keep only the most specific declaration of overridden methods (#175, upstream floor#515)
- **queryable_processor**: Collect fields from the closest to the most distant supertype and keep only the most specific declaration of overridden fields, respecting `@ignore` on overrides; the traversal is shared with the DAO processor (`InterfaceElementExtension.supertypesClosestFirst`) (#176, upstream floor#522, floor#798, floor#799)
- **database_writer, migration_adapter**: Don't enable foreign keys in `onConfigure` when an upgrade is pending (`MigrationAdapter.isUpgradePending`), but after the migrations in `onOpen` following a `PRAGMA foreign_key_check` (`enableForeignKeysAfterMigrations`) (#178, upstream floor#534)
- **query_processor, query_method_writer**: Accept list parameters as the only content of parentheses (row values), not only after `IN`, and bind `List<Object>` items as they are (#180, upstream floor#617)
- **query_method_processor**: Throw `unresolvedReturnType` for `InvalidType` return types before the nullability check, which misleadingly asked for a nullable type (#183, upstream floor#744, floor#837)
- **query_adapter**: Streams skip results of re-queries finishing after they got closed, ignore `database_closed` errors and forward other errors to listeners instead of leaving them unhandled; both stream methods share `_createStream` (#184, upstream floor#745)

### 🧹 Maintenance
- **queryable_processor**: Replace removed `FieldElement.isSynthetic` with `isOriginDeclaration || isOriginDeclaringFormalParameter`
- **queryable_processor**: Move value mapping generation from `EntityProcessor` into `QueryableProcessor` to reuse it for partial entities
- **dao_writer**: Share the field and initializer generation of insertion, update, upsertion and deletion adapters
- **change_method_processor_helper**: Share the return type checks (`returnsFuture`, `returnsList`, `returnsVoid`, `returnsInt`, `returnsIntList`, `flattenedReturnType`) of the insertion, update, upsertion and deletion processors
- **fakes**: Add `primaryConstructor` stub to `FakeClassElement` for analyzer 11.x compatibility
- **docs**: Document `@upsert` in DAOs, Getting Started, Database Views, Migration from Floor and READMEs

### 📝 All Commits Since v6.0.0
- ee30abd: 🐛 fix(froom_generator): suppress lints in generated code with ignore_for_file: type=lint
- a4a1768: ⬆️ chore(froom_generator,example): bump analyzer to ^11.0.0 for Flutter 3.47

### 📝 Documentation
- **getting-started**: Document absolute database paths for `databaseBuilder()`, covered by a test (#179, upstream floor#588, floor#803)
- **getting-started, READMEs**: Import the entity in the DAO example (#181, upstream floor#645)

## [6.0.0] - 2026-03-08

### 🔄 Breaking Changes
- **analyzer**: Bumped from `9.0.0` to `^10.0.0` in `froom_generator` and `example`
- **ci**: Updated CI Docker image from `dart:3.7.2` to `dart:3.9.0`

### ⬆️ Dependencies
- **analyzer**: `9.0.0` → `^10.0.0`

### 🧹 Maintenance
- **fakes**: Add missing `FakeFieldElement` stubs for analyzer 10.x API compatibility:
  - `declaringFormalParameter`
  - `isOriginDeclaration`
  - `isOriginDeclaringFormalParameter`
  - `isOriginEnumValues`
  - `isOriginExtensionTypeRecoveryRepresentation`
  - `isOriginGetterSetter`

### 📝 All Commits
- `.github/workflows/ci.yml`: dart:3.7.2 → dart:3.9.0
- `froom_generator/pubspec.yaml`: analyzer 9.0.0 → ^10.0.0
- `example/pubspec.yaml`: analyzer 9.0.0 → ^10.0.0
- `froom_generator/test/fakes.dart`: Add FakeFieldElement stubs for analyzer 10.x

## [5.0.0] - 2026-03-08

### 🔄 Breaking Changes
- **analyzer**: Bumped from `^8.1.1` to `9.0.0` in `froom_generator` and `example`
- **Dart SDK**: Minimum requirement raised from `>=3.7.0` to `>=3.9.0` in `froom_generator`

### ⬆️ Dependencies
- **analyzer**: `8.1.1` → `9.0.0`
- **_fe_analyzer_shared**: `88.0.0` → `92.0.0`
- **build**: `4.0.0` → `4.0.4`
- **build_runner**: `2.8.0` → `2.11.1`
- **build_test**: `3.4.0` → `3.5.7`
- **build_modules**: `5.0.17` → `5.1.8`
- **build_web_compilers**: `4.2.3` → `4.4.15`
- **source_gen**: `4.0.1` → `4.2.0`
- **dart_style**: `3.1.2` → `3.1.3`
- **mockito**: `5.5.1` → `5.6.3`
- **test**: `1.26.3` → `1.30.0`

### ✨ Features / Bug Fixes
- **query_method_writer**: Accept backtick-quoted table names for `queryableName` (135d615, PR #161 by [@Huluk](https://github.com/Huluk))

### 🧹 Maintenance
- **fakes**: Add `isDeprecatedWithKind` stub to `FakeClassElement` and `FakeFieldElement` for analyzer 9.x compatibility

### 📝 All Commits Since v4.0.0
- 95db6b0: Merge pull request #161 from Huluk/backticks
- 135d615: Accept backtick-quoted table names for queryableName

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
