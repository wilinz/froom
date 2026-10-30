import 'dart:async';

import 'package:sqflite_common/sqlite_api.dart' as sqflite;

/// The spec of an `AutoMigration`, like Room's `AutoMigrationSpec`.
///
/// Annotate subclasses with `@RenameTable`, `@RenameColumn`, `@DeleteTable`
/// or `@DeleteColumn` to declare renamed and deleted tables and columns.
abstract class AutoMigrationSpec {
  /// Called within the transaction of the migration after the automatic
  /// migration, e.g. for migrating data.
  FutureOr<void> onPostMigrate(final sqflite.Database database) {}
}
