import 'package:code_builder/code_builder.dart';
import 'package:froom_generator/misc/extension/string_extension.dart';
import 'package:froom_generator/value_object/auto_migration.dart';
import 'package:froom_generator/value_object/schema.dart';

/// Writes the [Migration] performing an automatic migration, like Room's
/// `AutoMigrationWriter`.
class AutoMigrationWriter {
  final AutoMigration _autoMigration;

  AutoMigrationWriter(this._autoMigration);

  /// The expression creating the migration, which may refer to the provided
  /// `autoMigrationSpecs`.
  Code write() {
    final statements = getStatements()
        .map((statement) => 'await database.execute(${statement.toLiteral()});')
        .join('\n');
    return Code('''
      Migration(${_autoMigration.from}, ${_autoMigration.to}, (database) async {
        $statements
        ${_writeSpecCall()}
      })''');
  }

  String _writeSpecCall() {
    final spec = _autoMigration.spec;
    if (spec == null) return '';

    // typed as AutoMigrationSpec, as overrides may return void
    final specName = spec.displayName;
    if (!_autoMigration.isSpecProvided) {
      return '''
        final AutoMigrationSpec spec = $specName();
        await spec.onPostMigrate(database);''';
    }
    return '''
      final AutoMigrationSpec? spec = autoMigrationSpecs.whereType<$specName>().firstOrNull;
      if (spec == null) {
        throw StateError('The spec $specName of the automatic migration from version ${_autoMigration.from} to ${_autoMigration.to} has to be passed to addAutoMigrationSpecs() of the database builder.');
      }
      await spec.onPostMigrate(database);''';
  }

  /// The SQL statements migrating the database.
  ///
  /// Renamed and recreated tables are moved to temporary names before
  /// getting their new names, so that their old names can be taken by other
  /// tables regardless of their order.
  List<String> getStatements() {
    final diff = _autoMigration.diff;
    // FTS tables are recreated last, as they can be based on other tables
    final recreatedTables = [
      ...diff.complexChangedTables.where((table) => !table.toTable.isFts),
      ...diff.complexChangedTables.where((table) => table.toTable.isFts),
    ];
    final movedTableNames = [
      ...diff.renamedTables.values,
      ...recreatedTables.map((table) => table.toTable.tableName),
    ];

    return [
      // views can refer to any changed table
      for (final view in diff.fromViews)
        'DROP VIEW IF EXISTS `${view.viewName}`',
      for (final tableName in diff.deletedTables) 'DROP TABLE `$tableName`',
      for (final entry in diff.renamedTables.entries)
        _rename(entry.key, '${EntitySchema.newTableNamePrefix}${entry.value}'),
      for (final table in recreatedTables) ..._getRecreateTableStatements(table),
      for (final tableName in movedTableNames)
        _rename('${EntitySchema.newTableNamePrefix}$tableName', tableName),
      for (final indexChange in diff.indexChanges)
        for (final indexName in indexChange.droppedIndices)
          'DROP INDEX IF EXISTS `$indexName`',
      for (final addedColumn in diff.addedColumns)
        _getAddColumnStatement(addedColumn),
      for (final table in recreatedTables) ...table.toTable.createIndices(),
      for (final indexChange in diff.indexChanges)
        ...indexChange.createdIndices,
      for (final table in diff.addedTables) ...[
        table.createTable(table.tableName),
        ...table.createIndices(),
      ],
      for (final view in diff.toViews) view.createSql,
    ];
  }

  String _rename(final String fromTableName, final String toTableName) =>
      'ALTER TABLE `$fromTableName` RENAME TO `$toTableName`';

  String _getAddColumnStatement(final AddedColumn addedColumn) {
    final field = addedColumn.field;
    final notNull = field.notNull ? ' NOT NULL' : '';
    // NOT NULL columns always have a default value
    final defaultValue =
        field.defaultValue == null ? '' : ' DEFAULT ${field.defaultValue}';
    return 'ALTER TABLE `${addedColumn.tableName}` ADD COLUMN '
        '`${field.columnName}` ${field.affinity}$notNull$defaultValue';
  }

  /// Recreates the table with its new schema, as SQLite can't alter it, see
  /// https://www.sqlite.org/lang_altertable.html#otheralter.
  List<String> _getRecreateTableStatements(final ComplexChangedTable table) {
    final fromTable = table.fromTable;
    final toTable = table.toTable;

    // the columns of the new table with data in the old one
    final columns = table.columnSources.keys.toList();
    final selectedColumns = columns.map((column) => table.columnSources[column]!);
    String escape(final Iterable<String> columns) =>
        columns.map((column) => '`$column`').join(', ');

    final copyStatement =
        'INSERT INTO `${toTable.newTableName}` (${escape(columns)}) '
        'SELECT ${escape(selectedColumns)} FROM `${fromTable.tableName}`';
    // renamed to the name of the new table with the other moved tables
    return [
      toTable.createTable(toTable.newTableName),
      // e.g. not if all old columns were deleted
      if (columns.isNotEmpty) copyStatement,
      'DROP TABLE `${fromTable.tableName}`',
    ];
  }
}

extension AutoMigrationsWriter on List<AutoMigration> {
  /// The expression of the list of migrations.
  Code writeList() {
    final migrations =
        map((autoMigration) => AutoMigrationWriter(autoMigration).write());
    return Code('[${migrations.map((code) => '$code,').join('\n')}]');
  }

  bool get hasProvidedSpecs =>
      any((autoMigration) => autoMigration.isSpecProvided);
}
