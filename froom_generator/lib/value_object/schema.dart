import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:froom_generator/misc/extension/foreign_key_action_extension.dart';
import 'package:froom_generator/value_object/entity.dart';
import 'package:froom_generator/value_object/index.dart';
import 'package:froom_generator/value_object/view.dart';

/// The schema of a version of a database, which is exported to and read from
/// JSON files for generating automatic migrations, like Room's
/// `DatabaseBundle`.
class DatabaseSchema {
  /// The version of the JSON format.
  static const formatVersion = 1;

  final int version;
  final List<EntitySchema> entities;
  final List<ViewSchema> views;

  DatabaseSchema(this.version, this.entities, this.views);

  factory DatabaseSchema.fromJson(final Map<String, Object?> json) {
    final jsonFormatVersion = json['formatVersion'];
    if (jsonFormatVersion != formatVersion) {
      throw FormatException(
        'The schema format version $jsonFormatVersion is not supported by '
        'this version of froom_generator, which supports version '
        '$formatVersion.',
      );
    }
    final database = json['database'] as Map<String, Object?>;
    return DatabaseSchema(
      database['version'] as int,
      (database['entities'] as List<Object?>)
          .map((entity) => EntitySchema.fromJson(entity as Map<String, Object?>))
          .toList(),
      (database['views'] as List<Object?>)
          .map((view) => ViewSchema.fromJson(view as Map<String, Object?>))
          .toList(),
    );
  }

  Map<String, Object?> toJson() => {
        'formatVersion': formatVersion,
        'database': {
          'version': version,
          'entities': entities.map((entity) => entity.toJson()).toList(),
          'views': views.map((view) => view.toJson()).toList(),
        },
      };

  /// The JSON of the schema file.
  String toJsonString() =>
      '${const JsonEncoder.withIndent('  ').convert(toJson())}\n';

  late final Map<String, EntitySchema> entitiesByTableName =
      {for (final entity in entities) entity.tableName: entity};
}

/// The schema of a table.
class EntitySchema {
  /// The placeholder for the table name in [createSql] and the statements of
  /// [indices].
  static const tableNamePlaceholder = r'${TABLE_NAME}';

  final String tableName;

  /// The statement creating the table, with [tableNamePlaceholder] as name.
  final String createSql;
  final List<FieldSchema> fields;
  final PrimaryKeySchema primaryKey;
  final List<IndexSchema> indices;
  final List<ForeignKeySchema> foreignKeys;
  final bool withoutRowid;

  /// The `USING` clause and options of virtual FTS tables, null for other
  /// tables.
  final String? fts;

  EntitySchema(
    this.tableName,
    this.createSql,
    this.fields,
    this.primaryKey,
    this.indices,
    this.foreignKeys,
    this.withoutRowid,
    this.fts,
  );

  factory EntitySchema.fromEntity(final Entity entity) {
    final tableName = entity.name;
    return EntitySchema(
      tableName,
      entity
          .getCreateTableStatement()
          .replaceFirst('`$tableName`', '`$tableNamePlaceholder`'),
      entity.fields
          .map((field) => FieldSchema(
                field.columnName,
                field.sqlType,
                !field.isNullable,
                field.defaultValue,
              ))
          .toList(),
      PrimaryKeySchema(
        entity.primaryKey.fields.map((field) => field.columnName).toList(),
        entity.primaryKey.autoGenerateId,
      ),
      entity.indices.map(IndexSchema.fromIndex).toList(),
      entity.foreignKeys
          .map((foreignKey) => ForeignKeySchema(
                foreignKey.parentName,
                foreignKey.childColumns,
                foreignKey.parentColumns,
                foreignKey.onUpdate.toSql(),
                foreignKey.onDelete.toSql(),
              ))
          .toList(),
      entity.withoutRowid,
      _getFts(entity),
    );
  }

  static String? _getFts(final Entity entity) {
    final fts = entity.fts;
    if (fts == null) return null;
    final options = fts.tableCreateOption();
    return options.isEmpty ? fts.usingOption : '${fts.usingOption} $options';
  }

  factory EntitySchema.fromJson(final Map<String, Object?> json) {
    return EntitySchema(
      json['tableName'] as String,
      json['createSql'] as String,
      (json['fields'] as List<Object?>)
          .map((field) => FieldSchema.fromJson(field as Map<String, Object?>))
          .toList(),
      PrimaryKeySchema.fromJson(json['primaryKey'] as Map<String, Object?>),
      (json['indices'] as List<Object?>)
          .map((index) => IndexSchema.fromJson(index as Map<String, Object?>))
          .toList(),
      (json['foreignKeys'] as List<Object?>)
          .map((foreignKey) =>
              ForeignKeySchema.fromJson(foreignKey as Map<String, Object?>))
          .toList(),
      json['withoutRowid'] as bool,
      json['fts'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
        'tableName': tableName,
        'createSql': createSql,
        'fields': fields.map((field) => field.toJson()).toList(),
        'primaryKey': primaryKey.toJson(),
        'indices': indices.map((index) => index.toJson()).toList(),
        'foreignKeys':
            foreignKeys.map((foreignKey) => foreignKey.toJson()).toList(),
        'withoutRowid': withoutRowid,
        'fts': fts,
      };

  bool get isFts => fts != null;

  /// Whether the table has an `INTEGER PRIMARY KEY` column, which is an
  /// alias of the row id and therefore never NULL.
  bool get hasRowidAlias =>
      !isFts &&
      !withoutRowid &&
      primaryKey.columnNames.length == 1 &&
      fieldsByColumnName[primaryKey.columnNames.single]?.affinity == 'INTEGER';

  bool isRowidAlias(final String columnName) =>
      hasRowidAlias && primaryKey.columnNames.single == columnName;

  /// Whether SQLite rejects NULL for the column [columnName], which is NOT
  /// NULL or a primary key of a `WITHOUT ROWID` table, except in FTS tables,
  /// which ignore NOT NULL, and for row ids, which replace NULL by a new row
  /// id.
  bool enforcesNotNull(final String columnName) =>
      (fieldsByColumnName[columnName]!.notNull ||
          withoutRowid && primaryKey.columnNames.contains(columnName)) &&
      !isFts &&
      !isRowidAlias(columnName);

  /// The prefix of the names of tables while recreating or renaming them.
  static const newTableNamePrefix = '_new_';

  /// The name of the table while recreating or renaming it, like Room.
  String get newTableName => '$newTableNamePrefix$tableName';

  late final Map<String, FieldSchema> fieldsByColumnName =
      {for (final field in fields) field.columnName: field};

  /// The statement creating the table named [name].
  String createTable(final String name) =>
      createSql.replaceFirst(tableNamePlaceholder, name);

  /// The statements creating the indices of the table.
  List<String> createIndices() => indices
      .map((index) => index.createSql.replaceFirst(tableNamePlaceholder, tableName))
      .toList();
}

/// The schema of a column.
class FieldSchema {
  final String columnName;
  final String affinity;
  final bool notNull;
  final String? defaultValue;

  FieldSchema(this.columnName, this.affinity, this.notNull, this.defaultValue);

  factory FieldSchema.fromJson(final Map<String, Object?> json) {
    return FieldSchema(
      json['columnName'] as String,
      json['affinity'] as String,
      json['notNull'] as bool,
      json['defaultValue'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
        'columnName': columnName,
        'affinity': affinity,
        'notNull': notNull,
        'defaultValue': defaultValue,
      };

  bool isSchemaEqual(final FieldSchema other) =>
      columnName == other.columnName &&
      affinity == other.affinity &&
      notNull == other.notNull &&
      defaultValue == other.defaultValue;
}

/// The schema of a primary key.
class PrimaryKeySchema {
  final List<String> columnNames;
  final bool autoGenerate;

  PrimaryKeySchema(this.columnNames, this.autoGenerate);

  factory PrimaryKeySchema.fromJson(final Map<String, Object?> json) {
    return PrimaryKeySchema(
      (json['columnNames'] as List<Object?>).cast<String>(),
      json['autoGenerate'] as bool,
    );
  }

  Map<String, Object?> toJson() => {
        'columnNames': columnNames,
        'autoGenerate': autoGenerate,
      };

  bool isSchemaEqual(final PrimaryKeySchema other) =>
      const ListEquality<String>().equals(columnNames, other.columnNames) &&
      autoGenerate == other.autoGenerate;
}

/// The schema of an index.
class IndexSchema {
  final String name;
  final bool unique;
  final List<String> columnNames;

  /// The statement creating the index, with
  /// [EntitySchema.tableNamePlaceholder] as table name.
  final String createSql;

  IndexSchema(this.name, this.unique, this.columnNames, this.createSql);

  factory IndexSchema.fromIndex(final Index index) {
    return IndexSchema(
      index.name,
      index.unique,
      index.columnNames,
      index.createQuery().replaceFirst(
            ' ON `${index.tableName}` ',
            ' ON `${EntitySchema.tableNamePlaceholder}` ',
          ),
    );
  }

  factory IndexSchema.fromJson(final Map<String, Object?> json) {
    return IndexSchema(
      json['name'] as String,
      json['unique'] as bool,
      (json['columnNames'] as List<Object?>).cast<String>(),
      json['createSql'] as String,
    );
  }

  Map<String, Object?> toJson() => {
        'name': name,
        'unique': unique,
        'columnNames': columnNames,
        'createSql': createSql,
      };

  bool isSchemaEqual(final IndexSchema other) =>
      name == other.name && createSql == other.createSql;
}

/// The schema of a foreign key.
class ForeignKeySchema {
  final String table;
  final List<String> columns;
  final List<String> referencedColumns;
  final String onUpdate;
  final String onDelete;

  ForeignKeySchema(
    this.table,
    this.columns,
    this.referencedColumns,
    this.onUpdate,
    this.onDelete,
  );

  factory ForeignKeySchema.fromJson(final Map<String, Object?> json) {
    return ForeignKeySchema(
      json['table'] as String,
      (json['columns'] as List<Object?>).cast<String>(),
      (json['referencedColumns'] as List<Object?>).cast<String>(),
      json['onUpdate'] as String,
      json['onDelete'] as String,
    );
  }

  Map<String, Object?> toJson() => {
        'table': table,
        'columns': columns,
        'referencedColumns': referencedColumns,
        'onUpdate': onUpdate,
        'onDelete': onDelete,
      };

  bool isSchemaEqual(final ForeignKeySchema other) =>
      table == other.table &&
      const ListEquality<String>().equals(columns, other.columns) &&
      const ListEquality<String>()
          .equals(referencedColumns, other.referencedColumns) &&
      onUpdate == other.onUpdate &&
      onDelete == other.onDelete;
}

/// The schema of a view.
class ViewSchema {
  final String viewName;
  final String createSql;

  ViewSchema(this.viewName, this.createSql);

  factory ViewSchema.fromView(final View view) =>
      ViewSchema(view.name, view.getCreateViewStatement());

  factory ViewSchema.fromJson(final Map<String, Object?> json) {
    return ViewSchema(json['viewName'] as String, json['createSql'] as String);
  }

  Map<String, Object?> toJson() => {
        'viewName': viewName,
        'createSql': createSql,
      };
}
