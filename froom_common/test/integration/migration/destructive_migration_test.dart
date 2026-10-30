import 'dart:async';

import 'package:froom_common/froom_common.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite;
import 'package:test/test.dart';

import '../../test_util/database_factory.dart';

part 'destructive_migration_test.g.dart';

void main() {
  group('destructive migration', () {
    late String name;
    late String path;

    setUp(() async {
      name = 'destructive_${DateTime.now().microsecondsSinceEpoch}.db';
      path = await sqfliteDatabaseFactory.getDatabasePath(name);
    });

    tearDown(() async {
      await sqfliteDatabaseFactory.deleteDatabase(path);
    });

    Future<void> createOldDatabase(final int version) async {
      final database = await sqfliteDatabaseFactory.openDatabase(
        path,
        options: sqflite.OpenDatabaseOptions(
          version: version,
          onCreate: (database, version) async {
            await database.execute(
                'CREATE TABLE Parent (id INTEGER PRIMARY KEY)');
            await database.execute(
                'CREATE TABLE Child (id INTEGER PRIMARY KEY, parent_id INTEGER REFERENCES Parent (id))');
            await database.execute('CREATE VIEW ParentIds AS SELECT id FROM Parent');
            await database.execute('CREATE VIRTUAL TABLE Notes USING fts4(text)');
            await database.execute('INSERT INTO Parent (id) VALUES (1)');
            await database.execute(
                'INSERT INTO Child (id, parent_id) VALUES (1, 1)');
            await database.execute("INSERT INTO Notes (text) VALUES ('note')");
            await database.execute(
                'CREATE TABLE Item (id INTEGER PRIMARY KEY, old_column TEXT)');
            await database.execute('INSERT INTO Item (id) VALUES (1)');
          },
        ),
      );
      await database.close();
    }

    Future<List<String>> schemaObjectNames(final TestDatabase database) async {
      final rows = await database.database.rawQuery(
          "SELECT name FROM sqlite_master WHERE name NOT LIKE 'sqlite_%' ORDER BY name");
      return rows.map((row) => row['name'] as String).toList();
    }

    test('recreates the database without migration path', () async {
      await createOldDatabase(1);
      var destructiveMigrations = 0;

      final database = await $FroomTestDatabase
          .databaseBuilder(name)
          .addCallback(Callback(
            onDestructiveMigration: (_) => destructiveMigrations++,
          ))
          .fallbackToDestructiveMigration()
          .build();

      expect(await schemaObjectNames(database), equals(['Item']));
      expect(await database.itemDao.findAllItems(), isEmpty);
      expect(await database.database.getVersion(), equals(2));
      expect(destructiveMigrations, equals(1));
      await database.close();
    });

    test('recreates the database on downgrade', () async {
      await createOldDatabase(5);

      final database = await $FroomTestDatabase
          .databaseBuilder(name)
          .fallbackToDestructiveMigration()
          .build();

      expect(await schemaObjectNames(database), equals(['Item']));
      expect(await database.database.getVersion(), equals(2));
      await database.close();
    });

    test('fails without migration path and fallback', () async {
      await createOldDatabase(1);

      final actual = $FroomTestDatabase.databaseBuilder(name).build();

      await expectLater(actual, throwsStateError);
    });

    test('prefers existing migrations', () async {
      await createOldDatabase(1);
      final migration = Migration(1, 2, (database) async {
        await database.execute('ALTER TABLE Item ADD COLUMN name TEXT');
      });

      final database = await $FroomTestDatabase
          .databaseBuilder(name)
          .addMigrations([migration])
          .fallbackToDestructiveMigration()
          .build();

      expect(await database.itemDao.findAllItems(), hasLength(1));
      expect(await schemaObjectNames(database), contains('Parent'));
      await database.close();
    });
  });
}

@entity
class Item {
  @primaryKey
  final int id;

  final String? name;

  Item(this.id, this.name);
}

@dao
abstract class ItemDao {
  @Query('SELECT * FROM Item')
  Future<List<Item>> findAllItems();
}

@Database(version: 2, entities: [Item])
abstract class TestDatabase extends FroomDatabase {
  ItemDao get itemDao;
}
