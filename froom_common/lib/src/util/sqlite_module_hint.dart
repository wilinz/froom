import 'package:sqflite_common/sqlite_api.dart';

/// Thrown when the SQLite library lacks a module required by the database,
/// e.g. the FTS version of an entity.
///
/// It's a [DatabaseException] like the exception of SQLite it explains.
class MissingSqliteModuleException extends DatabaseException {
  /// The name of the missing module, e.g. `fts4`.
  final String module;

  /// The exception of SQLite about the missing module.
  final Object cause;

  MissingSqliteModuleException(this.module, this.cause)
      : super('no such module: $module');

  @override
  int? getResultCode() {
    final cause = this.cause;
    return cause is DatabaseException ? cause.getResultCode() : null;
  }

  @override
  Object? get result {
    final cause = this.cause;
    return cause is DatabaseException ? cause.result : null;
  }

  @override
  String toString() {
    final hint = switch (module) {
      'fts3' || 'fts4' =>
        'The SQLite builds bundled by package:sqlite3 only support FTS5. Use '
            '@Fts5 instead, the SQLite of the system (the sqflite plugin on '
            'Android, or `hooks: user_defines: sqlite3: source: system` in '
            'the pubspec.yaml on other platforms) or a custom build of SQLite '
            'enabling SQLITE_ENABLE_FTS3.',
      'fts5' =>
        'Use the SQLite bundled by package:sqlite3, which supports FTS5: on '
            'Android, whose SQLite of the sqflite plugin lacks it, by passing '
            'databaseFactoryFfi to databaseFactory() of the database builder, '
            'with an absolute path of the database; on other platforms by '
            'removing `hooks: user_defines: sqlite3: source: system` from the '
            'pubspec.yaml.',
      _ => 'Use a SQLite build supporting it.',
    };
    return 'MissingSqliteModuleException: The SQLite library lacks the module '
        '$module. $hint\nCaused by: $cause';
  }
}

/// Runs the [action] opening a database, explaining failures due to modules
/// missing in the SQLite library.
Future<T> explainMissingSqliteModules<T>(Future<T> Function() action) async {
  try {
    return await action();
    // not other exceptions of callbacks, which may mention modules
  } on DatabaseException catch (exception, stackTrace) {
    final module = RegExp(r'no such module: (\w+)')
        .firstMatch(exception.toString())
        ?.group(1);
    if (module == null) rethrow;
    Error.throwWithStackTrace(
      MissingSqliteModuleException(module, exception),
      stackTrace,
    );
  }
}
