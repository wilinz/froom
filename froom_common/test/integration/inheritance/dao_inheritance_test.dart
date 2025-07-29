import 'dart:async';

import 'package:froom_common/froom_common.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite;
import 'package:test/test.dart';

import '../../test_util/database_factory.dart';

part 'dao_inheritance_test.g.dart';

void main() {
  group('dao inheritance tests', () {
    late TestDatabase database;
    late PersonDao personDao;

    setUp(() async {
      database = await $FroomTestDatabase.inMemoryDatabaseBuilder().build();
      personDao = database.personDao;
    });

    tearDown(() async {
      await database.close();
    });

    test('use generated inherited insert function', () async {
      final person = Person(1, 'Simon');
      await personDao.insertItem(person);

      final actual = await personDao.findPersonById(person.id);

      expect(actual, equals(person));
    });
  });
}

@Database(version: 1, entities: [Person])
abstract class TestDatabase extends FroomDatabase {
  PersonDao get personDao;
}

@dao
abstract class PersonDao extends AbstractDao<Person> {
  @Query('SELECT * FROM Person WHERE id = :id')
  Future<Person?> findPersonById(int id);
}

abstract class AbstractDao<T> {
  @insert
  Future<void> insertItem(T item);
}

@entity
class Person {
  @primaryKey
  final int id;

  final String name;

  Person(this.id, this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() {
    return 'Person{id: $id, name: $name}';
  }
}
