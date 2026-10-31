import 'dart:io';

import 'package:froom_common/froom_common.dart';
import 'package:test/test.dart';

import '../test_util/database_factory.dart';
import 'database.dart';

// the tests of this package use the system SQLite, which can't encrypt
void main() {
  test('password fails without encryption support of SQLite', () async {
    const name = 'encryption_unsupported_test.db';
    final path = await sqfliteDatabaseFactory.getDatabasePath(name);
    addTearDown(() => sqfliteDatabaseFactory.deleteDatabase(path));

    final actual = $FroomTestDatabase.databaseBuilder(name).password('password').build();

    await expectLater(
      actual,
      throwsA(isA<DatabaseEncryptionException>().having(
          (exception) => exception.message,
          'message',
          contains("doesn't support encryption"))),
    );
    // nothing is stored unencrypted
    final file = File(path);
    expect(file.existsSync() ? file.lengthSync() : 0, 0);
  });
}
