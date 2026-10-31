# Platform Support

Froom supports iOS, Android, Linux, macOS, Windows and the web.
It accesses SQLite through a [sqflite](https://github.com/tekartik/sqflite) `DatabaseFactory`, which can be chosen per database.

## Default Database Factory

Databases use the FFI implementation of sqflite by default, which is based on [sqlite3](https://pub.dev/packages/sqlite3):

| Platform | Default factory |
|---|---|
| Android, iOS, macOS, Linux, Windows | `databaseFactoryFfi` of [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) |
| Web | `databaseFactoryFfiWeb` of [sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web), which requires the SQLite WebAssembly binary and worker set up by `dart run sqflite_common_ffi_web:setup` |

## Choosing the SQLite Library

On native platforms, sqlite3 bundles its own build of SQLite with the app by [hooks](https://dart.dev/tools/hooks), so no further dependency is needed.
The library can be chosen per platform in the `pubspec.yaml` of the app, for example the SQLite of the operating system on iOS and macOS:

```yaml
hooks:
  user_defines:
    sqlite3:
      source:
        ios: system
        macos: system
        default: sqlite3 # the bundled build
```

Other sources are `sqlite3mc` ([SQLite3MultipleCiphers](https://utelle.github.io/SQLite3MultipleCiphers/)) and `sqlcipher` for encrypted databases, and custom builds of SQLite.
See the [hook options of sqlite3](https://github.com/simolus3/sqlite3.dart/blob/main/sqlite3/doc/hook.md) for all of them.

Android doesn't allow apps to load the SQLite of the system with FFI.
Use the sqflite plugin to access it instead, as described below.

!!! warning "FTS3 and FTS4"
    The SQLite builds bundled by sqlite3, including the encrypted ones, only support FTS5, so entities annotated with `@Fts3` or `@Fts4` fail with `no such module`.
    Use the SQLite of the system for them (`source: system`, or the sqflite plugin on Android), or a custom build enabling `SQLITE_ENABLE_FTS3`.

## Choosing the Database Factory

Pass another factory to the builder of the database to open it with, for example the sqflite plugin on Android and iOS:

```dart
import 'package:sqflite/sqflite.dart' as sqflite;

final database = await $FroomAppDatabase
    .databaseBuilder('app_database.db')
    .databaseFactory(sqflite.databaseFactorySqflitePlugin)
    .build();
```

Any `DatabaseFactory` works, e.g. `databaseFactoryFfiNoIsolate` to run the queries on the current isolate, or the factory of another SQLite library.

Changes are only reported to the streams of the database opened by the builder, not to other isolates, processes or browser tabs writing to the same database file.
