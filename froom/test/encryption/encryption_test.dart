@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:froom/froom.dart';
import 'package:froom/sqflite.dart' as sqflite;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

part 'encryption_test.g.dart';

@entity
class Secret {
  @primaryKey
  final int id;

  final String text;

  Secret(this.id, this.text);
}

@dao
abstract class SecretDao {
  @Query('SELECT * FROM Secret')
  Future<List<Secret>> findAllSecrets();

  @insert
  Future<void> insertSecret(Secret secret);
}

@Database(version: 1, entities: [Secret])
abstract class SecretDatabase extends FroomDatabase {
  SecretDao get secretDao;
}

// the tests of this package use SQLite3MultipleCiphers, see the pubspec.yaml
void main() {
  late String name;
  late String path;

  setUp(() async {
    name = 'encryption_${DateTime.now().microsecondsSinceEpoch}.db';
    path = await sqfliteDatabaseFactory.getDatabasePath(name);
  });

  tearDown(() => sqfliteDatabaseFactory.deleteDatabase(path));

  Future<SecretDatabase> open({final String? password}) {
    final builder = $FroomSecretDatabase.databaseBuilder(name);
    if (password != null) builder.password(password);
    return builder.build();
  }

  test('database is encrypted with the password', () async {
    final database = await open(password: "pass'word");
    await database.secretDao.insertSecret(Secret(1, 'hidden'));
    await database.close();

    final header = String.fromCharCodes(File(path).readAsBytesSync().take(15));
    expect(header, isNot('SQLite format 3'));
    expect(File(path).readAsStringSync(encoding: latin1), isNot(contains('hidden')));

    final reopened = await open(password: "pass'word");
    addTearDown(reopened.close);
    expect(
      (await reopened.secretDao.findAllSecrets()).map((secret) => secret.text),
      ['hidden'],
    );
  });

  test('wrong password fails', () async {
    final database = await open(password: 'right');
    await database.close();

    expect(
      () => open(password: 'wrong'),
      throwsA(isA<DatabaseEncryptionException>()
          // SQLITE_NOTADB, like the exception of SQLite
          .having((exception) => exception.getResultCode(), 'result code', 26)),
    );
  });

  test('wrong password fails while the database is open', () async {
    final database = await open(password: 'right');
    addTearDown(database.close);

    await expectLater(
        open(password: 'wrong'), throwsA(isA<DatabaseEncryptionException>()));
    await expectLater(open(), throwsA(isA<DatabaseEncryptionException>()));
    // the open instance, which shares the connection
    final reopened = await open(password: 'right');
    await reopened.secretDao.insertSecret(Secret(1, 'shared'));
    expect(await database.secretDao.findAllSecrets(), hasLength(1));
  });

  test('password fails while the database is open without one', () async {
    final database = await open();
    addTearDown(database.close);

    await expectLater(
        open(password: 'password'), throwsA(isA<DatabaseEncryptionException>()));
  });

  test('missing password of an encrypted database fails', () async {
    final database = await open(password: 'password');
    await database.close();

    expect(
      () => open(),
      throwsA(isA<DatabaseEncryptionException>()
          .having((exception) => exception.getResultCode(), 'result code', 26)),
    );
  });

  test('password of an unencrypted database fails', () async {
    final database = await open();
    await database.close();

    expect(
      () => open(password: 'password'),
      throwsA(isA<DatabaseEncryptionException>()),
    );
  });

  test('empty password fails', () async {
    expect(() => open(password: ''), throwsArgumentError);
    expect(File(path).existsSync(), isFalse);
  });

  test('in-memory database ignores the password', () async {
    final database = await $FroomSecretDatabase
        .inMemoryDatabaseBuilder()
        .password('password')
        .build();
    addTearDown(database.close);

    await database.secretDao.insertSecret(Secret(1, 'memory'));

    expect(await database.secretDao.findAllSecrets(), hasLength(1));
  });

  test('database files are in the databases directory', () {
    expect(p.basename(path), name);
  });
}
