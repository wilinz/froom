import 'package:froom_common/froom_common.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:test/test.dart';

import '../test_util/database_factory.dart';

void main() {
  Future<void> createVirtualTable(final String module) async {
    final database = await sqfliteDatabaseFactory.openDatabase(inMemoryDatabasePath);
    try {
      await database.execute('CREATE VIRTUAL TABLE note USING $module(text)');
    } finally {
      await database.close();
    }
  }

  test('missing module is explained', () async {
    final actual =
        explainMissingSqliteModules<void>(() => createVirtualTable('fts4x'));

    await expectLater(
      actual,
      throwsA(isA<DatabaseException>()
          .having((exception) => exception, 'exception',
              isA<MissingSqliteModuleException>())
          .having((exception) => (exception as MissingSqliteModuleException).module,
              'module', 'fts4x')
          // like the exception of SQLite
          .having((exception) => exception.getResultCode(), 'result code', 1)),
    );
  });

  test('missing FTS4 module is explained', () {
    expect(
      MissingSqliteModuleException('fts4', Exception()).toString(),
      contains('@Fts5'),
    );
  });

  test('other exceptions are rethrown', () async {
    final exception = Exception('no such module: fts4');

    final actual = explainMissingSqliteModules<void>(() async => throw exception);

    await expectLater(actual, throwsA(same(exception)));
  });
}
