import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:froom_annotation/froom_annotation.dart' as annotations;
import 'package:froom_generator/misc/constants.dart';
import 'package:froom_generator/misc/schema_store.dart';
import 'package:froom_generator/misc/type_utils.dart';
import 'package:froom_generator/processor/schema_differ.dart';
import 'package:froom_generator/value_object/auto_migration.dart';
import 'package:froom_generator/value_object/schema.dart';
import 'package:source_gen/source_gen.dart';

/// Processes the automatic migrations of a database, comparing the schema
/// of the current version, [_currentSchema], with the exported schemas of
/// the [_schemaStore].
class AutoMigrationProcessor {
  final ClassElement _classElement;
  final DatabaseSchema _currentSchema;
  final SchemaStore _schemaStore;

  /// Whether the schema of the database is exported.
  final bool _exportsSchema;

  AutoMigrationProcessor(
    this._classElement,
    this._currentSchema,
    this._schemaStore,
    this._exportsSchema,
  );

  List<AutoMigration> process() {
    final autoMigrations = _classElement
            .getAnnotation(annotations.Database)
            ?.getField(AnnotationField.databaseAutoMigrations)
            ?.toListValue() ??
        [];
    if (autoMigrations.isEmpty) return [];

    if (!_exportsSchema) {
      throw InvalidGenerationSourceError(
        'Automatic migrations require the exported schemas of the database.',
        todo: 'Remove exportSchema: false from @Database.',
        element: _classElement,
      );
    }

    return autoMigrations.map(_processAutoMigration).toList();
  }

  AutoMigration _processAutoMigration(final DartObject autoMigration) {
    final from = autoMigration.getField(AutoMigrationField.from)!.toIntValue()!;
    final to = autoMigration.getField(AutoMigrationField.to)!.toIntValue()!;
    if (from < 1 || from >= to || to > _currentSchema.version) {
      throw InvalidGenerationSourceError(
        'The automatic migration from version $from to $to is invalid.',
        todo: 'Migrate from a lower to a higher version, up to the version of '
            'the database, ${_currentSchema.version}.',
        element: _classElement,
      );
    }

    final specElement = autoMigration
        .getField(AutoMigrationField.spec)
        ?.toTypeValue()
        ?.element;
    if (specElement != null && specElement is! ClassElement) {
      throw InvalidGenerationSourceError(
        'The spec of the automatic migration from version $from to $to is '
        'not a class.',
        element: _classElement,
      );
    }
    final spec = specElement as ClassElement?;
    final isSpecProvided = spec?.hasAnnotation(
          annotations.providedAutoMigrationSpec.runtimeType,
        ) ??
        false;
    if (spec != null) _checkSpec(spec, isSpecProvided);

    final fromSchema = _readSchema(from);
    final toSchema = to == _currentSchema.version
        ? _currentSchema
        : _readSchema(to);

    try {
      final diff = SchemaDiffer(
        fromSchema,
        toSchema,
        specName: spec?.displayName,
        renamedTables: _getAnnotations(spec, annotations.RenameTable)
            .map((annotation) => RenamedTable(
                  annotation.getStringField(AutoMigrationField.fromTableName),
                  annotation.getStringField(AutoMigrationField.toTableName),
                ))
            .toList(),
        renamedColumns: _getAnnotations(spec, annotations.RenameColumn)
            .map((annotation) => RenamedColumn(
                  annotation.getStringField(AutoMigrationField.tableName),
                  annotation.getStringField(AutoMigrationField.fromColumnName),
                  annotation.getStringField(AutoMigrationField.toColumnName),
                ))
            .toList(),
        deletedTables: _getAnnotations(spec, annotations.DeleteTable)
            .map((annotation) => DeletedTable(
                  annotation.getStringField(AutoMigrationField.tableName),
                ))
            .toList(),
        deletedColumns: _getAnnotations(spec, annotations.DeleteColumn)
            .map((annotation) => DeletedColumn(
                  annotation.getStringField(AutoMigrationField.tableName),
                  annotation.getStringField(AutoMigrationField.columnName),
                ))
            .toList(),
      ).diffSchemas();
      return AutoMigration(from, to, spec, isSpecProvided, diff);
    } on SchemaDiffException catch (exception) {
      throw InvalidGenerationSourceError(
        'The automatic migration from version $from to $to failed: '
        '${exception.message}',
        element: spec ?? _classElement,
      );
    }
  }

  DatabaseSchema _readSchema(final int version) {
    final schema = _schemaStore.read(version);
    if (schema == null) {
      throw InvalidGenerationSourceError(
        'The schema of version $version of the database for the automatic '
        'migration is missing at ${_schemaStore.describe(version)}.',
        todo: 'The schema of each version is exported when generating the '
            'code of the database with that version. Commit the exported '
            'schemas.',
        element: _classElement,
      );
    }
    return schema;
  }

  void _checkSpec(final ClassElement spec, final bool isSpecProvided) {
    final extendsSpec = spec.allSupertypes
        .any((supertype) => supertype.element.name == 'AutoMigrationSpec');
    if (!extendsSpec) {
      throw InvalidGenerationSourceError(
        'The spec ${spec.displayName} of an automatic migration has to '
        'extend AutoMigrationSpec.',
        element: spec,
      );
    }
    if (isSpecProvided) return;

    final constructor = spec.unnamedConstructor;
    if (spec.isAbstract ||
        constructor == null ||
        constructor.formalParameters
            .any((parameter) => parameter.isRequired)) {
      throw InvalidGenerationSourceError(
        'The spec ${spec.displayName} of an automatic migration has to be '
        'created by its unnamed constructor without arguments.',
        todo: 'Add such a constructor or annotate the spec with '
            '@providedAutoMigrationSpec and pass it to the database builder '
            'with addAutoMigrationSpecs().',
        element: spec,
      );
    }
  }

  Iterable<DartObject> _getAnnotations(
    final ClassElement? spec,
    final Type type,
  ) {
    return spec?.getAnnotations(type) ?? const [];
  }
}

extension on DartObject {
  String getStringField(final String name) =>
      getField(name)!.toStringValue()!;
}
