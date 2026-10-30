import 'dart:async';

import 'package:froom_common/src/extension/change_listener_extension.dart';
import 'package:froom_common/src/util/primary_key_helper.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Inserts entities and updates them instead when they already exist.
///
/// Mirrors the behavior of Room's `@Upsert`: an insertion is attempted first
/// and, if it fails because of a unique constraint conflict, the entity gets
/// updated by its primary key. If no row with the primary key exists, e.g.
/// because the conflict was caused by another unique index, the original
/// exception is rethrown.
///
/// Upserts that don't return ids use a single batch of native
/// `INSERT ... ON CONFLICT DO UPDATE` statements instead when SQLite supports
/// them (version 3.24.0 and above, but not for virtual tables), which behaves
/// the same but avoids a round trip and an exception per existing entity.
///
/// Virtual tables like FTS tables don't enforce unique primary keys, thus an
/// insertion never conflicts. Their entities get updated by primary key first
/// and only inserted when no row got updated.
class UpsertionAdapter<T> {
  static const _sqliteConstraintPrimaryKey = 1555;
  static const _sqliteConstraintUnique = 2067;
  static const _nativeUpsertMinimumVersion = [3, 24, 0];

  /// Information about tables, cached per database and table.
  static final _tableInfoCache = Expando<Map<String, _TableInfo>>();

  final DatabaseExecutor _database;
  final String _entityName;
  final List<String> _primaryKeyColumnName;
  final Map<String, Object?> Function(T) _valueMapper;
  final StreamController<String>? _changeListener;

  /// The native upsert statement, built from the columns of the first item,
  /// as the value mapper always maps to the same columns.
  String? _nativeUpsertSql;

  UpsertionAdapter(
    final DatabaseExecutor database,
    final String entityName,
    final List<String> primaryKeyColumnName,
    final Map<String, Object?> Function(T) valueMapper, [
    final StreamController<String>? changeListener,
  ]) : assert(entityName.isNotEmpty),
       assert(primaryKeyColumnName.isNotEmpty),
       _database = database,
       _entityName = entityName,
       _primaryKeyColumnName = primaryKeyColumnName,
       _valueMapper = valueMapper,
       _changeListener = changeListener;

  Future<void> upsert(final T item) async {
    await upsertList([item]);
  }

  Future<void> upsertList(final List<T> items) async {
    if (items.isEmpty) return;

    if (!(await _getTableInfo()).supportsNativeUpsert) {
      await upsertListAndReturnIds(items);
      return;
    }

    final batch = _database.batch();
    for (final item in items) {
      final values = _valueMapper(item);
      final sql = _nativeUpsertSql ??= _getNativeUpsertSql(values.keys);
      batch.rawInsert(sql, values.values.toList());
    }
    await batch.commit(noResult: true);
    _changeListener?.notifyChange(_entityName);
  }

  /// Returns the row id of the inserted entity or `-1` if it got updated.
  Future<int> upsertAndReturnId(final T item) async {
    final tableInfo = await _getTableInfo();
    final id = await _runInTransaction(
      (executor) => _upsert(executor, item, tableInfo),
    );
    _changeListener?.notifyChange(_entityName);
    return id;
  }

  /// Returns the row ids of the inserted entities or `-1` for updated ones.
  Future<List<int>> upsertListAndReturnIds(final List<T> items) async {
    if (items.isEmpty) return [];

    final tableInfo = await _getTableInfo();
    final ids = await _runInTransaction((executor) async {
      final ids = <int>[];
      for (final item in items) {
        ids.add(await _upsert(executor, item, tableInfo));
      }
      return ids;
    });
    _changeListener?.notifyChange(_entityName);
    return ids;
  }

  /// Returns the row id of the inserted item or `-1` if it got updated.
  Future<int> _upsert(
    final DatabaseExecutor executor,
    final T item,
    final _TableInfo tableInfo,
  ) async {
    final values = _valueMapper(item);
    // A partial entity may omit an auto generated primary key, which leaves
    // no row to update.
    final hasPrimaryKey = _primaryKeyColumnName
        .every((columnName) => values[columnName] != null);

    if (tableInfo.isVirtualTable) {
      if (hasPrimaryKey && await _update(executor, values) != 0) return -1;
      return executor.insert(_entityName, values);
    }

    try {
      final id = await executor.insert(
        _entityName,
        values,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return id;
    } on DatabaseException catch (exception) {
      if (!_isUniqueConstraintError(exception)) rethrow;
      if (!hasPrimaryKey) rethrow;

      final changedRows = await _update(executor, values);
      // Unlike Room, don't silently drop the item when the conflict wasn't
      // caused by the primary key, e.g. by another unique index, so that no
      // row with the primary key exists to be updated.
      if (changedRows == 0) rethrow;
      return -1;
    }
  }

  /// Updates the row with the primary key of [values], returns the number of
  /// changed rows.
  Future<int> _update(
    final DatabaseExecutor executor,
    final Map<String, Object?> values,
  ) {
    return executor.update(
      _entityName,
      values,
      where: PrimaryKeyHelper.getWhereClause(_primaryKeyColumnName),
      whereArgs: PrimaryKeyHelper.getPrimaryKeyValues(
        _primaryKeyColumnName,
        values,
      ),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Whether the insertion failed because of a primary key or unique
  /// constraint conflict, checked like Room does by message and result code.
  bool _isUniqueConstraintError(final DatabaseException exception) {
    final resultCode = exception.getResultCode();
    return exception.isUniqueConstraintError() ||
        resultCode == _sqliteConstraintPrimaryKey ||
        resultCode == _sqliteConstraintUnique;
  }

  Future<_TableInfo> _getTableInfo() async {
    final database = _database.database;
    final cache = _tableInfoCache[database] ??= {};
    final cached = cache[_entityName];
    if (cached != null) return cached;

    final result = await _database.rawQuery(
      'SELECT sqlite_version() AS version, '
      '(SELECT sql FROM sqlite_master WHERE type = ? AND name = ?) AS sql',
      ['table', _entityName],
    );
    final version = result.first['version'] as String;
    final sql = result.first['sql'] as String?;
    final isVirtualTable =
        sql?.trimLeft().toUpperCase().startsWith('CREATE VIRTUAL TABLE') ??
            false;

    return cache[_entityName] = _TableInfo(
      isVirtualTable: isVirtualTable,
      supportsNativeUpsert:
          !isVirtualTable && _isAtLeast(version, _nativeUpsertMinimumVersion),
    );
  }

  static bool _isAtLeast(final String version, final List<int> minimum) {
    final parts = version.split('.').map((part) => int.tryParse(part) ?? 0);
    final padded = [...parts, 0, 0, 0];
    for (var index = 0; index < minimum.length; index++) {
      if (padded[index] != minimum[index]) {
        return padded[index] > minimum[index];
      }
    }
    return true;
  }

  String _getNativeUpsertSql(final Iterable<String> columnNames) {
    final columns = columnNames.map((columnName) => '`$columnName`');
    final placeholders = List.filled(columnNames.length, '?');
    final conflictTarget =
        _primaryKeyColumnName.map((columnName) => '`$columnName`');
    final updates = columnNames
        .where((columnName) => !_primaryKeyColumnName.contains(columnName))
        .map((columnName) => '`$columnName` = excluded.`$columnName`');
    final action =
        updates.isEmpty ? 'NOTHING' : 'UPDATE SET ${updates.join(', ')}';

    return 'INSERT INTO `$_entityName` (${columns.join(', ')}) '
        'VALUES (${placeholders.join(', ')}) '
        'ON CONFLICT(${conflictTarget.join(', ')}) DO $action';
  }

  /// Like Room, the upsert of a single item runs in a transaction too.
  Future<R> _runInTransaction<R>(
    final Future<R> Function(DatabaseExecutor executor) action,
  ) {
    final database = _database;
    if (database is Database) {
      return database.transaction(action);
    } else {
      return action(database);
    }
  }
}

class _TableInfo {
  final bool isVirtualTable;

  /// Whether SQLite supports `INSERT ... ON CONFLICT DO UPDATE` for the table.
  final bool supportsNativeUpsert;

  const _TableInfo({
    required this.isVirtualTable,
    required this.supportsNativeUpsert,
  });
}
