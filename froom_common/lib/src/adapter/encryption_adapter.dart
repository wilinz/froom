import 'package:sqflite_common/sqlite_api.dart';

/// Thrown when an encrypted database can't be opened with its password.
///
/// It's a [DatabaseException] like the exception of SQLite causing it.
class DatabaseEncryptionException extends DatabaseException {
  final String message;

  /// The exception of SQLite causing it, if any.
  final Object? cause;

  DatabaseEncryptionException(this.message, [this.cause]) : super(message);

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
  String toString() => cause == null
      ? 'DatabaseEncryptionException: $message'
      : 'DatabaseEncryptionException: $message\nCaused by: $cause';
}

// ignore: avoid_classes_with_only_static_members
abstract class EncryptionAdapter {
  /// The result code `SQLITE_NOTADB` of SQLite.
  static const _notADatabase = 26;

  /// The passwords the open databases were configured with.
  static final _passwords = Expando<Object>();

  /// The value of [_passwords] for databases without password.
  static const _noPassword = Object();

  /// Rejects the empty [password], which SQLite3MultipleCiphers doesn't
  /// encrypt with.
  static void validatePassword(final String password) {
    if (password.isEmpty) {
      throw ArgumentError.value(
        password,
        'password',
        'An empty password would store the database unencrypted',
      );
    }
  }

  /// Checks the [password] of the [database] being open, which sqflite
  /// returns without configuring it again when its path is already open.
  static Database checkPassword(
    final Database database,
    final String? password,
  ) {
    final configuredPassword = _passwords[database];
    // e.g. unknown after a hot restart
    if (configuredPassword != null &&
        configuredPassword != (password ?? _noPassword)) {
      throw DatabaseEncryptionException(
        'The database is already open with another password or without one.',
      );
    }
    return database;
  }

  /// Sets the [password] of the [database], if any, which has to happen
  /// before any other statement accesses it.
  ///
  /// SQLite builds without encryption ignore the password, so they are
  /// rejected instead of storing the database unencrypted.
  static Future<void> setPassword(
    final Database database,
    final String? password,
  ) async {
    if (password != null) {
      validatePassword(password);
      // SQLite builds without encryption, e.g. on the web, ignore it
      await database
          .execute("PRAGMA key = '${password.replaceAll("'", "''")}'");

      // SQLite3MultipleCiphers reports its cipher, SQLCipher its version
      if ((await database.rawQuery('PRAGMA cipher')).isEmpty &&
          (await database.rawQuery('PRAGMA cipher_version')).isEmpty) {
        throw DatabaseEncryptionException(
          "The SQLite library doesn't support encryption, so the database "
          'would be stored unencrypted. Use an encrypted build of SQLite, '
          'e.g. with `hooks: user_defines: sqlite3: source: sqlite3mc` in the '
          'pubspec.yaml.',
        );
      }
    }

    // reading fails if the password doesn't decrypt the database
    try {
      await database.rawQuery('SELECT count(*) FROM sqlite_master');
    } on DatabaseException catch (exception, stackTrace) {
      if (exception.getResultCode() != _notADatabase) rethrow;
      Error.throwWithStackTrace(
        DatabaseEncryptionException(
          password == null
              ? "The database can't be read without password, so it's "
                  "encrypted or isn't a database."
              : "The database can't be decrypted with the password, which is "
                  "wrong, or the database isn't encrypted.",
          exception,
        ),
        stackTrace,
      );
    }
    _passwords[database] = password ?? _noPassword;
  }
}
