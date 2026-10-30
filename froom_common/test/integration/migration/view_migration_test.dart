import 'dart:async';

import 'package:froom_common/froom_common.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite;
import 'package:test/test.dart';

import '../../test_util/database_factory.dart';

part 'view_migration_test.g.dart';

void main() {
  test('views are recreated with their current query on upgrade', () async {
    final name = 'view_migration_${DateTime.now().microsecondsSinceEpoch}.db';
    final path = await sqfliteDatabaseFactory.getDatabasePath(name);
    final oldDatabase = await sqfliteDatabaseFactory.openDatabase(
      path,
      options: sqflite.OpenDatabaseOptions(
        version: 1,
        onCreate: (database, version) async {
          await database.execute(
              'CREATE TABLE IF NOT EXISTS `Person` (`id` INTEGER NOT NULL, `name` TEXT NOT NULL, PRIMARY KEY (`id`))');
          await database.execute(
              'CREATE VIEW IF NOT EXISTS `PersonName` AS SELECT name FROM Person WHERE id = 0');
          await database.execute(
              "INSERT INTO Person (id, name) VALUES (1, 'Simon')");
        },
      ),
    );
    await oldDatabase.close();
    addTearDown(() => sqfliteDatabaseFactory.deleteDatabase(path));

    final database = await $FroomTestDatabase
        .databaseBuilder(name)
        .addMigrations([Migration(1, 2, (database) async {})])
        .build();
    addTearDown(database.close);

    final actual = await database.personDao.findAllNames();

    expect(actual.map((personName) => personName.name), equals(['Simon']));
  });
}

@entity
class Person {
  @primaryKey
  final int id;

  final String name;

  Person(this.id, this.name);
}

@DatabaseView('SELECT name FROM Person', viewName: 'PersonName')
class PersonName {
  final String name;

  PersonName(this.name);
}

@dao
abstract class PersonDao {
  @Query('SELECT * FROM PersonName')
  Future<List<PersonName>> findAllNames();
}

@Database(version: 2, entities: [Person], views: [PersonName])
abstract class TestDatabase extends FroomDatabase {
  PersonDao get personDao;
}
