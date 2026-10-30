import 'package:froom_generator/value_object/auto_migration.dart';
import 'package:froom_generator/value_object/schema.dart';

/// Thrown when an automatic migration can't be generated.
class SchemaDiffException implements Exception {
  final String message;

  SchemaDiffException(this.message);

  @override
  String toString() => message;
}

/// Detects the changes between two schema versions of a database, like
/// Room's `SchemaDiffer`.
///
/// Renamed and deleted tables and columns have to be declared by the
/// [renamedTables], [renamedColumns], [deletedTables] and [deletedColumns]
/// of the spec named [specName], as they can't be distinguished otherwise.
class SchemaDiffer {
  final DatabaseSchema _fromSchema;
  final DatabaseSchema _toSchema;
  final String? _specName;
  final List<RenamedTable> _renamedTableEntries;
  final List<RenamedColumn> _renamedColumnEntries;
  final Set<String> _deletedTables;
  final List<DeletedColumn> _deletedColumns;

  final _potentiallyDeletedTables = <String>{};
  final _addedTables = <EntitySchema>[];

  // tables which are only renamed, without complex changes
  final _renamedTables = <String, String>{};

  // keyed by the table name in the from version
  final _complexChangedTables = <String, ComplexChangedTable>{};
  final _addedColumns = <AddedColumn>[];

  SchemaDiffer(
    this._fromSchema,
    this._toSchema, {
    final String? specName,
    final List<RenamedTable> renamedTables = const [],
    final List<RenamedColumn> renamedColumns = const [],
    final List<DeletedTable> deletedTables = const [],
    final List<DeletedColumn> deletedColumns = const [],
  })  : _specName = specName,
        _renamedTableEntries = renamedTables,
        _renamedColumnEntries = renamedColumns,
        _deletedTables = deletedTables.map((table) => table.tableName).toSet(),
        _deletedColumns = deletedColumns;

  SchemaDiff diffSchemas() {
    final processedColumnsByNewTable = <String, List<String>>{};

    // from the old to the new version for changed and deleted tables and
    // columns
    for (final fromTable in _fromSchema.entities) {
      final toTable = _detectTableLevelChanges(fromTable);
      if (toTable == null) continue;

      processedColumnsByNewTable[toTable.tableName] = fromTable.fields
          .map((fromColumn) =>
              _detectColumnLevelChanges(fromTable, toTable, fromColumn))
          .whereType<String>()
          .toList();
    }

    // from the new to the old version for added tables and columns
    for (final toTable in _toSchema.entities) {
      _processAddedTableAndColumns(toTable, processedColumnsByNewTable);
    }

    for (final tableName in _potentiallyDeletedTables) {
      throw SchemaDiffException(_deletedOrRenamedTableFound(tableName));
    }
    _processDeletedColumns();

    return SchemaDiff(
      addedTables: _addedTables,
      renamedTables: _renamedTables,
      deletedTables: _deletedTables.toList(),
      addedColumns: _addedColumns,
      complexChangedTables: _complexChangedTables.values.toList(),
      fromViews: _fromSchema.views,
      toViews: _toSchema.views,
    );
  }

  /// Returns the table in the new version, or null if it was deleted.
  EntitySchema? _detectTableLevelChanges(final EntitySchema fromTable) {
    final renamedTable = _getRenamedTable(fromTable.tableName);
    if (renamedTable != null) {
      final toTable =
          _toSchema.entitiesByTableName[renamedTable.toTableName];
      if (toTable == null) {
        throw SchemaDiffException(
          'AutoMigration failure in $_specName: The table renamed from '
          '${renamedTable.fromTableName} to ${renamedTable.toTableName} is not '
          'found in the new version of the database.',
        );
      }
      if (_containsComplexChanges(fromTable, toTable)) {
        _addComplexChangedTable(fromTable, toTable);
      } else {
        _renamedTables[fromTable.tableName] = toTable.tableName;
      }
      return toTable;
    }

    final toTable = _toSchema.entitiesByTableName[fromTable.tableName];
    final isDeleted = _deletedTables.contains(fromTable.tableName);
    if (toTable != null) {
      if (isDeleted) {
        throw SchemaDiffException(
          'AutoMigration failure in $_specName: The table '
          '${fromTable.tableName} is declared as deleted, but it exists in '
          'the new version of the database.',
        );
      }
      if (_containsComplexChanges(fromTable, toTable)) {
        _addComplexChangedTable(fromTable, toTable);
      }
      return toTable;
    }

    if (!isDeleted) _potentiallyDeletedTables.add(fromTable.tableName);
    return null;
  }

  /// Returns the name of the column in the new version, or null if it was
  /// deleted.
  String? _detectColumnLevelChanges(
    final EntitySchema fromTable,
    final EntitySchema toTable,
    final FieldSchema fromColumn,
  ) {
    final renamedColumn =
        _getRenamedColumn(fromTable.tableName, fromColumn.columnName);
    if (renamedColumn != null) {
      final complexChangedTable = _addComplexChangedTable(fromTable, toTable);
      complexChangedTable.renamedColumns[renamedColumn.toColumnName] =
          fromColumn.columnName;
      return renamedColumn.toColumnName;
    }

    final match = toTable.fieldsByColumnName[fromColumn.columnName];
    if (match != null) {
      if (!match.isSchemaEqual(fromColumn)) {
        _addComplexChangedTable(fromTable, toTable);
      }
      return match.columnName;
    }

    final isDeleted = _deletedColumns.any((column) =>
        column.tableName == fromTable.tableName &&
        column.columnName == fromColumn.columnName);
    if (!isDeleted) {
      throw SchemaDiffException(_deletedOrRenamedColumnFound(
        fromTable.tableName,
        fromColumn.columnName,
      ));
    }
    return null;
  }

  void _processAddedTableAndColumns(
    final EntitySchema toTable,
    final Map<String, List<String>> processedColumnsByNewTable,
  ) {
    final renamedTable = _renamedTableEntries
        .where((table) => table.toTableName == toTable.tableName)
        .firstOrNull;
    final fromTable = _fromSchema.entitiesByTableName[
        renamedTable?.fromTableName ?? toTable.tableName];
    if (fromTable == null) {
      _checkTableName(toTable);
      _addedTables.add(toTable);
      return;
    }

    final processedColumns = processedColumnsByNewTable[toTable.tableName];
    final fromColumns = fromTable.fieldsByColumnName;
    for (final toColumn in toTable.fields) {
      if (processedColumns?.contains(toColumn.columnName) ?? false) continue;
      if (fromColumns.containsKey(toColumn.columnName)) continue;

      if (toColumn.notNull && toColumn.defaultValue == null) {
        throw SchemaDiffException(
          'The new NOT NULL column ${toColumn.columnName} of the table '
          '${toTable.tableName} has no default value. Specify it with '
          '@ColumnInfo(defaultValue: ...).',
        );
      }
      // tables with complex changes get recreated with the new column
      if (!_complexChangedTables.containsKey(fromTable.tableName)) {
        _addedColumns.add(AddedColumn(toTable.tableName, toColumn));
      }
    }
  }

  void _processDeletedColumns() {
    for (final deletedColumn in _deletedColumns) {
      final fromTable = _fromSchema.entitiesByTableName[deletedColumn.tableName];
      final toTable = _toSchema.entitiesByTableName[deletedColumn.tableName];
      if (fromTable == null || toTable == null) {
        throw SchemaDiffException(
          'AutoMigration failure in $_specName: The table '
          '${deletedColumn.tableName} of the deleted column '
          '${deletedColumn.columnName} is not found in both versions of the '
          'database.',
        );
      }
      if (toTable.fieldsByColumnName.containsKey(deletedColumn.columnName)) {
        throw SchemaDiffException(
          'AutoMigration failure in $_specName: The column '
          '${deletedColumn.columnName} of the table ${deletedColumn.tableName} '
          'is declared as deleted, but it exists in the new version of the '
          'database.',
        );
      }
      // the columns are deleted by recreating the table
      _addComplexChangedTable(fromTable, toTable);
    }
  }

  bool _containsComplexChanges(
    final EntitySchema fromTable,
    final EntitySchema toTable,
  ) {
    if (fromTable.isFts || toTable.isFts) {
      // virtual tables can't be altered
      return fromTable.createTable(toTable.tableName) !=
              toTable.createTable(toTable.tableName) ||
          fromTable.tableName != toTable.tableName;
    }
    if (!fromTable.primaryKey.isSchemaEqual(toTable.primaryKey) ||
        fromTable.withoutRowid != toTable.withoutRowid ||
        !_areForeignKeysEqual(fromTable.foreignKeys, toTable.foreignKeys) ||
        !_areIndicesEqual(fromTable.indices, toTable.indices)) {
      return true;
    }
    // the foreign keys have to reference the new name of the table
    return fromTable.foreignKeys.any((foreignKey) => _renamedTableEntries
        .any((table) => table.fromTableName == foreignKey.table));
  }

  bool _areForeignKeysEqual(
    final List<ForeignKeySchema> fromForeignKeys,
    final List<ForeignKeySchema> toForeignKeys,
  ) {
    return fromForeignKeys.length == toForeignKeys.length &&
        fromForeignKeys.every((fromForeignKey) => toForeignKeys
            .any((toForeignKey) => fromForeignKey.isSchemaEqual(toForeignKey)));
  }

  bool _areIndicesEqual(
    final List<IndexSchema> fromIndices,
    final List<IndexSchema> toIndices,
  ) {
    return fromIndices.length == toIndices.length &&
        fromIndices.every((fromIndex) =>
            toIndices.any((toIndex) => fromIndex.isSchemaEqual(toIndex)));
  }

  ComplexChangedTable _addComplexChangedTable(
    final EntitySchema fromTable,
    final EntitySchema toTable,
  ) {
    _renamedTables.remove(fromTable.tableName);
    return _complexChangedTables.putIfAbsent(fromTable.tableName, () {
      if (_toSchema.entitiesByTableName.containsKey(toTable.newTableName)) {
        throw SchemaDiffException(
            _tableWithConflictingPrefix(toTable.newTableName));
      }
      return ComplexChangedTable(fromTable, toTable, {});
    });
  }

  void _checkTableName(final EntitySchema table) {
    if (table.tableName.startsWith('_new_')) {
      throw SchemaDiffException(_tableWithConflictingPrefix(table.tableName));
    }
  }

  RenamedTable? _getRenamedTable(final String tableName) {
    final renamedTables = _renamedTableEntries
        .where((table) => table.fromTableName == tableName)
        .toList();
    if (renamedTables.length > 1) {
      throw SchemaDiffException(
        'AutoMigration failure in $_specName: The table $tableName is renamed '
        'by multiple @RenameTable annotations.',
      );
    }
    return renamedTables.firstOrNull;
  }

  RenamedColumn? _getRenamedColumn(
    final String tableName,
    final String columnName,
  ) {
    final renamedColumns = _renamedColumnEntries
        .where((column) =>
            column.tableName == tableName && column.fromColumnName == columnName)
        .toList();
    if (renamedColumns.length > 1) {
      throw SchemaDiffException(
        'AutoMigration failure in $_specName: The column $columnName of the '
        'table $tableName is renamed by multiple @RenameColumn annotations.',
      );
    }
    return renamedColumns.firstOrNull;
  }

  String _tableWithConflictingPrefix(final String tableName) =>
      'The new version of the database contains the table $tableName with '
      "the prefix '_new_', which conflicts with recreating tables in "
      'automatic migrations. Use another name.';

  String _deletedOrRenamedTableFound(final String tableName) {
    return '${_failurePrefix()}The table $tableName has been either deleted '
        'or renamed. Annotate the spec with @DeleteTable or @RenameTable:\n'
        "  @DeleteTable(tableName: '$tableName')\n"
        "  @RenameTable(fromTableName: '$tableName', toTableName: <new name>)";
  }

  String _deletedOrRenamedColumnFound(
    final String tableName,
    final String columnName,
  ) {
    return '${_failurePrefix()}The column $columnName of the table '
        '$tableName has been either deleted or renamed. Annotate the spec '
        'with @DeleteColumn or @RenameColumn:\n'
        "  @DeleteColumn(tableName: '$tableName', columnName: '$columnName')\n"
        "  @RenameColumn(tableName: '$tableName', fromColumnName: "
        "'$columnName', toColumnName: <new name>)";
  }

  String _failurePrefix() => _specName == null
      ? 'AutoMigration failure: Add a spec extending AutoMigrationSpec to '
          'the AutoMigration. '
      : 'AutoMigration failure in $_specName: ';
}
