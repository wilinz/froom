/// Exception thrown when SQL parsing fails.
class SqlParseException implements Exception {
  /// The SQL query that failed to parse.
  final String sql;

  /// Creates a new SQL parse exception with the given SQL query.
  const SqlParseException(this.sql);

  @override
  String toString() => 'Failed to parse "$sql"';
}