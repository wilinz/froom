/// Marks an Entity annotated class as an FTS3 entity.
/// This class will have a mapping SQLite FTS3 table in the database.
class Fts3 {
  /// The tokenizer to be used in the FTS table.
  /// The default value is [FtsTokenizer.simple]. Tokenizer arguments can be defined
  /// with [tokenizerArgs].
  ///
  /// The tokenizer to use on the FTS table. Built-in available tokenizers are
  /// [FtsTokenizer.simple],[FtsTokenizer.porter] and [FtsTokenizer.unicode61].
  ///
  /// [SQLite tokenizers documentation](https://www.sqlite.org/fts3.html#tokenizer)
  final String tokenizer;

  /// Optional arguments to configure the defined tokenizer.
  ///
  /// Tokenizer arguments consist of an argument name, followed by an "=" character, followed by
  /// the option value. For example, `separators=.` defines the dot character as an
  /// additional separator when using the [FtsTokenizer.unicode61] tokenizer.
  ///
  /// The available arguments that can be defined depend on the tokenizer defined, see the
  /// [SQLite tokenizers documentation](https://www.sqlite.org/fts3.html#tokenizer) for
  /// details.
  ///
  /// A list of tokenizer arguments strings.
  final List<String> tokenizerArgs;

  /// Creates an [Fts3] constant which can be used to mark an Entity annotated
  /// class as an FTS3 entity.
  const Fts3({
    this.tokenizer = FtsTokenizer.simple,
    this.tokenizerArgs = const [],
  });
}

/// Marks an Entity annotated class as an FTS3 entity.
/// This class will have a mapping SQLite FTS3 table in the database.
///
/// It uses the [FtsTokenizer.simple] with no additional [Fts3.tokenizerArgs].
const fts3 = Fts3();

/// Marks an Entity annotated class as an FTS4 entity.
/// This class will have a mapping SQLite FTS4 table in the database.
class Fts4 {
  /// The tokenizer to be used in the FTS table.
  /// The default value is [FtsTokenizer.simple]. Tokenizer arguments can be defined
  /// with [tokenizerArgs].
  ///
  /// The tokenizer to use on the FTS table. Built-in available tokenizers are
  /// [FtsTokenizer.simple],[FtsTokenizer.porter] and [FtsTokenizer.unicode61].
  ///
  /// [SQLite tokenizers documentation](https://www.sqlite.org/fts3.html#tokenizer)
  final String tokenizer;

  /// Optional arguments to configure the defined tokenizer.
  ///
  /// Tokenizer arguments consist of an argument name, followed by an "=" character, followed by
  /// the option value. For example, `separators=.` defines the dot character as an
  /// additional separator when using the [FtsTokenizer.unicode61] tokenizer.
  ///
  /// The available arguments that can be defined depend on the tokenizer defined, see the
  /// [SQLite tokenizers documentation](https://www.sqlite.org/fts3.html#tokenizer) for
  /// details.
  ///
  /// A list of tokenizer arguments strings.
  final List<String> tokenizerArgs;

  /// Creates an [Fts4] constant which can be used to mark an Entity annotated
  /// class as an FTS4 entity.
  const Fts4({
    this.tokenizer = FtsTokenizer.simple,
    this.tokenizerArgs = const [],
  });
}

/// Marks an Entity annotated class as an FTS4 entity.
/// This class will have a mapping SQLite FTS4 table in the database.
///
/// It uses the [FtsTokenizer.simple] with no additional [Fts4.tokenizerArgs].
const fts4 = Fts4();

/// Marks an Entity annotated class as an FTS5 entity.
/// This class will have a mapping SQLite FTS5 table in the database.
///
/// Unlike FTS3 and FTS4, FTS5 is supported by the SQLite builds bundled by
/// `package:sqlite3`, including the encrypted ones. The SQLite of Android
/// used by the sqflite plugin lacks it, though, so FTS5 entities require the
/// FFI database factory there.
///
/// The primary key of the entity has to be an integer field of the column
/// `rowid`, which is the row id of the table. As `SELECT *` doesn't return the
/// row id of FTS5 tables, queries of the entity have to select it explicitly,
/// e.g. `SELECT rowid, * FROM mail WHERE mail MATCH :query`.
///
/// [SQLite FTS5 documentation](https://www.sqlite.org/fts5.html)
class Fts5 {
  /// The tokenizer to be used in the FTS table.
  /// The default value is [FtsTokenizer.unicode61]. Tokenizer arguments can be
  /// defined with [tokenizerArgs].
  ///
  /// The built-in tokenizers of FTS5 are [FtsTokenizer.unicode61],
  /// [FtsTokenizer.ascii], [FtsTokenizer.porter] and [FtsTokenizer.trigram].
  ///
  /// [SQLite FTS5 tokenizers documentation](https://www.sqlite.org/fts5.html#tokenizers)
  final String tokenizer;

  /// Optional arguments to configure the defined tokenizer.
  ///
  /// Each argument is an item of the list, e.g. `remove_diacritics` and `2`
  /// or `tokenchars` and `-_` for the [FtsTokenizer.unicode61] tokenizer, or
  /// the tokenizer wrapped by the [FtsTokenizer.porter] tokenizer, e.g.
  /// `unicode61`. Arguments which aren't words are quoted.
  final List<String> tokenizerArgs;

  /// The lengths of prefixes to index for faster prefix queries, e.g. `[2, 3]`.
  ///
  /// [SQLite FTS5 prefix indexes documentation](https://www.sqlite.org/fts5.html#prefix_indexes)
  final List<int> prefixes;

  /// The names of the columns which are stored but not indexed for full-text
  /// queries.
  final List<String> notIndexed;

  /// Creates an [Fts5] constant which can be used to mark an Entity annotated
  /// class as an FTS5 entity.
  const Fts5({
    this.tokenizer = FtsTokenizer.unicode61,
    this.tokenizerArgs = const [],
    this.prefixes = const [],
    this.notIndexed = const [],
  });
}

/// Marks an Entity annotated class as an FTS5 entity.
/// This class will have a mapping SQLite FTS5 table in the database.
///
/// It uses the [FtsTokenizer.unicode61] with no additional
/// [Fts5.tokenizerArgs].
const fts5 = Fts5();

/// Available option values that can be used with [Fts3], [Fts4] & [Fts5].
abstract class FtsTokenizer {
  /// The name of the default tokenizer used on FTS tables.
  ///
  /// [Fts3.tokenizer]
  /// [Fts4.tokenizer]
  static const simple = 'simple';

  /// The name of the tokenizer based on the Porter Stemming Algorithm.
  ///
  /// [Fts3.tokenizer]
  /// [Fts4.tokenizer]
  static const porter = 'porter';

  /// The name of a tokenizer implemented by the ICU library.
  /// Not available in certain Android builds (e.g. vendor).
  ///
  /// [Fts3.tokenizer]
  /// [Fts4.tokenizer]
  static const icu = 'icu';

  /// The name of the tokenizer that extends the [simple] tokenizer
  /// according to rules in Unicode Version 6.1.
  ///
  /// [Fts3.tokenizer]
  /// [Fts4.tokenizer]
  static const unicode61 = 'unicode61';

  /// The name of the FTS5 tokenizer which only treats ASCII characters other
  /// than letters and digits as separators.
  ///
  /// [Fts5.tokenizer]
  static const ascii = 'ascii';

  /// The name of the FTS5 tokenizer which indexes all sequences of three
  /// characters, supporting substring queries.
  ///
  /// [Fts5.tokenizer]
  static const trigram = 'trigram';
}
