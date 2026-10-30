import 'package:froom_common/src/migration.dart';
import 'package:sqflite_common/sqlite_api.dart';

// ignore: avoid_classes_with_only_static_members
abstract class MigrationAdapter {
  /// Runs the given [migrations] for migrating the database schema and data.
  static Future<void> runMigrations(
    final Database migrationDatabase,
    final int startVersion,
    final int endVersion,
    final List<Migration> migrations,
  ) async {
    final migrationPath =
        _findMigrationPath(startVersion, endVersion, migrations);
    if (migrationPath == null) {
      throw StateError(
        'There is no migration supplied to update the database to the current version.'
        ' Aborting the migration.',
      );
    }

    for (final migration in migrationPath) {
      await migration.migrate(migrationDatabase);
    }
  }

  /// Whether opening the existing [database] runs migrations, as its version
  /// is lower than [version].
  ///
  /// Foreign keys stay disabled while migrating then, as they can't be
  /// toggled within the transaction of migrations, e.g. for recreating
  /// tables.
  static Future<bool> isUpgradePending(
    final Database database,
    final int version,
  ) async {
    final currentVersion = await database.getVersion();
    return currentVersion != 0 && currentVersion < version;
  }

  /// Checks that the migrations, which ran with foreign keys disabled, didn't
  /// violate them, as recommended by SQLite for schema changes.
  ///
  /// Throws within the transaction of the migrations, so that they get rolled
  /// back together with the database version.
  static Future<void> checkForeignKeys(final DatabaseExecutor database) async {
    final violations = await database.rawQuery('PRAGMA foreign_key_check');
    if (violations.isNotEmpty) {
      final tables = violations.map((violation) => violation['table']).toSet();
      throw StateError(
        'The migrations violated foreign keys of the tables ${tables.join(', ')}.',
      );
    }
  }

  /// Whether [migrations] migrate the database from [startVersion] to
  /// [endVersion].
  static bool hasMigrationPath(
    final int startVersion,
    final int endVersion,
    final List<Migration> migrations,
  ) {
    return _findMigrationPath(startVersion, endVersion, migrations) != null;
  }

  /// Returns consecutive [migrations] from [startVersion] to [endVersion],
  /// preferring the ones reaching the highest version like Room, or null if
  /// there are none.
  static List<Migration>? _findMigrationPath(
    final int startVersion,
    final int endVersion,
    final List<Migration> migrations,
  ) {
    // the migrations upwards from each version, highest end version first
    final migrationsByStartVersion = <int, List<Migration>>{};
    for (final migration in migrations) {
      if (migration.endVersion > migration.startVersion &&
          migration.endVersion <= endVersion) {
        migrationsByStartVersion
            .putIfAbsent(migration.startVersion, () => [])
            .add(migration);
      }
    }
    for (final versionMigrations in migrationsByStartVersion.values) {
      versionMigrations
          .sort((first, second) => second.endVersion.compareTo(first.endVersion));
    }

    // versions from which the end version can't be reached
    final deadEnds = <int>{};
    List<Migration>? findPath(final int version) {
      if (version == endVersion) return [];
      if (deadEnds.contains(version)) return null;

      for (final migration in migrationsByStartVersion[version] ?? const []) {
        final remainingPath = findPath(migration.endVersion);
        if (remainingPath != null) return [migration, ...remainingPath];
      }
      deadEnds.add(version);
      return null;
    }

    return findPath(startVersion);
  }

  /// Drops all tables and views of the [database], e.g. for a destructive
  /// migration. Foreign keys are only checked once the transaction gets
  /// committed.
  static Future<void> dropAllTables(final DatabaseExecutor database) async {
    await database.execute('PRAGMA defer_foreign_keys = TRUE');

    Future<List<Map<String, Object?>>> schemaObjects(final String type) {
      return database.rawQuery(
        "SELECT name, sql FROM sqlite_master WHERE type = ? AND name NOT LIKE 'sqlite\\_%' ESCAPE '\\' AND name != 'android_metadata'",
        [type],
      );
    }

    for (final view in await schemaObjects('view')) {
      await database.execute('DROP VIEW IF EXISTS `${view['name']}`');
    }

    // dropping virtual tables drops their shadow tables as well
    final tables = await schemaObjects('table');
    final virtualTables = tables.where((table) =>
        (table['sql'] as String?)
            ?.trimLeft()
            .toUpperCase()
            .startsWith('CREATE VIRTUAL TABLE') ??
        false);
    for (final table in virtualTables) {
      await database.execute('DROP TABLE IF EXISTS `${table['name']}`');
    }
    for (final table in await schemaObjects('table')) {
      await database.execute('DROP TABLE IF EXISTS `${table['name']}`');
    }
  }
}
