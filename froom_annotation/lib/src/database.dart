import 'package:froom_annotation/src/auto_migration.dart';

/// Marks a class as a FroomDatabase.
class Database {
  /// The database version.
  final int version;

  /// The entities the database manages.
  final List<Type> entities;

  /// The views the database manages.
  final List<Type> views;

  /// The automatic migrations between versions of the database.
  final List<AutoMigration> autoMigrations;

  /// Whether to export the schema of the database to the schema directory,
  /// which [autoMigrations] require.
  ///
  /// The schema of each version is exported to
  /// `<schema directory>/<path of the library>/<database class>/<version>.json`.
  /// The schema directory is `froom_schemas` by default and can be configured
  /// by the `schema_location` option of the froom builder in `build.yaml`.
  /// By default, it's only exported when there are [autoMigrations]. Enable
  /// it before adding the first automatic migration, so that the schema of
  /// the version to migrate from is available.
  final bool? exportSchema;

  /// Marks a class as a FroomDatabase.
  const Database({
    required this.version,
    required this.entities,
    this.views = const [],
    this.autoMigrations = const [],
    this.exportSchema,
  });
}
