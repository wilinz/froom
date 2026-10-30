import 'package:froom_common/src/adapter/migration_adapter.dart';
import 'package:froom_common/src/migration.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../test_util/mocks.dart';

void main() {
  final mockDatabase = MockDatabase();

  tearDown(() {
    clearInteractions(mockDatabase);
  });

  test('run single migration', () async {
    const startVersion = 1;
    const endVersion = 2;
    const sql = 'FOO BAR';
    final migrations = [
      Migration(1, 2, (database) async {
        await database.execute(sql);
      })
    ];
    when(mockDatabase.execute(sql)).thenAnswer((_) => Future(() {}));

    await MigrationAdapter.runMigrations(
      mockDatabase,
      startVersion,
      endVersion,
      migrations,
    );

    verify(mockDatabase.execute(sql));
  });

  test('run multiple migrations in order', () async {
    const startVersion = 1;
    const endVersion = 4;
    const sql1 = 'first';
    const sql2 = 'second';
    const sql3 = 'third';
    final migrations = [
      Migration(3, 4, (database) async {
        await database.execute(sql3);
      }),
      Migration(1, 2, (database) async {
        await database.execute(sql1);
      }),
      Migration(2, 3, (database) async {
        await database.execute(sql2);
      }),
    ];
    final future = Future(() {});
    when(mockDatabase.execute(sql1)).thenAnswer((_) => future);
    when(mockDatabase.execute(sql2)).thenAnswer((_) => future);
    when(mockDatabase.execute(sql3)).thenAnswer((_) => future);

    await MigrationAdapter.runMigrations(
      mockDatabase,
      startVersion,
      endVersion,
      migrations,
    );

    verifyInOrder([
      mockDatabase.execute(sql1),
      mockDatabase.execute(sql2),
      mockDatabase.execute(sql3),
    ]);
  });

  test('exception when no matching start version found', () {
    const startVersion = 10;
    const endVersion = 20;
    const sql = 'FOO BAR';
    final migrations = [
      Migration(1, 2, (database) async {
        await database.execute(sql);
      })
    ];

    final actual = () => MigrationAdapter.runMigrations(
          mockDatabase,
          startVersion,
          endVersion,
          migrations,
        );

    expect(actual, throwsStateError);
    verifyZeroInteractions(mockDatabase);
  });

  test('exception when no matching end version found', () {
    const startVersion = 1;
    const endVersion = 10;
    const sql = 'FOO BAR';
    final migrations = [
      Migration(1, 2, (database) async {
        await database.execute(sql);
      })
    ];

    final actual = () => MigrationAdapter.runMigrations(
          mockDatabase,
          startVersion,
          endVersion,
          migrations,
        );

    expect(actual, throwsStateError);
    verifyZeroInteractions(mockDatabase);
  });

  group('migration path', () {
    Migration migration(final int startVersion, final int endVersion) =>
        Migration(startVersion, endVersion, (database) async {
          await database.execute('$startVersion-$endVersion');
        });

    setUp(() {
      when(mockDatabase.execute(any)).thenAnswer((_) => Future(() {}));
    });

    test('no path with a gap between migrations', () {
      final migrations = [migration(1, 2), migration(3, 4)];

      expect(MigrationAdapter.hasMigrationPath(1, 4, migrations), isFalse);
      expect(
        () => MigrationAdapter.runMigrations(mockDatabase, 1, 4, migrations),
        throwsStateError,
      );
      verifyZeroInteractions(mockDatabase);
    });

    test('prefers the migration reaching the highest version', () async {
      final migrations = [migration(1, 2), migration(2, 3), migration(1, 3)];

      await MigrationAdapter.runMigrations(mockDatabase, 1, 3, migrations);

      verify(mockDatabase.execute('1-3'));
      verifyNoMoreInteractions(mockDatabase);
    });

    test('falls back to shorter migrations when a path ends', () async {
      final migrations = [migration(1, 3), migration(1, 2), migration(2, 4)];

      await MigrationAdapter.runMigrations(mockDatabase, 1, 4, migrations);

      verifyInOrder([
        mockDatabase.execute('1-2'),
        mockDatabase.execute('2-4'),
      ]);
      verifyNoMoreInteractions(mockDatabase);
    });

    test('ignores migrations beyond the end version', () async {
      final migrations = [migration(1, 2), migration(2, 3)];

      await MigrationAdapter.runMigrations(mockDatabase, 1, 2, migrations);

      verify(mockDatabase.execute('1-2'));
      verifyNoMoreInteractions(mockDatabase);
    });
  });
}
