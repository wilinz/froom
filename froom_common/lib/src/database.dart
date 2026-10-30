import 'dart:async';

import 'package:meta/meta.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite;

/// Extend this class to enable database functionality.
abstract class FroomDatabase {
  /// [StreamController] that is responsible for notifying listeners about changes
  /// in specific tables. It acts as an event bus.
  @protected
  late final StreamController<String> changeListener;

  /// Use this whenever you need direct access to the sqflite database.
  late final sqflite.DatabaseExecutor database;

  /// The table names of all entities of the database.
  @protected
  List<String> get entityTableNames;

  /// Deletes all rows of all entity tables while keeping the database schema,
  /// like Room's `clearAllTables`.
  ///
  /// The counters of `AUTOINCREMENT` primary keys are reset as well.
  Future<void> clearAllTables() async {
    Future<void> clear(final sqflite.DatabaseExecutor executor) async {
      // foreign keys are only checked once the transaction gets committed
      await executor.execute('PRAGMA defer_foreign_keys = TRUE');
      for (final tableName in entityTableNames) {
        await executor.execute('DELETE FROM `$tableName`');
      }

      final sequenceTable = await executor.rawQuery(
        'SELECT 1 FROM sqlite_master WHERE type = ? AND name = ?',
        ['table', 'sqlite_sequence'],
      );
      if (sequenceTable.isNotEmpty) {
        await executor.execute('DELETE FROM sqlite_sequence');
      }
    }

    final database = this.database;
    if (database is sqflite.Database) {
      await database.transaction(clear);
    } else {
      await clear(database);
    }

    // the database might have been closed meanwhile
    if (changeListener.isClosed) return;
    entityTableNames.forEach(changeListener.add);
  }

  /// Closes the database.
  Future<void> close() async {
    await changeListener.close();

    final database = this.database;
    if (database is sqflite.Database && database.isOpen) {
      await database.close();
    }
  }
}
