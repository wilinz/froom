import 'dart:async';

import 'package:froom_common/froom_common.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite;
import 'package:test/test.dart';

import '../../test_util/database_factory.dart';

part 'index_test.g.dart';

void main() {
  group('indices', () {
    late TestDatabase database;
    late AccountDao accountDao;

    setUp(() async {
      database = await $FroomTestDatabase.inMemoryDatabaseBuilder().build();
      accountDao = database.accountDao;
    });

    tearDown(() async {
      await database.close();
    });

    test('partial unique index ignores rows not matching its expression',
        () async {
      await accountDao.insertAccount(Account(1, null));
      await accountDao.insertAccount(Account(2, null));
      await accountDao.insertAccount(Account(3, 'a@b.c'));

      final actual = accountDao.insertAccount(Account(4, 'a@b.c'));

      await expectLater(actual, throwsA(isA<sqflite.DatabaseException>()));
      expect(await accountDao.findAllAccounts(), hasLength(3));
    });

    test('unique index on expression', () async {
      await accountDao.insertAccount(Account(1, 'a@b.c'));

      final actual = accountDao.insertAccount(Account(2, 'A@B.C'));

      await expectLater(actual, throwsA(isA<sqflite.DatabaseException>()));
      expect(await accountDao.findAllAccounts(), hasLength(1));
    });

    test('creates index on expression with generated name', () async {
      final actual = await database.database.rawQuery(
          "SELECT sql FROM sqlite_master WHERE type = 'index' AND name = 'index_Account_lower_email_'");

      expect(actual, [
        {
          'sql': 'CREATE UNIQUE INDEX `index_Account_lower_email_`'
              ' ON `Account` (lower(email))'
        },
      ]);
    });
  });
}

@Entity(indices: [
  Index(value: ['email'], unique: true, where: 'email IS NOT NULL'),
  Index(value: ['lower(email)'], unique: true),
])
class Account {
  @primaryKey
  final int id;

  final String? email;

  Account(this.id, this.email);
}

@dao
abstract class AccountDao {
  @insert
  Future<void> insertAccount(Account account);

  @Query('SELECT * FROM Account')
  Future<List<Account>> findAllAccounts();
}

@Database(version: 1, entities: [Account])
abstract class TestDatabase extends FroomDatabase {
  AccountDao get accountDao;
}
