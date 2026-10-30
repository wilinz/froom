import 'package:code_builder/code_builder.dart';
import 'package:froom_generator/writer/writer.dart';

class DatabaseBuilderContractWriter extends Writer {
  final String _databaseName;

  /// Whether specs of automatic migrations are provided to the builder.
  final bool _hasProvidedAutoMigrationSpecs;

  DatabaseBuilderContractWriter(
    final String databaseName, {
    final bool hasProvidedAutoMigrationSpecs = false,
  })  : _databaseName = databaseName,
        _hasProvidedAutoMigrationSpecs = hasProvidedAutoMigrationSpecs;

  @override
  Class write() {
    final databaseBuilderName = '\$${_databaseName}BuilderContract';

    final addMigrationsMethod = Method((builder) => builder
      ..name = 'addMigrations'
      ..returns = refer(databaseBuilderName)
      ..docs.add('/// Adds migrations to the builder.')
      ..requiredParameters.add(Parameter((builder) => builder
        ..name = 'migrations'
        ..type = refer('List<Migration>'))));

    final addAutoMigrationSpecsMethod = Method((builder) => builder
      ..name = 'addAutoMigrationSpecs'
      ..returns = refer(databaseBuilderName)
      ..docs.addAll([
        '/// Adds the specs of automatic migrations annotated with',
        '/// `@providedAutoMigrationSpec` to the builder.',
      ])
      ..requiredParameters.add(Parameter((builder) => builder
        ..name = 'autoMigrationSpecs'
        ..type = refer('List<AutoMigrationSpec>'))));

    final addCallbackMethod = Method((builder) => builder
      ..name = 'addCallback'
      ..returns = refer(databaseBuilderName)
      ..docs.add('/// Adds a database [Callback] to the builder.')
      ..requiredParameters.add(Parameter((builder) => builder
        ..name = 'callback'
        ..type = refer('Callback'))));

    final fallbackToDestructiveMigrationMethod = Method((builder) => builder
      ..name = 'fallbackToDestructiveMigration'
      ..returns = refer(databaseBuilderName)
      ..docs.addAll([
        '/// Recreates the database instead of crashing when there is no migration',
        '/// from its version to the current one, deleting all of its data.',
      ]));

    final buildMethod = Method((builder) => builder
      ..returns = refer('Future<$_databaseName>')
      ..name = 'build'
      ..modifier = MethodModifier.async
      ..docs.add('/// Creates the database and initializes it.'));

    return Class((builder) => builder
      ..name = databaseBuilderName
      ..abstract = true
      ..methods.addAll([
        addMigrationsMethod,
        if (_hasProvidedAutoMigrationSpecs) addAutoMigrationSpecsMethod,
        addCallbackMethod,
        fallbackToDestructiveMigrationMethod,
        buildMethod,
      ]));
  }
}
