import 'package:code_builder/code_builder.dart';
import 'package:froom_generator/misc/annotation_expression.dart';
import 'package:froom_generator/misc/extension/string_extension.dart';
import 'package:froom_generator/value_object/database.dart';
import 'package:froom_generator/value_object/entity.dart';
import 'package:froom_generator/writer/auto_migration_writer.dart';
import 'package:froom_generator/writer/writer.dart';

/// Takes care of generating the database implementation.
class DatabaseWriter implements Writer {
  final Database database;

  DatabaseWriter(this.database);

  @override
  Class write() {
    return _generateDatabaseImplementation(database);
  }

  Class _generateDatabaseImplementation(final Database database) {
    final databaseName = database.name;

    return Class((builder) => builder
      ..name = '_\$$databaseName'
      ..extend = refer(databaseName)
      ..methods.add(_generateOpenMethod(database))
      ..methods.add(_generateEntityTableNamesGetter(database))
      ..methods.addAll(_generateDaoGetters(database))
      ..fields.addAll(_generateDaoInstances(database))
      ..constructors.add(_generateConstructor()));
  }

  Constructor _generateConstructor() {
    return Constructor((builder) {
      final parameter = Parameter((builder) => builder
        ..name = 'listener'
        ..type = refer('StreamController<String>?'));

      builder
        ..body = const Code(
          'changeListener = listener ?? StreamController<String>.broadcast();',
        )
        ..optionalParameters.add(parameter);
    });
  }

  Method _generateEntityTableNamesGetter(final Database database) {
    final tableNames = database.entities
        .map((entity) => entity.name.toLiteral())
        .join(', ');

    return Method((builder) => builder
      ..annotations.add(overrideAnnotationExpression)
      ..type = MethodType.getter
      ..returns = refer('List<String>')
      ..name = 'entityTableNames'
      ..lambda = true
      ..body = Code('const [$tableNames]'));
  }

  List<Method> _generateDaoGetters(final Database database) {
    return database.daoGetters.map((daoGetter) {
      final daoGetterName = daoGetter.name;
      final daoTypeName = daoGetter.dao.classElement.displayName;

      return Method((builder) => builder
        ..annotations.add(overrideAnnotationExpression)
        ..type = MethodType.getter
        ..returns = refer(daoTypeName)
        ..name = daoGetterName
        ..body = Code(
            'return _${daoGetterName}Instance ??= _\$$daoTypeName(database, changeListener);'));
    }).toList();
  }

  List<Field> _generateDaoInstances(final Database database) {
    return database.daoGetters.map((daoGetter) {
      final daoGetterName = daoGetter.name;
      final daoTypeName = daoGetter.dao.classElement.displayName;

      return Field((builder) => builder
        ..type = refer('$daoTypeName?')
        ..name = '_${daoGetterName}Instance');
    }).toList();
  }

  Method _generateOpenMethod(final Database database) {
    final createTableStatements = _generateCreateTableSqlStatements(
            database.entities)
        .map((statement) => 'await database.execute(${statement.toLiteral()});')
        .join('\n');
    final createIndexStatements = database.entities
        .map((entity) => entity.indices.map((index) => index.createQuery()))
        .expand((statements) => statements)
        .map((statement) => 'await database.execute(${statement.toLiteral()});')
        .join('\n');
    final createViewStatements = database.views
        .map((view) => view.getCreateViewStatement().toLiteral())
        .map((statement) => 'await database.execute($statement);')
        .join('\n');
    // views don't hold data, so they are recreated with their current queries
    final recreateViewStatements = database.views.isEmpty
        ? ''
        : [
            ...database.views
                .map((view) => 'DROP VIEW IF EXISTS `${view.name}`'.toLiteral())
                .map((statement) => 'await database.execute($statement);'),
            createViewStatements,
          ].join('\n');

    final databaseFactoryParameter = Parameter((builder) => builder
      ..name = 'databaseFactory'
      ..type = refer('sqflite.DatabaseFactory'));
    final pathParameter = Parameter((builder) => builder
      ..name = 'path'
      ..type = refer('String'));
    final migrationsParameter = Parameter((builder) => builder
      ..name = 'migrations'
      ..type = refer('List<Migration>'));
    final callbackParameter = Parameter((builder) => builder
      ..name = 'callback'
      ..type = refer('Callback?'));
    final fallbackToDestructiveMigrationParameter = Parameter((builder) =>
        builder
          ..name = 'fallbackToDestructiveMigration'
          ..type = refer('bool')
          ..defaultTo = const Code('false'));
    final autoMigrationSpecsParameter = Parameter((builder) => builder
      ..name = 'autoMigrationSpecs'
      ..type = refer('List<AutoMigrationSpec>')
      ..defaultTo = const Code('const []'));

    // migrations of the builder replace automatic ones of the same versions
    final autoMigrations = database.autoMigrations;
    final migrations = autoMigrations.isEmpty ? 'migrations' : 'allMigrations';
    final allMigrationsStatement = autoMigrations.isEmpty
        ? ''
        : '''
          final allMigrations = [
            ...migrations,
            ...${autoMigrations.writeList()}.where((autoMigration) => !migrations.any((migration) =>
                migration.startVersion == autoMigration.startVersion &&
                migration.endVersion == autoMigration.endVersion)),
          ];
          ''';

    return Method((builder) => builder
      ..name = 'open'
      ..returns = refer('Future<sqflite.Database>')
      ..modifier = MethodModifier.async
      ..requiredParameters.addAll([
        databaseFactoryParameter,
        pathParameter,
        migrationsParameter,
      ])
      ..optionalParameters.addAll([
        callbackParameter,
        fallbackToDestructiveMigrationParameter,
        if (autoMigrations.hasProvidedSpecs) autoMigrationSpecsParameter,
      ])
      ..body = Code('''
          $allMigrationsStatement
          Future<void> createSchema(sqflite.Database database) async {
            $createTableStatements
            $createIndexStatements
            $createViewStatements
          }

          Future<void> recreateSchema(sqflite.Database database) async {
            await MigrationAdapter.dropAllTables(database);
            await createSchema(database);
            await callback?.onDestructiveMigration?.call(database);
          }

          // foreign keys are enabled after migrations, which can't disable
          // them within their transaction
          var enableForeignKeysOnOpen = false;

          final databaseOptions = sqflite.OpenDatabaseOptions(
            version: ${database.version},
            onConfigure: (database) async {
              if (await MigrationAdapter.isUpgradePending(database, ${database.version})) {
                enableForeignKeysOnOpen = true;
              } else {
                await database.execute('PRAGMA foreign_keys = ON');
              }
              await callback?.onConfigure?.call(database);
            },
            onOpen: (database) async {
              if (enableForeignKeysOnOpen) {
                await database.execute('PRAGMA foreign_keys = ON');
              }
              await callback?.onOpen?.call(database);
            },
            onUpgrade: (database, startVersion, endVersion) async {
              if (fallbackToDestructiveMigration &&
                  !MigrationAdapter.hasMigrationPath(startVersion, endVersion, $migrations)) {
                await recreateSchema(database);
                return;
              }

              final foreignKeyViolations = await MigrationAdapter.getForeignKeyViolations(database);
              await MigrationAdapter.runMigrations(database, startVersion, endVersion, $migrations);
              $recreateViewStatements

              await callback?.onUpgrade?.call(database, startVersion, endVersion);
              await MigrationAdapter.checkForeignKeys(database, foreignKeyViolations);
            },
            onDowngrade: fallbackToDestructiveMigration
                ? (database, startVersion, endVersion) => recreateSchema(database)
                : null,
            onCreate: (database, version) async {
              await createSchema(database);

              await callback?.onCreate?.call(database, version);
            },
          );
          return databaseFactory.openDatabase(path, options: databaseOptions);
          '''));
  }

  List<String> _generateCreateTableSqlStatements(final List<Entity> entities) {
    return entities.map((entity) => entity.getCreateTableStatement()).toList();
  }
}
