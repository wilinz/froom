import 'package:collection/collection.dart';

class Index {
  final String name;
  final String tableName;
  final bool unique;
  final List<String> columnNames;

  /// The expression of a partial index.
  final String? where;

  Index(
    this.name,
    this.tableName,
    this.unique,
    this.columnNames, {
    this.where,
  });

  String createQuery() {
    final uniqueSql = unique ? ' UNIQUE' : '';
    final escapedColumnNames =
        columnNames.map((columnName) => '`$columnName`').join(', ');

    final whereSql = where != null ? ' WHERE $where' : '';

    return 'CREATE$uniqueSql INDEX IF NOT EXISTS `$name`'
        ' ON `$tableName` ($escapedColumnNames)$whereSql';
  }

  static const defaultPrefix = 'index_';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Index &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          tableName == other.tableName &&
          unique == other.unique &&
          const ListEquality<String>().equals(columnNames, other.columnNames) &&
          where == other.where;

  @override
  int get hashCode =>
      name.hashCode ^
      tableName.hashCode ^
      unique.hashCode ^
      columnNames.hashCode ^
      where.hashCode;

  @override
  String toString() {
    return 'Index{name: $name, tableName: $tableName, unique: $unique, columnNames: $columnNames, where: $where}';
  }
}
