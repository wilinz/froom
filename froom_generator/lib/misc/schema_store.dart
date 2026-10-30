import 'dart:convert';
import 'dart:io';

import 'package:froom_generator/value_object/schema.dart';
import 'package:path/path.dart' as p;

/// Stores the schemas of the versions of a database.
abstract class SchemaStore {
  /// Returns the schema of [version], or null if it wasn't exported.
  DatabaseSchema? read(final int version);

  /// Exports the [schema] of its version.
  void write(final DatabaseSchema schema);

  /// Describes where the schema of [version] is stored, for error messages.
  String describe(final int version);
}

/// Stores the schemas as JSON files in a [directory], like Room's exported
/// schemas, which have to be committed for generating automatic migrations.
///
/// The files are accessed directly instead of as assets of the build, as
/// their paths depend on the version and they have to persist.
class FileSchemaStore implements SchemaStore {
  final String directory;

  FileSchemaStore(this.directory);

  /// The directory of the schemas of the database class [databaseName]
  /// declared in the library at [libraryPath] within [schemaLocation].
  factory FileSchemaStore.forDatabase(
    final String schemaLocation,
    final String libraryPath,
    final String databaseName,
  ) {
    return FileSchemaStore(p.join(
      schemaLocation,
      p.withoutExtension(libraryPath),
      databaseName,
    ));
  }

  File _file(final int version) => File(p.join(directory, '$version.json'));

  @override
  DatabaseSchema? read(final int version) {
    final file = _file(version);
    if (!file.existsSync()) return null;
    return DatabaseSchema.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, Object?>,
    );
  }

  @override
  void write(final DatabaseSchema schema) {
    final file = _file(schema.version);
    final json = schema.toJsonString();
    // keep the file untouched if it didn't change, e.g. for file watchers
    if (file.existsSync() && file.readAsStringSync() == json) return;
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(json);
  }

  @override
  String describe(final int version) => _file(version).path;
}
