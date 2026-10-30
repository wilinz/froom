import 'package:build_test/build_test.dart';
import 'package:code_builder/code_builder.dart';
import 'package:froom_generator/processor/database_processor.dart';
import 'package:froom_generator/value_object/database.dart';
import 'package:froom_generator/writer/database_writer.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  useDartfmt();

  test('open database for simple entity', () async {
    final database = await _createDatabase('''
      @Database(version: 1, entities: [Person])
      abstract class TestDatabase extends FroomDatabase {}
      
      @entity
      class Person {
        @primaryKey
        final int id;
      
        final String name;
      
        Person(this.id, this.name);
      }
    ''');

    final actual = DatabaseWriter(database).write();

    expect(actual, equalsDart(r'''
    class _$TestDatabase extends TestDatabase {
        _$TestDatabase([StreamController<String>? listener]) {
          changeListener = listener ?? StreamController<String>.broadcast();
        }
      
        Future<sqflite.Database> open(
          String path,
          List<Migration> migrations, [
          Callback? callback,
          bool fallbackToDestructiveMigration = false,
        ]) async {
          Future<void> createSchema(sqflite.Database database) async {
              await database.execute(
                  'CREATE TABLE IF NOT EXISTS `Person` (`id` INTEGER NOT NULL, `name` TEXT NOT NULL, PRIMARY KEY (`id`))');
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
            version: 1,
            onConfigure: (database) async {
              if (await MigrationAdapter.isUpgradePending(database, 1)) {
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
                  !MigrationAdapter.hasMigrationPath(startVersion, endVersion, migrations)) {
                await recreateSchema(database);
                return;
              }

              final foreignKeyViolations = await MigrationAdapter.getForeignKeyViolations(database);
              await MigrationAdapter.runMigrations(
                  database, startVersion, endVersion, migrations);

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
          return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
        }

        @override
        List<String> get entityTableNames => const ['Person'];
      } 
      '''));
  });

  test('open database with DAO', () async {
    final database = await _createDatabase('''
      @Database(version: 1, entities: [Person])
      abstract class TestDatabase extends FroomDatabase {
        TestDao get testDao;
      }
      
      @entity
      class Person {
        @primaryKey
        final int id;
      
        final String name;
      
        Person(this.id, this.name);
      }
      
      @dao
      abstract class TestDao {
        @insert
        Future<int> insertPersonWithReturn(Person person);
      }
    ''');

    final actual = DatabaseWriter(database).write();

    expect(actual, equalsDart(r'''
      class _$TestDatabase extends TestDatabase {
        _$TestDatabase([StreamController<String>? listener]) {
          changeListener = listener ?? StreamController<String>.broadcast();
        }
        
        TestDao? _testDaoInstance;
        
        Future<sqflite.Database> open(
          String path,
          List<Migration> migrations, [
          Callback? callback,
          bool fallbackToDestructiveMigration = false,
        ]) async {
          Future<void> createSchema(sqflite.Database database) async {
              await database.execute(
                  'CREATE TABLE IF NOT EXISTS `Person` (`id` INTEGER NOT NULL, `name` TEXT NOT NULL, PRIMARY KEY (`id`))');
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
            version: 1,
            onConfigure: (database) async {
              if (await MigrationAdapter.isUpgradePending(database, 1)) {
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
                  !MigrationAdapter.hasMigrationPath(startVersion, endVersion, migrations)) {
                await recreateSchema(database);
                return;
              }

              final foreignKeyViolations = await MigrationAdapter.getForeignKeyViolations(database);
              await MigrationAdapter.runMigrations(
                  database, startVersion, endVersion, migrations);

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
          return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
        }

        @override
        List<String> get entityTableNames => const ['Person'];
      
        @override
        TestDao get testDao {
          return _testDaoInstance ??= _$TestDao(database, changeListener);
        }
      }
    '''));
  });

  test('open database for complex entity', () async {
    final database = await _createDatabase('''
      @Database(version: 1, entities: [Person])
      abstract class TestDatabase extends FroomDatabase {}
      
      @Entity(tableName: 'custom_table_name')
      class Person {
        @PrimaryKey(autoGenerate: true)
        final int? id;
      
        @ColumnInfo(name: 'custom_name')
        final String name;
      
        Person(this.id, this.name);
      }
    ''');

    final actual = DatabaseWriter(database).write();

    expect(actual, equalsDart(r'''
      class _$TestDatabase extends TestDatabase {
        _$TestDatabase([StreamController<String>? listener]) {
          changeListener = listener ?? StreamController<String>.broadcast();
        }
        
        Future<sqflite.Database> open(
          String path,
          List<Migration> migrations, [
          Callback? callback,
          bool fallbackToDestructiveMigration = false,
        ]) async {
          Future<void> createSchema(sqflite.Database database) async {
              await database.execute(
                  'CREATE TABLE IF NOT EXISTS `custom_table_name` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `custom_name` TEXT NOT NULL)');
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
            version: 1,
            onConfigure: (database) async {
              if (await MigrationAdapter.isUpgradePending(database, 1)) {
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
                  !MigrationAdapter.hasMigrationPath(startVersion, endVersion, migrations)) {
                await recreateSchema(database);
                return;
              }

              final foreignKeyViolations = await MigrationAdapter.getForeignKeyViolations(database);
              await MigrationAdapter.runMigrations(
                  database, startVersion, endVersion, migrations);

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
          return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
        }

        @override
        List<String> get entityTableNames => const ['custom_table_name'];
      }      
    '''));
  });

  test('open database with view', () async {
    final database = await _createDatabase('''
      @Database(version: 1, entities: [Person], views: [Name])
      abstract class TestDatabase extends FroomDatabase {}
      
      @DatabaseView(
          'SELECT custom_name as name FROM person',
          viewName: 'names')
      class Name {
        final String name;
      
        Name(this.name);
      }
      
      @entity
      class Person {
        @primaryKey
        final int id;
      
        final String name;
      
        Person(this.id, this.name);
      }
    ''');

    final actual = DatabaseWriter(database).write();

    expect(actual, equalsDart(r"""
      class _$TestDatabase extends TestDatabase {
        _$TestDatabase([StreamController<String>? listener]) {
         changeListener = listener ?? StreamController<String>.broadcast();
        }
      
        Future<sqflite.Database> open(
          String path,
          List<Migration> migrations, [
          Callback? callback,
          bool fallbackToDestructiveMigration = false,
        ]) async {
          Future<void> createSchema(sqflite.Database database) async {
              await database.execute(
                  'CREATE TABLE IF NOT EXISTS `Person` (`id` INTEGER NOT NULL, `name` TEXT NOT NULL, PRIMARY KEY (`id`))');
                  
              await database.execute(
                  'CREATE VIEW IF NOT EXISTS `names` AS SELECT custom_name as name FROM person');
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
            version: 1,
            onConfigure: (database) async {
              if (await MigrationAdapter.isUpgradePending(database, 1)) {
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
                  !MigrationAdapter.hasMigrationPath(startVersion, endVersion, migrations)) {
                await recreateSchema(database);
                return;
              }

              final foreignKeyViolations = await MigrationAdapter.getForeignKeyViolations(database);
              await MigrationAdapter.runMigrations(
                  database, startVersion, endVersion, migrations);
              await database.execute('DROP VIEW IF EXISTS `names`');
              await database.execute(
                  'CREATE VIEW IF NOT EXISTS `names` AS SELECT custom_name as name FROM person');

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
          return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
        }

        @override
        List<String> get entityTableNames => const ['Person'];
      }      
    """));
  });
}

Future<Database> _createDatabase(final String definition) async {
  final library = await resolveSource(readAllSourcesFromFilesystem: true, '''
      library test;
      
      import 'package:froom_annotation/froom_annotation.dart';
      
      $definition
      ''', (resolver) async {
    return resolver
        .findLibraryByName('test')
        .then((value) => ArgumentError.checkNotNull(value))
        .then((value) => LibraryReader(value));
  });

  return DatabaseProcessor(library.classes.first).process();
}
