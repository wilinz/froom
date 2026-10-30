import 'package:analyzer/dart/element/element.dart';
import 'package:froom_generator/value_object/schema.dart';

/// An automatic migration of the database from the schema version [from] to
/// [to], performing the changes of [diff].
class AutoMigration {
  final int from;
  final int to;

  /// The class extending `AutoMigrationSpec`, if any.
  final ClassElement? spec;

  /// Whether the [spec] is provided by the database builder instead of
  /// being created by its unnamed constructor.
  final bool isSpecProvided;
  final SchemaDiff diff;

  AutoMigration(
    this.from,
    this.to,
    this.spec,
    this.isSpecProvided,
    this.diff,
  );
}

/// The changes between two schema versions.
class SchemaDiff {
  final List<EntitySchema> addedTables;

  /// The tables which are only renamed, by their old names.
  final Map<String, String> renamedTables;
  final List<String> deletedTables;

  /// The columns added to tables without complex changes.
  final List<AddedColumn> addedColumns;

  /// The tables which have to be recreated.
  final List<ComplexChangedTable> complexChangedTables;

  /// The changed indices of tables which aren't recreated.
  final List<IndexChange> indexChanges;
  final List<ViewSchema> fromViews;
  final List<ViewSchema> toViews;

  SchemaDiff({
    required this.addedTables,
    required this.renamedTables,
    required this.deletedTables,
    required this.addedColumns,
    required this.complexChangedTables,
    this.indexChanges = const [],
    required this.fromViews,
    required this.toViews,
  });
}

/// A table with changes which SQLite can't alter, so that it's recreated.
class ComplexChangedTable {
  final EntitySchema fromTable;
  final EntitySchema toTable;

  /// The columns of [fromTable] the data of the columns of [toTable] is
  /// copied from, by the names of the columns of [toTable]. New columns get
  /// their default values.
  final Map<String, String> columnSources;

  /// The values replacing NULL when copying the columns which became NOT
  /// NULL, by the names of the columns of [toTable].
  final Map<String, String> nullReplacements = {};

  ComplexChangedTable(this.fromTable, this.toTable, this.columnSources);
}

/// The indices of a table to drop and create, by their names and statements.
class IndexChange {
  final List<String> droppedIndices;
  final List<String> createdIndices;

  IndexChange(this.droppedIndices, this.createdIndices);
}

class AddedColumn {
  final String tableName;
  final FieldSchema field;

  AddedColumn(this.tableName, this.field);
}

class RenamedTable {
  final String fromTableName;
  final String toTableName;

  RenamedTable(this.fromTableName, this.toTableName);
}

class RenamedColumn {
  final String tableName;
  final String fromColumnName;
  final String toColumnName;

  RenamedColumn(this.tableName, this.fromColumnName, this.toColumnName);
}

class DeletedTable {
  final String tableName;

  DeletedTable(this.tableName);
}

class DeletedColumn {
  final String tableName;
  final String columnName;

  DeletedColumn(this.tableName, this.columnName);
}
