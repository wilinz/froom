import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:froom_common/froom_common.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite;
import 'package:test/test.dart';

import '../../test_util/database_factory.dart';

part 'auto_migration_test.g.dart';

void main() {
  group('automatic migrations', () {
    late String name;
    late String path;

    setUp(() async {
      name = 'auto_migration_${DateTime.now().microsecondsSinceEpoch}.db';
      path = await sqfliteDatabaseFactory.getDatabasePath(name);
      await _createFirstVersion(path);
    });

    tearDown(() async {
      await sqfliteDatabaseFactory.deleteDatabase(path);
    });

    test('migrate data to the latest version', () async {
      final spec = SecondAutoMigrationSpec();
      final database = await $FroomAutoMigrationDatabase
          .databaseBuilder(name)
          .addAutoMigrationSpecs([spec]).build();
      addTearDown(database.close);
      final executor = database.database;

      expect(await executor.query('Person'), [
        {'id': 1, 'fullName': 'Simon', 'age': 0},
        {'id': 2, 'fullName': 'Frank', 'age': 0},
      ]);
      expect(await executor.query('Pet'), [
        {'id': 1, 'ownerId': 1, 'name': 'Rex', 'species': null},
      ]);
      expect(await executor.query('Artist'), [
        {'id': 1, 'name': 'Adele', 'country': null},
      ]);
      expect(await executor.query('Song'), [
        {'id': 1, 'title': 'migrated'},
      ]);
      expect(
        await executor.rawQuery("SELECT text FROM note WHERE note MATCH 'hello'"),
        [
          {'text': 'hello world'},
        ],
      );
      expect(
        await executor.query('PersonName'),
        unorderedEquals([
          {'name': 'Simon'},
          {'name': 'Frank'},
        ]),
      );
      expect(spec.isMigrated, isTrue);
    });

    test('migrated schema equals the schema of a new database', () async {
      final database = await $FroomAutoMigrationDatabase
          .databaseBuilder(name)
          .addAutoMigrationSpecs([SecondAutoMigrationSpec()]).build();
      addTearDown(database.close);
      final newDatabase = await $FroomAutoMigrationDatabase
          .inMemoryDatabaseBuilder()
          .addAutoMigrationSpecs([SecondAutoMigrationSpec()]).build();
      addTearDown(newDatabase.close);

      expect(
        await _describeSchema(database.database),
        equals(await _describeSchema(newDatabase.database)),
      );
      // the auto generated primary key and the changed foreign key work
      await database.database.insert('Person', {'fullName': 'Jane'});
      expect(
        await database.database.query('Person', where: "fullName = 'Jane'"),
        [
          {'id': 3, 'fullName': 'Jane', 'age': 0},
        ],
      );
      await expectLater(
        database.database.delete('Person', where: 'id = 1'),
        throwsA(isA<sqflite.DatabaseException>()),
      );
    });

    test('migrations of the builder replace automatic ones', () async {
      var isMigrated = false;
      final migration = Migration(2, 3, (database) async {
        isMigrated = true;
      });

      final database = await $FroomAutoMigrationDatabase
          .databaseBuilder(name)
          .addMigrations([migration]).build();
      addTearDown(database.close);

      expect(isMigrated, isTrue);
      expect(await database.database.query('Song'), hasLength(1));
    });

    test('missing provided spec fails', () async {
      final actual =
          $FroomAutoMigrationDatabase.databaseBuilder(name).build();

      await expectLater(actual, throwsStateError);
    });
  });
}

/// Creates the first version of the database from its exported schema.
Future<void> _createFirstVersion(final String path) async {
  final file = File('froom_schemas/test/integration/auto_migration/'
      'auto_migration_test/AutoMigrationDatabase/1.json');
  final schema = (jsonDecode(file.readAsStringSync())
      as Map<String, Object?>)['database'] as Map<String, Object?>;

  final database = await sqfliteDatabaseFactory.openDatabase(
    path,
    options: sqflite.OpenDatabaseOptions(
      version: 1,
      onCreate: (database, version) async {
        for (final entity in (schema['entities'] as List).cast<Map>()) {
          final tableName = entity['tableName'] as String;
          await database.execute((entity['createSql'] as String)
              .replaceFirst(r'${TABLE_NAME}', tableName));
          for (final index in (entity['indices'] as List).cast<Map>()) {
            await database.execute((index['createSql'] as String)
                .replaceFirst(r'${TABLE_NAME}', tableName));
          }
        }
        for (final view in (schema['views'] as List).cast<Map>()) {
          await database.execute(view['createSql'] as String);
        }
      },
    ),
  );
  await database.insert('Person', {'id': 1, 'name': 'Simon', 'nickname': 'Si'});
  await database.insert('Person', {'id': 2, 'name': 'Frank'});
  await database.insert('Pet', {'id': 1, 'ownerId': 1, 'name': 'Rex'});
  await database.insert('Singer', {'id': 1, 'name': 'Adele'});
  await database.insert('Album', {'id': 1, 'title': '21'});
  await database.insert('note', {'rowid': 1, 'text': 'hello world'});
  await database.close();
}

/// The tables, columns, indices, foreign keys and views of the [database].
Future<Map<String, Object?>> _describeSchema(
  final sqflite.DatabaseExecutor database,
) async {
  final objects = await database.rawQuery(
    "SELECT type, name, tbl_name FROM sqlite_master WHERE name NOT LIKE 'sqlite_%' AND name NOT LIKE 'note_%' ORDER BY name",
  );
  final tables = objects
      .where((object) => object['type'] == 'table')
      .map((object) => object['name'] as String);
  return {
    'objects': objects,
    for (final table in tables) ...{
      '$table columns': await database.rawQuery('PRAGMA table_info(`$table`)'),
      '$table foreign keys':
          await database.rawQuery('PRAGMA foreign_key_list(`$table`)'),
      '$table indices': await database.rawQuery('PRAGMA index_list(`$table`)'),
    },
  };
}

@Entity(indices: [Index(value: ['fullName'])])
class Person {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String fullName;

  @ColumnInfo(defaultValue: '0')
  final int age;

  Person(this.id, this.fullName, this.age);
}

@Entity(
  foreignKeys: [
    ForeignKey(
      childColumns: ['ownerId'],
      parentColumns: ['id'],
      entity: Person,
      onDelete: ForeignKeyAction.restrict,
    ),
  ],
  indices: [Index(value: ['name'])],
)
class Pet {
  @primaryKey
  final int id;

  final int ownerId;

  final String name;

  final String? species;

  Pet(this.id, this.ownerId, this.name, this.species);
}

@entity
class Artist {
  @primaryKey
  final int id;

  final String name;

  final String? country;

  Artist(this.id, this.name, this.country);
}

@Entity(indices: [Index(value: ['title'])])
class Song {
  @primaryKey
  final int id;

  final String title;

  Song(this.id, this.title);
}

@Entity(tableName: 'note')
@Fts4(tokenizer: FtsTokenizer.unicode61)
class Note {
  @PrimaryKey()
  @ColumnInfo(name: 'rowid')
  final int id;

  final String text;

  Note(this.id, this.text);
}

@DatabaseView('SELECT fullName AS name FROM Person', viewName: 'PersonName')
class PersonName {
  final String name;

  PersonName(this.name);
}

@RenameColumn(tableName: 'Person', fromColumnName: 'name', toColumnName: 'fullName')
@DeleteColumn(tableName: 'Person', columnName: 'nickname')
@RenameTable(fromTableName: 'Singer', toTableName: 'Artist')
@DeleteTable(tableName: 'Album')
class FirstAutoMigrationSpec extends AutoMigrationSpec {
  @override
  Future<void> onPostMigrate(final sqflite.Database database) async {
    await database.insert('Song', {'id': 1, 'title': 'migrated'});
  }
}

@providedAutoMigrationSpec
class SecondAutoMigrationSpec extends AutoMigrationSpec {
  var isMigrated = false;

  @override
  void onPostMigrate(final sqflite.Database database) {
    isMigrated = true;
  }
}

@Database(
  version: 3,
  entities: [Person, Pet, Artist, Song, Note],
  views: [PersonName],
  autoMigrations: [
    AutoMigration(from: 1, to: 2, spec: FirstAutoMigrationSpec),
    AutoMigration(from: 2, to: 3, spec: SecondAutoMigrationSpec),
  ],
)
abstract class AutoMigrationDatabase extends FroomDatabase {}
