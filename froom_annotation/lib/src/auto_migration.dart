/// Declares an automatic migration of a [Database] from the schema version
/// [from] to [to], like Room's `@AutoMigration`.
///
/// Froom detects the changes between the schemas of both versions, which it
/// exports to the schema directory when generating the code, and generates a
/// migration performing them. Commit the exported schema files, as they are
/// required to generate the migrations of later versions.
///
/// Deleted or renamed tables and columns can't be distinguished from each
/// other, so they have to be declared on a [spec] class annotated with
/// [RenameTable], [RenameColumn], [DeleteTable] or [DeleteColumn]. Its
/// `onPostMigrate` method is called after the automatic migration, e.g. for
/// migrating data.
///
/// ```dart
/// @Database(
///   version: 3,
///   entities: [Song, Artist],
///   autoMigrations: [
///     AutoMigration(from: 1, to: 2),
///     AutoMigration(from: 2, to: 3, spec: MusicAutoMigrationSpec),
///   ],
/// )
/// abstract class MusicDatabase extends FroomDatabase {}
///
/// @DeleteTable(tableName: 'Album')
/// @RenameTable(fromTableName: 'Singer', toTableName: 'Artist')
/// @RenameColumn(
///   tableName: 'Song',
///   fromColumnName: 'songName',
///   toColumnName: 'songTitle',
/// )
/// @DeleteColumn(tableName: 'Song', columnName: 'genre')
/// class MusicAutoMigrationSpec extends AutoMigrationSpec {}
/// ```
class AutoMigration {
  /// The version of the database schema to migrate from.
  final int from;

  /// The version of the database schema to migrate to.
  final int to;

  /// The class extending `AutoMigrationSpec`, which declares renamed and
  /// deleted tables and columns.
  final Type? spec;

  /// Declares an automatic migration.
  const AutoMigration({required this.from, required this.to, this.spec});
}

/// Declares a table renamed in the [AutoMigration.to] version on the spec of
/// an [AutoMigration].
class RenameTable {
  /// The name of the table in the [AutoMigration.from] version.
  final String fromTableName;

  /// The name of the table in the [AutoMigration.to] version.
  final String toTableName;

  /// Declares a renamed table.
  const RenameTable({required this.fromTableName, required this.toTableName});
}

/// Declares a column renamed in the [AutoMigration.to] version on the spec
/// of an [AutoMigration].
class RenameColumn {
  /// The name of the table of the column in the [AutoMigration.from]
  /// version.
  final String tableName;

  /// The name of the column in the [AutoMigration.from] version.
  final String fromColumnName;

  /// The name of the column in the [AutoMigration.to] version.
  final String toColumnName;

  /// Declares a renamed column.
  const RenameColumn({
    required this.tableName,
    required this.fromColumnName,
    required this.toColumnName,
  });
}

/// Declares a table deleted in the [AutoMigration.to] version on the spec of
/// an [AutoMigration].
class DeleteTable {
  /// The name of the table in the [AutoMigration.from] version.
  final String tableName;

  /// Declares a deleted table.
  const DeleteTable({required this.tableName});
}

/// Declares a column deleted in the [AutoMigration.to] version on the spec
/// of an [AutoMigration].
class DeleteColumn {
  /// The name of the table of the column in the [AutoMigration.from]
  /// version.
  final String tableName;

  /// The name of the column in the [AutoMigration.from] version.
  final String columnName;

  /// Declares a deleted column.
  const DeleteColumn({required this.tableName, required this.columnName});
}

class _ProvidedAutoMigrationSpec {
  const _ProvidedAutoMigrationSpec();
}

/// Marks the spec of an [AutoMigration] as provided at runtime with
/// `addAutoMigrationSpecs()` of the database builder, e.g. for passing
/// dependencies, instead of being created by its unnamed constructor.
const providedAutoMigrationSpec = _ProvidedAutoMigrationSpec();
