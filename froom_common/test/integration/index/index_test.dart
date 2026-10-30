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

  });
}

@Entity(indices: [
  Index(value: ['email'], unique: true, where: 'email IS NOT NULL'),
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
