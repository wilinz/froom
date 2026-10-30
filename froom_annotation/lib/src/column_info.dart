/// Allows customization of the column associated with this field.
class ColumnInfo {
  /// The custom name of the column.
  final String? name;

  /// The SQL default value of the column, like Room's `defaultValue`.
  ///
  /// It's used when a row gets inserted without a value for the column,
  /// e.g. by a `@Query` `INSERT` statement, a partial entity of `@Upsert` or
  /// when adding the column with `ALTER TABLE` in a migration. Inserting an
  /// entity always uses its field value instead.
  ///
  /// Values of `TEXT` columns are quoted, unless they are `NULL`,
  /// `CURRENT_TIME`, `CURRENT_DATE`, `CURRENT_TIMESTAMP`, `TRUE`, `FALSE` or
  /// expressions in parentheses. Surround them with single quotes to use them
  /// as strings. Values of other columns are used as given, e.g. `'0'`.
  ///
  /// ```dart
  /// @ColumnInfo(defaultValue: 'Guest')
  /// final String role;
  ///
  /// @ColumnInfo(defaultValue: 'CURRENT_TIMESTAMP')
  /// final String createdAt;
  ///
  /// @ColumnInfo(defaultValue: '0')
  /// final int count;
  /// ```
  final String? defaultValue;

  const ColumnInfo({this.name, this.defaultValue});
}
