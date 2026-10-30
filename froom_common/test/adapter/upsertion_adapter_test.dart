import 'package:froom_common/froom_common.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:test/test.dart';

import '../test_util/mocks.dart';
import '../test_util/person.dart';

void main() {
  final mockDatabaseExecutor = MockDatabaseExecutor();
  final mockDatabaseBatch = MockBatch();

  const entityName = 'person';
  final valueMapper = (Person person) => {'id': person.id, 'name': person.name};
  const nativeUpsertSql = 'INSERT INTO `person` (`id`, `name`) '
      'VALUES (?, ?) '
      'ON CONFLICT(`id`) DO UPDATE SET `name` = excluded.`name`';

  final person1 = Person(1, 'Simon');
  final person2 = Person(2, 'Frank');
  final values1 = {'id': person1.id, 'name': person1.name};

  late UpsertionAdapter<Person> underTest;

  void stubDatabase({required String version, String? sql}) {
    // a new database per test, as support for native upserts is cached
    when(mockDatabaseExecutor.database).thenReturn(MockDatabase());
    when(mockDatabaseExecutor.rawQuery(any, any))
        .thenAnswer((_) async => [
              {'version': version, 'sql': sql}
            ]);
    when(mockDatabaseExecutor.batch()).thenReturn(mockDatabaseBatch);
    when(mockDatabaseBatch.commit(noResult: true))
        .thenAnswer((_) async => []);
  }

  setUp(() {
    underTest = UpsertionAdapter(
      mockDatabaseExecutor,
      entityName,
      ['id'],
      valueMapper,
    );
  });

  tearDown(() {
    clearInteractions(mockDatabaseExecutor);
    clearInteractions(mockDatabaseBatch);
    reset(mockDatabaseExecutor);
    reset(mockDatabaseBatch);
  });

  group('SQLite 3.24.0 and above', () {
    test('upsert list in a batch of native upserts', () async {
      stubDatabase(version: '3.24.0', sql: 'CREATE TABLE person');

      await underTest.upsertList([person1, person2]);

      verifyInOrder([
        mockDatabaseExecutor.batch(),
        mockDatabaseBatch.rawInsert(nativeUpsertSql, [1, 'Simon']),
        mockDatabaseBatch.rawInsert(nativeUpsertSql, [2, 'Frank']),
        mockDatabaseBatch.commit(noResult: true),
      ]);
      verifyNever(mockDatabaseExecutor.insert(any, any,
          conflictAlgorithm: anyNamed('conflictAlgorithm')));
    });

    test('upsert item with native upsert', () async {
      stubDatabase(version: '3.45.1', sql: 'CREATE TABLE person');

      await underTest.upsert(person1);

      verify(mockDatabaseBatch.rawInsert(nativeUpsertSql, [1, 'Simon']));
    });

    test('checks support only once per database', () async {
      stubDatabase(version: '3.45.1', sql: 'CREATE TABLE person');

      await underTest.upsert(person1);
      await underTest.upsert(person2);

      verify(mockDatabaseExecutor.rawQuery(any, any)).called(1);
    });

    test('does nothing on conflict when all columns are primary keys',
        () async {
      stubDatabase(version: '3.45.1', sql: 'CREATE TABLE person');
      final adapter = UpsertionAdapter<Person>(
        mockDatabaseExecutor,
        entityName,
        ['id'],
        (person) => {'id': person.id},
      );

      await adapter.upsert(person1);

      verify(mockDatabaseBatch.rawInsert(
        'INSERT INTO `person` (`id`) VALUES (?) ON CONFLICT(`id`) DO NOTHING',
        [1],
      ));
    });

    test('ids are returned by insert and update fallback', () async {
      stubDatabase(version: '3.45.1', sql: 'CREATE TABLE person');
      when(mockDatabaseExecutor.insert(entityName, values1,
              conflictAlgorithm: ConflictAlgorithm.abort))
          .thenAnswer((_) async => 1);

      final actual = await underTest.upsertAndReturnId(person1);

      expect(actual, equals(1));
      verifyNever(mockDatabaseExecutor.batch());
    });
  });

  group('fallback to insert and update', () {
    test('before SQLite 3.24.0', () async {
      stubDatabase(version: '3.22.0', sql: 'CREATE TABLE person');
      when(mockDatabaseExecutor.insert(entityName, values1,
              conflictAlgorithm: ConflictAlgorithm.abort))
          .thenAnswer((_) async => 1);

      await underTest.upsert(person1);

      verify(mockDatabaseExecutor.insert(entityName, values1,
          conflictAlgorithm: ConflictAlgorithm.abort));
      verifyNever(mockDatabaseExecutor.batch());
    });
  });

  group('virtual tables without unique primary keys', () {
    const virtualTableSql =
        'CREATE VIRTUAL TABLE person USING fts4(`id`, `name`)';

    test('update existing row instead of inserting', () async {
      stubDatabase(version: '3.45.1', sql: virtualTableSql);
      when(mockDatabaseExecutor.update(entityName, values1,
              where: 'id = ?',
              whereArgs: [1],
              conflictAlgorithm: ConflictAlgorithm.abort))
          .thenAnswer((_) async => 1);

      final actual = await underTest.upsertAndReturnId(person1);

      expect(actual, equals(-1));
      verifyNever(mockDatabaseExecutor.insert(any, any,
          conflictAlgorithm: anyNamed('conflictAlgorithm')));
      verifyNever(mockDatabaseExecutor.batch());
    });

    test('insert when no row got updated', () async {
      stubDatabase(version: '3.45.1', sql: virtualTableSql);
      when(mockDatabaseExecutor.update(entityName, values1,
              where: 'id = ?',
              whereArgs: [1],
              conflictAlgorithm: ConflictAlgorithm.abort))
          .thenAnswer((_) async => 0);
      when(mockDatabaseExecutor.insert(entityName, values1))
          .thenAnswer((_) async => 1);

      await underTest.upsert(person1);

      verifyInOrder([
        mockDatabaseExecutor.update(entityName, values1,
            where: 'id = ?',
            whereArgs: [1],
            conflictAlgorithm: ConflictAlgorithm.abort),
        mockDatabaseExecutor.insert(entityName, values1),
      ]);
    });
  });

  test('notifies change listener', () async {
    final mockStreamController = MockStreamController<String>();
    final adapter = UpsertionAdapter<Person>(
      mockDatabaseExecutor,
      entityName,
      ['id'],
      valueMapper,
      mockStreamController,
    );
    stubDatabase(version: '3.45.1', sql: 'CREATE TABLE person');

    await adapter.upsert(person1);

    verify(mockStreamController.add(entityName));
  });
}
