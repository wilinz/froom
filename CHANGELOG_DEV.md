# Changelog

## [Unreleased]

### ✨ Features
- **fts**: `Fts5` annotation (`FtsTokenizer.ascii` and `trigram` added) and value object; `Entity.getCreateTableStatement()` declares FTS5 columns without types and constraints, omitting the `rowid` primary key and appending `UNINDEXED`; `EntityProcessor` requires a single integer `rowid` primary key, another column, a single FTS annotation, prefixes from 1 to 999, no columns named `rowid`, `rank` or like the table (ignoring case), no FTS3/FTS4 tokenizers, existing `notIndexed` columns (ignoring case) and a primary key column named exactly `rowid`, the name of the row id in results, and quotes tokenizer arguments which aren't words and no indices, foreign keys or `WITHOUT ROWID`; `QueryMethodProcessor` requires the result columns of queries of FTS5 entities, resolved by sqlparser with the FTS5 extension and the tables and views of the database, to include one named exactly `rowid` (any case of `rowid`, `oid` or `_rowid_` of the table, or an alias), also of subqueries, CTEs, compound selects and table-valued functions, unless they reference unknown tables; recreated FTS5 tables copy their row id only with their `rowid` column; `Fts.hashCode` hashes the options instead of their tear-off; `Fts3` and `Fts4` reject the FTS5 tokenizers `ascii` and `trigram`
- **database_factory_extension**: `DatabaseFactoryExtension.getDatabasePath()` used by generated builders moved from `froom` to `froom_common`, so `froom_ffi` provides it as well, which has tests of a generated database now
- **exceptions**: `MissingSqliteModuleException` and `DatabaseEncryptionException` extend `DatabaseException`, delegating its result code to their cause
- **sqlite_module_hint**: `explainMissingSqliteModules()` in `froom_common` wraps opening the database in the generated `open()` and turns `no such module` errors of SQLite, only `DatabaseException`s, into a `MissingSqliteModuleException`
- **database_builder_writer**: Generate `databaseFactory(sqflite.DatabaseFactory)` in builders and their contracts; `build()` opens the database with it or the default `sqfliteDatabaseFactory`, which `open()` of the database takes as its first parameter
- **froom**: `sqfliteDatabaseFactory` is exported by conditional imports instead of detecting the web with `_kIsWeb`: on Android and iOS the global `databaseFactory` of sqflite, which the sqflite plugin registers, failing with an explanation without it, `databaseFactoryFfi` on the other native platforms and `databaseFactoryFfiWeb` on the web; `package:froom/sqflite.dart` and `package:froom_ffi/sqflite.dart` export the sqflite API for the `sqflite` import prefix of the generated code; `sqflite_common` is a direct dependency and the unused `sqlparser` dependency is removed
- **dependencies**: `sqflite_common` ^2.5.13, `sqflite_common_ffi` ^2.4.5 (`sqlite3` 3 with hooks), `sqflite_common_ffi_web` ^1.2.0 and `sqflite` ^2.4.5 in the example; Dart SDK `>=3.12.0` for `froom`, `froom_ffi` and the example; `>=3.10.0` for `froom_generator`, as dart_style supports analyzer 11 from 3.1.6, which requires it, with the `dart:3.10.0` image in CI, and for `froom_common`, as required by `sqlparser` ^0.45.1, whose `SqlEngine.parse()` takes a `ParserEntrypoint`; `path` only in the tests of `froom` and no longer in `froom_ffi`; the integration tests of `froom_common` use the system SQLite (`hooks.user_defines.sqlite3.source: system`), as the bundled one lacks FTS3 and FTS4
- **encryption**: `EncryptionAdapter.setPassword()` in `froom_common` rejects empty passwords, which SQLite3MultipleCiphers ignores, runs `PRAGMA key`, checks `PRAGMA cipher` (SQLite3MultipleCiphers) or `PRAGMA cipher_version` (SQLCipher) and reads the schema to detect wrong passwords; builders get `password()`, and `open()` takes the password after the path and sets it first in `onConfigure`, except for in-memory databases; `EncryptionAdapter.checkPassword()` compares the password with the one the open single instance, which sqflite returns without `onConfigure`, was configured with (an `Expando` of the database); `password()` of builders rejects empty passwords with `EncryptionAdapter.validatePassword()`; databases opened without password fail with a `DatabaseEncryptionException` if SQLite can't read them; builds without encryption on the web fail like native ones; the tests of `froom` use `sqlite3mc`
- **web**: Browser tests of a generated database in `froom/test/web` (`dart test -p chrome`, with dart2js and dart2wasm in the new `froom-web` CI job), using the `sqlite3.wasm` set up by `dart run sqflite_common_ffi_web:setup --dir test/web`; the example contains the web setup; the integration tests of `froom_common` use `winsqlite3` on Windows
- **froom_ffi**: Rename the library to `froom_ffi.dart`, keeping the misspelled `froon_ffi.dart` as a deprecated export
- **auto_migration**: Add `AutoMigration`, `RenameTable`, `RenameColumn`, `DeleteTable`, `DeleteColumn` and `providedAutoMigrationSpec` annotations, `Database.autoMigrations` and `Database.exportSchema` (exported by default only with automatic migrations), and `AutoMigrationSpec` in `froom_common`
- **schema**: Export the `DatabaseSchema` of the current version to `<schema_location>/<library path>/<database>/<version>.json` (`FileSchemaStore`, builder option `schema_location`, default `froom_schemas`); entity and index statements use the `${TABLE_NAME}` placeholder like Room
- **auto_migration_processor, schema_differ**: Port Room's `SchemaDiffer`, detecting added, renamed and deleted tables, added columns and complex changes (primary key, foreign keys, indices, `WITHOUT ROWID`, FTS, changed, renamed and deleted columns, foreign keys to renamed tables), requiring specs for deleted or renamed tables and columns and default values for new `NOT NULL` columns
- **auto_migration_writer**: Generate migrations dropping views, deleting, renaming and adding tables, adding columns, recreating tables with complex changes (FTS tables last) and recreating views, calling `onPostMigrate` of the spec; builder migrations replace automatic ones of the same versions, and builders of databases with provided specs get `addAutoMigrationSpecs()`
- **froom_generator**: `path` is a regular dependency

## [7.0.0] - 2026-10-30

### 🔄 Breaking Changes
- **analyzer**: Bumped from `^10.0.0` to `^11.0.0` in `froom_generator` (Flutter 3.47.x / Dart 3.13.x)
- **froom_generator**: Dart SDK lower bound raised from `>=3.0.0` to `>=3.9.0`, as required by analyzer 11
- **example**: Removed the explicit `analyzer` dev dependency
- **migrations**: Migrations run with foreign keys disabled, so foreign key actions don't run during them, and fail when adding foreign key violations (#178)
- **migration_adapter**: Migrations have to be consecutive from the database version to the current one; of several migrations starting at the same version, only the one reaching the highest version runs

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
- **database**: Add `FroomDatabase.clearAllTables()`, deleting all rows of all entity tables in one transaction with deferred foreign keys and resetting `sqlite_sequence`; the generated database provides `entityTableNames`; adapters and `clearAllTables` notify streams via `ChangeListenerExtension.notifyChange`, which ignores changes after closing the database (#163, upstream floor#166, floor#834)
- **queryable_processor**: Assign fields not initialized by the constructor via setters (`Entity()..field = value`) when mapping rows (#164, upstream floor#175, floor#839)
- **column_info**: Add `ColumnInfo.defaultValue`, added as `DEFAULT` to the column definition; text values are quoted (and escaped) unless SQLite constants, parenthesized expressions or already SQL string literals, `NULL` for non-nullable fields is an error, and partial entities may omit columns with default values (#165, upstream floor#256, floor#611, floor#849)
- **migrations**: Add `fallbackToDestructiveMigration()` to the builder; without a migration path on upgrade, and on downgrade, `MigrationAdapter.dropAllTables` drops all views and tables (virtual tables first) with deferred foreign keys and the schema gets recreated; `MigrationAdapter.hasMigrationPath` and `Callback.onDestructiveMigration` added, the generated `open` creates the schema in a local `createSchema` (#167, upstream floor#356, floor#566, floor#614, floor#853)
- **queryable_processor**: Allow mixins on entities and views (removed `prohibitedMixinUsage`); their fields are columns like fields of superclasses (#171, upstream floor#495)
- **index**: Add `Index.where`, appended as `WHERE` clause to `CREATE INDEX` for partial indices (#172, upstream floor#497)
- **type_converter**: `getClosestOrNullForNullable` falls back to the converter of the non-nullable type for nullable types; encoding, decoding, query parameters and single query results bypass it for `null` (with an explicit type argument for `query<T?>`) (#174, upstream floor#508)
- **entity_processor**: Generate `Entity.insertionValueMapping`, mapping `0` of a non-nullable auto generated `int` primary key to `NULL`, used by insertion and upsertion adapters (#177, upstream floor#527, floor#571)
- **type_converter**: Recognize converters by any `TypeConverter` supertype of froom_annotation (`typeConverterSupertype`), not only the direct superclass (#182, upstream floor#670)
- **entity_processor**: Index values not matching a column are used as expressions, unescaped in `CREATE INDEX` and sanitized in generated index names (#194, upstream floor#835)

### 🐛 Bug Fixes
- **insertion_method_processor**: Reject `Future<List<void>>` return types, which generated non-compiling code
- **generator**: Emit `// ignore_for_file: type=lint` (plus `unused_element` with type converters) at the top of generated code (ee30abd, #162)
- **queryable_processor**: Prefer the unnamed constructor (named `new`) over named ones declared before it, and call named constructors with their name instead of the unnamed syntax (#166, upstream floor#275, floor#644)
- **query_method_writer, transaction_method_writer**: Keep optional positional and named parameters with their default values (as literals for constant `bool`, `int`, `double` and `String` values and as `Enum.value` for enum values, which may refer to constants of other libraries) in generated overrides and pass named arguments by name (`MethodParametersExtension.addParametersOf`, `getArgumentsOf`) (#168, upstream floor#371)
- **dao_writer**: Pass the change listener to `QueryAdapter` whenever the database has streams, so changes of `@Query` statements notify streams of other DAOs (#169, upstream floor#383, floor#603)
- **database_writer**: Drop and recreate the declared views after running migrations, so changed view queries take effect (#170, upstream floor#400)
- **query_processor, query_method_writer**: Allow nullable scalar query parameters (nullable lists are still rejected), bound as `NULL`; nullable `bool`/enum parameters and nullable parameters with a converter of the non-nullable type map `null` to `NULL`; `QueryAdapter` takes `List<Object?>` arguments (#173, upstream floor#507)
- **dao_processor**: Collect DAO methods from the closest to the most distant supertype (mixins in reverse order) and keep only the most specific declaration of overridden methods, falling back to the closest annotated one for abstract redeclarations without annotation, unless a concrete one comes first, and rejecting such redeclarations with another signature (#175, upstream floor#515)
- **queryable_processor**: Collect fields from the closest to the most distant supertype and keep only the most specific declaration of overridden fields, respecting `@ignore` on overrides; the traversal is shared with the DAO processor (`InterfaceElementExtension.supertypesClosestFirst`) (#176, upstream floor#522, floor#798, floor#799)
- **database_writer, migration_adapter**: Don't enable foreign keys in `onConfigure` when an upgrade is pending (`MigrationAdapter.isUpgradePending`), but after the migrations in `onOpen`; `MigrationAdapter.checkForeignKeys` runs `PRAGMA foreign_key_check` at the end of `onUpgrade` and compares the violations per table with `getForeignKeyViolations` from before the migrations, so migrations adding violations get rolled back together with the database version (#178, upstream floor#534)
- **query_processor, query_method_writer**: Accept list parameters as the only content of parentheses (row values, but not function calls), not only after `IN`, and bind `List<Object>` items as they are (#180, upstream floor#617)
- **query_method_processor**: Throw `unresolvedReturnType` for `InvalidType` return types before the nullability check, which misleadingly asked for a nullable type (#183, upstream floor#744, floor#837)
- **query_adapter**: Streams skip results of re-queries finishing after they got closed, ignore `database_closed` errors and forward other errors to listeners instead of leaving them unhandled; both stream methods share `_createStream` (#184, upstream floor#745)
- **dao_processor**: Don't treat query, insertion, update, upsertion and deletion methods annotated with `@transaction` as transaction methods, which generated them twice (#185, upstream floor#748)
- **example**: Create tasks with the status `open`, so they are shown by the default filter and cycle through all statuses (#186, upstream floor#763)
- **index**: Generate `CREATE INDEX IF NOT EXISTS`, so creating the schema again, e.g. for new tables in migrations, doesn't fail (#187, upstream floor#775, floor#788)
- **transaction_method_writer**: Keep the nullability of the type argument of `transaction<T>`, e.g. `transaction<Person?>` for `Future<Person?>` (#188, upstream floor#783)
- **entity_processor**: Throw `noMatchingPrimaryKeyColumn` for compound primary key columns without a matching field, which were silently dropped from the primary key (#189, upstream floor#789)
- **cast**: Read `double` values as `(value as num).toDouble()` instead of `value as double`, which failed for integers SQLite returns e.g. for whole number expressions (#191, upstream floor#802, floor#814, floor#816, floor#828)
- **query_method_processor**: Parse queries with `sqlparser` (new dependency of froom_generator, as of froom_common) and throw `invalidQuery` for invalid statements, which the runtime rejects as well; invalid SQL of test fixtures fixed (#192, upstream floor#820)
- **query_method_writer**: Parse the streamed table name from the raw query, supporting double quotes, brackets and backticks as well as any whitespace after `FROM` (#193, upstream floor#833)
- **migration_adapter**: `runMigrations` and `hasMigrationPath` search consecutive migrations from the start to the end version, preferring the highest end version and backtracking, instead of running all migrations starting at or after the start version

### 🧹 Maintenance
- **queryable_processor**: Replace removed `FieldElement.isSynthetic` with `isOriginDeclaration || isOriginDeclaringFormalParameter`
- **queryable_processor**: Move value mapping generation from `EntityProcessor` into `QueryableProcessor` to reuse it for partial entities
- **dao_writer**: Share the field and initializer generation of insertion, update, upsertion and deletion adapters
- **change_method_processor_helper**: Share the return type checks (`returnsFuture`, `returnsList`, `returnsVoid`, `returnsInt`, `returnsIntList`, `flattenedReturnType`) of the insertion, update, upsertion and deletion processors
- **fakes**: Add `primaryConstructor` stub to `FakeClassElement` for analyzer 11.x compatibility
- **docs**: Document `@upsert` in DAOs, Getting Started, Database Views, Migration from Floor and READMEs

### 📝 All Commits Since v6.0.0
- 3e89556: ⬆️ chore(pubspec.lock): bump dependency versions, update SHAs, and raise Dart SDK min to >=3.9.0
- a4a1768: ⬆️ chore(froom_generator,example): bump analyzer to ^11.0.0 for Flutter 3.47, replace removed isSynthetic, add primaryConstructor fake, raise generator SDK to >=3.9.0
- ee30abd: 🐛 fix(froom_generator): suppress lints in generated code with ignore_for_file: type=lint
- 861826a: ✨ feat: add @Upsert annotation mirroring Room's @Upsert
- 640c1d3: ✨ feat(database): add clearAllTables() like Room
- 0fa024d: ✨ feat(generator): assign fields not initialized by the constructor via setters
- 1bfb682: ✨ feat(column_info): add defaultValue for SQL column default values
- 82c78a4: 🐛 fix(generator): prefer the unnamed constructor and call named ones by name
- 9636877: ✨ feat(migrations): add fallbackToDestructiveMigration() like Room
- 32d1008: 🐛 fix(generator): support optional and named parameters of DAO methods
- c8475f0: 🐛 fix(dao): notify streams of other DAOs about @Query changes
- 527dd10: 🐛 fix(migrations): recreate database views after migrations
- 437dd2c: ✨ feat(generator): allow mixins on entities and views
- 5352cd5: ✨ feat(index): add Index.where for partial indices
- 183c83a: 🐛 fix(query): allow nullable query method parameters
- 2bab716: 📝 docs: track the open upstream floor issues
- aa601c8: ✨ feat(type_converter): use converters of non-nullable types for nullable values
- 27f0012: 🐛 fix(dao): generate overridden DAO methods only once
- 916f801: 🐛 fix(entity): include overridden fields only once
- 0d69991: ✨ feat(entity): treat 0 of auto generated int primary keys as unset
- ebf3ab1: 🐛 fix(migrations): run migrations with foreign keys disabled
- 415d7f8: 📝 docs: document absolute database paths
- a8bbbed: 🐛 fix(query): accept list parameters as row values
- d27801e: 📝 docs: import the entity in the DAO example
- 08f3712: ✨ feat(type_converter): accept converters implementing TypeConverter
- 83fbc0c: 🐛 fix(query): report unresolved return types of query methods
- 5dbe2f6: 🐛 fix(streams): handle re-queries finishing after the database closed
- 1f3dc54: 🐛 fix(dao): ignore @transaction on query and change methods
- 9283a6a: 🐛 fix(example): create tasks with the open status
- c2245a7: 🐛 fix(index): create indices with IF NOT EXISTS
- ca2d50f: 🐛 fix(transaction): keep nullable return types of transaction methods
- 794e287: 🐛 fix(entity): report unknown compound primary key columns
- a55861a: 📝 docs: document full text search entities
- 9095cd5: 🐛 fix(query): read doubles from integer values
- 7de2d56: 🐛 fix(query): report invalid queries during code generation
- 84ec23e: 🐛 fix(streams): support quoted table names of stream queries
- 54b2505: ✨ feat(index): support indices on expressions
- 4703275: 📝 docs: fix the link to the integration tests
- 8299992: 📝 docs: explain how the linked tests differ from Flutter tests
- 1a69159: 🐛 fix(migrations): roll back migrations violating foreign keys
- 6828568: ✅ test: cover RESTRICT foreign keys when clearing and dropping tables
- 9e6d0e5: 🐛 fix(dao): keep annotations of methods redeclared without them
- b62f0e6: 🐛 fix(column_info): don't escape default values which are string literals
- eb37515: 🐛 fix(query): reject list parameters as function arguments
- 1a912dc: 🐛 fix(migrations): require consecutive migrations
- d647c93: 🐛 fix(dao): write constant default values of parameters as literals
- 68677a3: 🐛 fix(database): don't notify streams after closing while clearing tables
- 6b989de: ⚡️ perf(query): share the SQL engine validating queries
- 00546ff: 🐛 fix(dao): respect concrete methods and signatures of redeclarations
- 1b6f6c9: ♻️ refactor(query): accept row values only after specific keywords
- 42f2c7b: ⚡️ perf(migrations): remember versions without migration path
- 081f10b: 🐛 fix(column_info): unquote quoted default values with unescaped quotes
- 5976f8a: 🐛 fix(streams): don't notify streams after closing the database
- b6b7a0a: 🐛 fix(dao): write enum default values of parameters as enum values
- e4b2893: 🐛 fix(query): accept row values after IN and CASE
- 78dd438: 🐛 fix(dao): compare default values of redeclarations by name and value
- 04381ca: ⚡️ perf(migrations): group migrations by start version for the path search
- a580f36: 🐛 fix(streams): match FROM as a whole word for the streamed table
- 36d7b7e: 🐛 fix(migrations): only fail on foreign key violations added by migrations
- 689934f: 🐛 fix(generator): search superclasses before interfaces
- e838380: ✅ test(dao): cover redeclarations with implicit null default values
- 41db98d: 🐛 fix(index): hash column names and expressions by content
- 1c7a6c5: 🐛 fix(column_info): strip all surrounding quotes of default values again
- 617961e: 🐛 fix(query): reject list parameters in quoted or nested function calls

### 📝 Documentation
- **getting-started**: Document absolute database paths for `databaseBuilder()`, covered by a test (#179, upstream floor#588, floor#803)
- **getting-started, READMEs**: Import the entity in the DAO example (#181, upstream floor#645)
- **entities**: Document FTS entities, tokenizers, the `rowid` primary key, `MATCH` queries and the missing constraints of virtual tables (#190, upstream floor#792)
- **docs**: Point test links of the docs and READMEs to `froom_common/test/integration`, close the `group(` call of the testing example (#195, upstream floor#840)

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
