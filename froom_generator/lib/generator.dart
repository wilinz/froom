import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:froom_annotation/froom_annotation.dart' as annotations;
import 'package:froom_generator/misc/extension/iterable_extension.dart';
import 'package:froom_generator/misc/schema_store.dart';
import 'package:froom_generator/processor/database_processor.dart';
import 'package:froom_generator/value_object/database.dart';
import 'package:froom_generator/writer/auto_migration_writer.dart';
import 'package:froom_generator/writer/code_writer.dart';
import 'package:froom_generator/writer/dao_writer.dart';
import 'package:froom_generator/writer/database_builder_contract_writer.dart';
import 'package:froom_generator/writer/database_builder_writer.dart';
import 'package:froom_generator/writer/database_writer.dart';
import 'package:froom_generator/writer/type_converter_field_writer.dart';
import 'package:source_gen/source_gen.dart';

// The migration is complete
/// Froom generator that produces the implementation of the persistence code.
class FroomGenerator extends GeneratorForAnnotation<annotations.Database> {
  static const defaultSchemaLocation = 'froom_schemas';

  /// The directory the schemas of the databases are exported to.
  final String schemaLocation;

  FroomGenerator({this.schemaLocation = defaultSchemaLocation});
  @override
  FutureOr<String> generateForAnnotatedElement(
    final Element element,
    final ConstantReader annotation,
    final BuildStep buildStep,
  ) {
    final database = _getDatabase(element, buildStep);
    final hasProvidedAutoMigrationSpecs =
        database.autoMigrations.hasProvidedSpecs;

    final databaseClass = DatabaseWriter(database).write();
    final daoClasses = database.daoGetters
        .map((daoGetter) => daoGetter.dao)
        .map((dao) => DaoWriter(
              dao,
              database.streamEntities,
              database.hasViewStreams,
            ).write());
    final distinctTypeConverterFields = database.allTypeConverters
        .distinctBy((element) => element.name)
        .map((typeConverter) =>
            TypeConverterFieldWriter(typeConverter.name).write())
        .toList();

    // Generated code is not expected to satisfy the lint rules of the
    // consuming project (e.g. very_good_analysis), so suppress all lints.
    final ignoredDiagnostics = [
      'type=lint',
      if (distinctTypeConverterFields.isNotEmpty) 'unused_element',
    ];

    final library = Library((builder) {
      builder
        ..body
            .add(Code('// ignore_for_file: ${ignoredDiagnostics.join(', ')}\n'))
        ..body.add(DatabaseBuilderContractWriter(
          database.name,
          hasProvidedAutoMigrationSpecs: hasProvidedAutoMigrationSpecs,
        ).write())
        ..body.add(CodeWriter(database.name).write())
        ..body.add(DatabaseBuilderWriter(
          database.name,
          hasProvidedAutoMigrationSpecs: hasProvidedAutoMigrationSpecs,
        ).write())
        ..body.add(databaseClass)
        ..body.addAll(daoClasses)
        ..body.addAll(distinctTypeConverterFields);
    });

    return library.accept(DartEmitter()).toString();
  }

  Database _getDatabase(final Element element, final BuildStep buildStep) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
          'The element annotated with @Database is not a class.',
          element: element);
    }

    if (!element.isAbstract) {
      throw InvalidGenerationSourceError(
          'The database class has to be abstract.',
          element: element);
    }

    final schemaStore = FileSchemaStore.forDatabase(
      schemaLocation,
      buildStep.inputId.path,
      element.displayName,
    );
    return DatabaseProcessor(element, schemaStore: schemaStore).process();
  }
}
