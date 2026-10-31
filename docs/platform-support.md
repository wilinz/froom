# Platform Support

Froom supports iOS, Android, Linux, macOS, Windows and the web.
It accesses SQLite through a [sqflite](https://github.com/tekartik/sqflite) `DatabaseFactory`, which can be chosen per database.

## Default Database Factory

| Platform | Default factory |
|---|---|
| Android, iOS | The [sqflite](https://pub.dev/packages/sqflite) plugin, which uses the SQLite of the system and requires the app to depend on `sqflite`. Background isolates have to register it with `DartPluginRegistrant.ensureInitialized()` |
| Linux, macOS, Windows | `databaseFactoryFfi` of [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi), which is based on [sqlite3](https://pub.dev/packages/sqlite3) |
| Web | `databaseFactoryFfiWeb` of [sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web), see [Web](#web) |

The sqflite plugin stores databases passed by name to `databaseBuilder()` in the databases directory of the platform.
The FFI factory stores them in `.dart_tool/sqflite_common_ffi/databases` of the working directory instead, which suits tests and command line apps.
Apps using it should pass an absolute path, e.g. based on `getApplicationSupportDirectory()` of the [path_provider](https://pub.dev/packages/path_provider) package.

## Choosing the SQLite Library

With the FFI factory, sqlite3 bundles its own build of SQLite with the app by [hooks](https://dart.dev/tools/hooks), so no further dependency is needed.
The library can be chosen per platform in the `pubspec.yaml` of the app, for example the SQLite of the operating system on macOS:

```yaml
hooks:
  user_defines:
    sqlite3:
      source:
        macos: system
        default: sqlite3 # the bundled build
```

Other sources are `sqlite3mc` ([SQLite3MultipleCiphers](https://utelle.github.io/SQLite3MultipleCiphers/)) and `sqlcipher` for encrypted databases, and custom builds of SQLite.
See the [hook options of sqlite3](https://github.com/simolus3/sqlite3.dart/blob/main/sqlite3/doc/hook.md) for all of them.

Android doesn't allow apps to load the SQLite of the system with FFI, use the sqflite plugin for it instead.

As sqlite3 bundles SQLite on Android and iOS as well, apps only using the sqflite plugin there can avoid bundling it by choosing the system SQLite for these platforms, which is never loaded then:

```yaml
hooks:
  user_defines:
    sqlite3:
      source:
        android: system
        ios: system
        default: sqlite3
```

!!! warning "FTS3 and FTS4"
    The SQLite builds bundled by sqlite3, including the encrypted ones, only support FTS5, so opening databases with entities annotated with `@Fts3` or `@Fts4` fails with a `MissingSqliteModuleException`.
    Use [`@Fts5`](entities.md#fts5) instead, the SQLite of the system (`source: system`, or the sqflite plugin on Android and iOS), or a custom build enabling `SQLITE_ENABLE_FTS3`.

## Choosing the Database Factory

Pass another factory to the builder of the database to open it with, for example the FFI one on Android and iOS, to use the bundled or an encrypted SQLite there:

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final database = await $FroomAppDatabase
    .databaseBuilder(path)
    .databaseFactory(databaseFactoryFfi)
    .build();
```

Any `DatabaseFactory` works, e.g. `databaseFactoryFfiNoIsolate` to run the queries on the current isolate, or the factory of another SQLite library.

Changes are only reported to the streams of the database opened by the builder, not to other isolates, processes or browser tabs writing to the same database.

## Encryption

Databases are encrypted with a password passed to their builder, which requires an encrypted build of SQLite like [SQLite3MultipleCiphers](https://utelle.github.io/SQLite3MultipleCiphers/) or [SQLCipher](https://www.zetetic.net/sqlcipher/), and thus the FFI factory:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlite3mc # or sqlcipher
```

```dart
final database = await $FroomAppDatabase
    .databaseBuilder(path)
    .password(password)
    .build();
```

Opening the database fails with a `DatabaseEncryptionException` if the password is wrong, the database isn't encrypted, or SQLite doesn't support encryption, e.g. the system SQLite of the sqflite plugin, instead of storing the database unencrypted.
Existing unencrypted databases aren't encrypted by adding a password, which fails as well, so their data has to be copied into a new database with the password.
In-memory databases aren't stored and thus not encrypted.
Encryption isn't supported on the web, as the storage of sqflite_common_ffi_web doesn't support it.

## Web

On the web, the databases are stored in IndexedDB by [sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web), which runs SQLite compiled to WebAssembly in a shared worker.
Its files have to be added to the `web` directory of the app once, and again after upgrading sqflite_common_ffi_web:

```bash
dart run sqflite_common_ffi_web:setup
```

This adds `sqlite3.wasm` and the worker `sqflite_sw.js`.
Apps can be compiled both to JavaScript and to WebAssembly (`flutter build web --wasm`).
