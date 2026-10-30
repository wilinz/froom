/// Declares an index on an Entity.
/// see: <a href="https://sqlite.org/lang_createindex.html">SQLite Index Documentation</a>
class Index {
  /// Name of the index.
  ///
  /// If not set, froom will set it to the list of columns joined by '_' and
  /// prefixed by 'index_$tableName'. So if you have a table with name "Foo"
  /// and with an index of {"bar", "baz"}, generated index name will be
  /// 'index_Foo_bar_baz'. If you need to specify the index in a query, you
  /// should never rely on this name, instead, specify a name for your index.
  final String? name;

  /// If set to true, this will be a unique index and any duplicates will be
  /// rejected.
  final bool unique;

  /// List of column names in the Index.
  ///
  /// Entries which aren't column names of the entity, like `'lower(email)'`,
  /// are indexed as [expressions](https://www.sqlite.org/expridx.html).
  ///
  /// The order of columns is important as it defines when SQLite can use a
  /// particular index.
  /// See <a href="https://www.sqlite.org/optoverview.html">SQLite documentation</a>
  /// for details on index usage in the query optimizer.
  final List<String> value;

  /// The SQL expression of a partial index, which only indexes rows the
  /// expression is true for, e.g. `'email IS NOT NULL'` for a [unique] index
  /// allowing multiple rows without an email.
  /// See <a href="https://www.sqlite.org/partialindex.html">SQLite documentation</a>.
  final String? where;

  /// Declares an index on an Entity.
  ///
  /// Is not [unique] by default.
  const Index({
    this.name,
    this.unique = false,
    required this.value,
    this.where,
  });
}
