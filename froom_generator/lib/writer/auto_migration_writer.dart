import 'package:code_builder/code_builder.dart';
import 'package:froom_generator/misc/extension/string_extension.dart';
import 'package:froom_generator/value_object/auto_migration.dart';

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
  List<String> getStatements() {
    final diff = _autoMigration.diff;
    return [
      // views can refer to any changed table
      for (final view in diff.fromViews)
        'DROP VIEW IF EXISTS `${view.viewName}`',
      for (final tableName in diff.deletedTables) 'DROP TABLE `$tableName`',
      for (final entry in diff.renamedTables.entries)
        'ALTER TABLE `${entry.key}` RENAME TO `${entry.value}`',
      for (final addedColumn in diff.addedColumns)
        _getAddColumnStatement(addedColumn),
      for (final table in diff.addedTables) ...[
        table.createTable(table.tableName),
        ...table.createIndices(),
      ],
      // FTS tables are recreated last, as they can be based on other tables
      for (final table in [
        ...diff.complexChangedTables.where((table) => !table.toTable.isFts),
        ...diff.complexChangedTables.where((table) => table.toTable.isFts),
      ])
        ..._getRecreateTableStatements(table),
      for (final view in diff.toViews) view.createSql,
    ];
  }

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
    return [
      toTable.createTable(toTable.newTableName),
      copyStatement,
      'DROP TABLE `${fromTable.tableName}`',
      'ALTER TABLE `${toTable.newTableName}` RENAME TO `${toTable.tableName}`',
      ...toTable.createIndices(),
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
