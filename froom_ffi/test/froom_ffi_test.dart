import 'dart:async';

import 'package:froom_ffi/froom_ffi.dart';
import 'package:froom_ffi/sqflite.dart' as sqflite;
import 'package:test/test.dart';

part 'froom_ffi_test.g.dart';

@entity
class Person {
  @primaryKey
  final int id;

  final String name;

  Person(this.id, this.name);
}

@dao
abstract class PersonDao {
  @Query('SELECT * FROM Person')
  Future<List<Person>> findAllPersons();

  @insert
  Future<void> insertPerson(Person person);
}

@Database(version: 1, entities: [Person])
abstract class TestDatabase extends FroomDatabase {
  PersonDao get personDao;
}

void main() {
  test('generated database works with froom_ffi', () async {
    const name = 'froom_ffi_test.db';
    final path = await sqfliteDatabaseFactory.getDatabasePath(name);
    addTearDown(() => sqfliteDatabaseFactory.deleteDatabase(path));

    final database = await $FroomTestDatabase.databaseBuilder(name).build();
    addTearDown(database.close);
    await database.personDao.insertPerson(Person(1, 'Simon'));

    expect(await database.personDao.findAllPersons(), hasLength(1));
  });
}
