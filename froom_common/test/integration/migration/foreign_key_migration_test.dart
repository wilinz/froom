import 'dart:async';

import 'package:froom_common/froom_common.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite;
import 'package:test/test.dart';

import '../../test_util/database_factory.dart';

part 'foreign_key_migration_test.g.dart';

void main() {
  group('foreign keys during migrations', () {
    late String name;
    late String path;

    setUp(() async {
      name = 'foreign_key_${DateTime.now().microsecondsSinceEpoch}.db';
      path = await sqfliteDatabaseFactory.getDatabasePath(name);
      final database = await sqfliteDatabaseFactory.openDatabase(
        path,
        options: sqflite.OpenDatabaseOptions(
          version: 1,
          onConfigure: (database) =>
              database.execute('PRAGMA foreign_keys = ON'),
          onCreate: (database, version) async {
            await database.execute(
                'CREATE TABLE `Parent` (`id` INTEGER NOT NULL, `title` TEXT NOT NULL, PRIMARY KEY (`id`))');
            await database.execute(
                'CREATE TABLE `Child` (`id` INTEGER NOT NULL, `parentId` INTEGER NOT NULL, FOREIGN KEY (`parentId`) REFERENCES `Parent` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE, PRIMARY KEY (`id`))');
            await database
                .execute("INSERT INTO Parent (id, title) VALUES (1, 'parent')");
            await database
                .execute('INSERT INTO Child (id, parentId) VALUES (1, 1)');
          },
        ),
      );
      await database.close();
    });

    tearDown(() async {
      await sqfliteDatabaseFactory.deleteDatabase(path);
    });

    Future<int> foreignKeysEnabled(final TestDatabase database) async {
      final rows = await database.database.rawQuery('PRAGMA foreign_keys');
      return rows.first.values.first as int;
    }

    test('recreating a parent table keeps its children', () async {
      // the steps of https://www.sqlite.org/lang_altertable.html#otheralter
      final migration = Migration(1, 2, (database) async {
        await database.execute(
            'CREATE TABLE `Parent_new` (`id` INTEGER NOT NULL, `name` TEXT NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'INSERT INTO Parent_new (id, name) SELECT id, title FROM Parent');
        await database.execute('DROP TABLE Parent');
        await database.execute('ALTER TABLE Parent_new RENAME TO Parent');
      });

      final database = await $FroomTestDatabase
          .databaseBuilder(name)
          .addMigrations([migration]).build();

      expect(await database.familyDao.findAllChildren(), hasLength(1));
      expect(await foreignKeysEnabled(database), equals(1));
      await database.close();
    });

    test('migrations violating foreign keys fail', () async {
      final migration = Migration(1, 2, (database) async {
        await database
            .execute("ALTER TABLE Parent RENAME COLUMN title TO name");
        await database.execute('INSERT INTO Child (id, parentId) VALUES (2, 9)');
      });

      final actual =
          $FroomTestDatabase.databaseBuilder(name).addMigrations([migration]).build();

      await expectLater(actual, throwsStateError);
      // the migration got rolled back and fails again on the next opening
      final database = await sqfliteDatabaseFactory.openDatabase(path);
      expect(await database.getVersion(), equals(1));
      expect(await database.rawQuery('SELECT * FROM Child'), hasLength(1));
      await database.close();
      final retry =
          $FroomTestDatabase.databaseBuilder(name).addMigrations([migration]).build();
      await expectLater(retry, throwsStateError);
    });

    test('foreign keys are enabled without migrations', () async {
      final database = await $FroomTestDatabase.inMemoryDatabaseBuilder().build();

      expect(await foreignKeysEnabled(database), equals(1));
      await database.close();
    });
  });
}

@entity
class Parent {
  @primaryKey
  final int id;

  final String name;

  Parent(this.id, this.name);
}

@Entity(foreignKeys: [
  ForeignKey(
    childColumns: ['parentId'],
    parentColumns: ['id'],
    entity: Parent,
    onDelete: ForeignKeyAction.cascade,
  ),
])
class Child {
  @primaryKey
  final int id;

  final int parentId;

  Child(this.id, this.parentId);
}

@dao
abstract class FamilyDao {
  @Query('SELECT * FROM Child')
  Future<List<Child>> findAllChildren();
}

@Database(version: 2, entities: [Parent, Child])
abstract class TestDatabase extends FroomDatabase {
  FamilyDao get familyDao;
}
