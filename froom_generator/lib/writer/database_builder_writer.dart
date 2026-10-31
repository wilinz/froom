import 'package:code_builder/code_builder.dart';
import 'package:froom_generator/misc/annotation_expression.dart';
import 'package:froom_generator/writer/writer.dart';

class DatabaseBuilderWriter extends Writer {
  final String _databaseName;

  /// Whether specs of automatic migrations are provided to the builder.
  final bool _hasProvidedAutoMigrationSpecs;

  DatabaseBuilderWriter(
    final String databaseName, {
    final bool hasProvidedAutoMigrationSpecs = false,
  })  : _databaseName = databaseName,
        _hasProvidedAutoMigrationSpecs = hasProvidedAutoMigrationSpecs;

  @override
  Class write() {
    final databaseBuilderName = '_\$${_databaseName}Builder';
    final databaseBuilderContractRefer = refer(
      '\$${_databaseName}BuilderContract',
    );

    final nameField = Field((builder) => builder
      ..name = 'name'
      ..type = refer('String?')
      ..modifier = FieldModifier.final$);

    final migrationsField = Field((builder) => builder
      ..name = '_migrations'
      ..type = refer('List<Migration>')
      ..modifier = FieldModifier.final$
      ..assignment = const Code('[]'));

    final autoMigrationSpecsField = Field((builder) => builder
      ..name = '_autoMigrationSpecs'
      ..type = refer('List<AutoMigrationSpec>')
      ..modifier = FieldModifier.final$
      ..assignment = const Code('[]'));

    final callbackField = Field((builder) => builder
      ..name = '_callback'
      ..type = refer('Callback?'));

    final fallbackToDestructiveMigrationField = Field((builder) => builder
      ..name = '_fallbackToDestructiveMigration'
      ..type = refer('bool')
      ..assignment = const Code('false'));

    final databaseFactoryField = Field((builder) => builder
      ..name = '_databaseFactory'
      ..type = refer('sqflite.DatabaseFactory?'));

    final passwordField = Field((builder) => builder
      ..name = '_password'
      ..type = refer('String?'));

    final constructor = Constructor((builder) => builder
      ..requiredParameters.add(Parameter((builder) => builder
        ..toThis = true
        ..name = 'name')));

    final addMigrationsMethod = Method((builder) => builder
      ..annotations.add(overrideAnnotationExpression)
      ..name = 'addMigrations'
      ..returns = databaseBuilderContractRefer
      ..body = const Code('''
        _migrations.addAll(migrations);
        return this;
      ''')
      ..requiredParameters.add(Parameter((builder) => builder
        ..name = 'migrations'
        ..type = refer('List<Migration>'))));

    final addAutoMigrationSpecsMethod = Method((builder) => builder
      ..annotations.add(overrideAnnotationExpression)
      ..name = 'addAutoMigrationSpecs'
      ..returns = databaseBuilderContractRefer
      ..body = const Code('''
        _autoMigrationSpecs.addAll(autoMigrationSpecs);
        return this;
      ''')
      ..requiredParameters.add(Parameter((builder) => builder
        ..name = 'autoMigrationSpecs'
        ..type = refer('List<AutoMigrationSpec>'))));

    final addCallbackMethod = Method((builder) => builder
      ..annotations.add(overrideAnnotationExpression)
      ..name = 'addCallback'
      ..returns = databaseBuilderContractRefer
      ..body = const Code('''
        _callback = callback;
        return this;
      ''')
      ..requiredParameters.add(Parameter((builder) => builder
        ..name = 'callback'
        ..type = refer('Callback'))));

    final fallbackToDestructiveMigrationMethod = Method((builder) => builder
      ..annotations.add(overrideAnnotationExpression)
      ..name = 'fallbackToDestructiveMigration'
      ..returns = databaseBuilderContractRefer
      ..body = const Code('''
        _fallbackToDestructiveMigration = true;
        return this;
      '''));

    final databaseFactoryMethod = Method((builder) => builder
      ..annotations.add(overrideAnnotationExpression)
      ..name = 'databaseFactory'
      ..returns = databaseBuilderContractRefer
      ..body = const Code('''
        _databaseFactory = databaseFactory;
        return this;
      ''')
      ..requiredParameters.add(Parameter((builder) => builder
        ..name = 'databaseFactory'
        ..type = refer('sqflite.DatabaseFactory'))));

    final passwordMethod = Method((builder) => builder
      ..annotations.add(overrideAnnotationExpression)
      ..name = 'password'
      ..returns = databaseBuilderContractRefer
      ..body = const Code('''
        EncryptionAdapter.validatePassword(password);
        _password = password;
        return this;
      ''')
      ..requiredParameters.add(Parameter((builder) => builder
        ..name = 'password'
        ..type = refer('String'))));

    final buildMethod = Method((builder) => builder
      ..annotations.add(overrideAnnotationExpression)
      ..returns = refer('Future<$_databaseName>')
      ..name = 'build'
      ..modifier = MethodModifier.async
      ..body = Code('''
        final databaseFactory = _databaseFactory ?? sqfliteDatabaseFactory;
        final path = name != null
          ? await databaseFactory.getDatabasePath(name!)
          : ':memory:';
        final database = _\$$_databaseName();
        database.database = await database.open(
          databaseFactory,
          path,
          // in-memory databases are not stored
          name != null ? _password : null,
          _migrations,
          _callback,
          _fallbackToDestructiveMigration,
          ${_hasProvidedAutoMigrationSpecs ? '_autoMigrationSpecs,' : ''}
        );
        return database;
      '''));

    return Class((builder) => builder
      ..name = databaseBuilderName
      ..implements.addAll([
        databaseBuilderContractRefer,
      ])
      ..fields.addAll([
        nameField,
        migrationsField,
        if (_hasProvidedAutoMigrationSpecs) autoMigrationSpecsField,
        callbackField,
        fallbackToDestructiveMigrationField,
        databaseFactoryField,
        passwordField,
      ])
      ..constructors.add(constructor)
      ..methods.addAll([
        addMigrationsMethod,
        if (_hasProvidedAutoMigrationSpecs) addAutoMigrationSpecsMethod,
        addCallbackMethod,
        fallbackToDestructiveMigrationMethod,
        databaseFactoryMethod,
        passwordMethod,
        buildMethod,
      ]));
  }
}
