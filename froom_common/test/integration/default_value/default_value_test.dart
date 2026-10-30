import 'dart:async';

import 'package:froom_common/froom_common.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite;
import 'package:test/test.dart';

import '../../test_util/database_factory.dart';

part 'default_value_test.g.dart';

void main() {
  group('column default values', () {
    late TestDatabase database;
    late UserDao userDao;

    setUp(() async {
      database = await $FroomTestDatabase.inMemoryDatabaseBuilder().build();
      userDao = database.userDao;
    });

    tearDown(() async {
      await database.close();
    });

    test('insert query without columns uses default values', () async {
      await userDao.insertName(1, 'Simon');

      final actual = await userDao.findUserById(1);

      expect(actual, equals(User(1, 'Simon', "Guest's role", 0, true)));
    });

    test('partial entity without columns uses default values', () async {
      await userDao.upsertUserName(UserName(2, 'Frank'));

      final actual = await userDao.findUserById(2);

      expect(actual, equals(User(2, 'Frank', "Guest's role", 0, true)));
    });

    test('inserting an entity uses its field values', () async {
      final user = User(3, 'Anna', 'Admin', 5, false);
      await userDao.insertUser(user);

      expect(await userDao.findUserById(3), equals(user));
    });
  });
}

@entity
class User {
  @primaryKey
  final int id;

  final String name;

  @ColumnInfo(defaultValue: "Guest's role")
  final String role;

  @ColumnInfo(defaultValue: '0')
  final int visits;

  @ColumnInfo(defaultValue: '1')
  final bool active;

  User(this.id, this.name, this.role, this.visits, this.active);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          role == other.role &&
          visits == other.visits &&
          active == other.active;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      role.hashCode ^
      visits.hashCode ^
      active.hashCode;

  @override
  String toString() =>
      'User{id: $id, name: $name, role: $role, visits: $visits, active: $active}';
}

/// Partial entity of [User] omitting the columns with default values.
class UserName {
  final int id;

  final String name;

  UserName(this.id, this.name);
}

@dao
abstract class UserDao {
  @Query('INSERT INTO User (id, name) VALUES (:id, :name)')
  Future<void> insertName(int id, String name);

  @insert
  Future<void> insertUser(User user);

  @Upsert(entity: User)
  Future<void> upsertUserName(UserName userName);

  @Query('SELECT * FROM User WHERE id = :id')
  Future<User?> findUserById(int id);
}

@Database(version: 1, entities: [User])
abstract class TestDatabase extends FroomDatabase {
  UserDao get userDao;
}
