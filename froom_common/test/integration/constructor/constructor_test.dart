import 'dart:async';

import 'package:froom_common/froom_common.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite;
import 'package:test/test.dart';

import '../../test_util/database_factory.dart';

part 'constructor_test.g.dart';

void main() {
  group('entity constructors', () {
    late TestDatabase database;

    setUp(() async {
      database = await $FroomTestDatabase.inMemoryDatabaseBuilder().build();
    });

    tearDown(() async {
      await database.close();
    });

    test('uses the unnamed constructor over a named one declared first',
        () async {
      await database.userDao.insertUser(User(1, 'Simon'));

      final actual = await database.userDao.findAllUsers();

      expect(actual.map((user) => user.name), equals(['Simon']));
    });

    test('calls a named constructor by its name', () async {
      await database.userDao.insertAccount(Account.fromDatabase(1, 'Frank'));

      final actual = await database.userDao.findAllAccounts();

      expect(actual.map((account) => account.owner), equals(['Frank']));
    });
  });
}

@entity
class User {
  @primaryKey
  final int? id;

  final String? name;

  User.empty()
      : id = null,
        name = null;

  User(this.id, this.name);
}

@entity
class Account {
  @primaryKey
  final int id;

  final String owner;

  Account.fromDatabase(this.id, this.owner);
}

@dao
abstract class UserDao {
  @insert
  Future<void> insertUser(User user);

  @Query('SELECT * FROM User')
  Future<List<User>> findAllUsers();

  @insert
  Future<void> insertAccount(Account account);

  @Query('SELECT * FROM Account')
  Future<List<Account>> findAllAccounts();
}

@Database(version: 1, entities: [User, Account])
abstract class TestDatabase extends FroomDatabase {
  UserDao get userDao;
}
