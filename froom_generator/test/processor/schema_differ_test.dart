import 'package:froom_generator/processor/schema_differ.dart';
import 'package:froom_generator/value_object/auto_migration.dart';
import 'package:froom_generator/value_object/schema.dart';
import 'package:froom_generator/writer/auto_migration_writer.dart';
import 'package:test/test.dart';

void main() {
  EntitySchema table(
    final String name,
    final List<FieldSchema> fields, {
    final List<String> primaryKey = const ['id'],
    final List<IndexSchema> indices = const [],
    final List<ForeignKeySchema> foreignKeys = const [],
    final String? fts,
  }) {
    final columns = fields
        .map((field) =>
            '`${field.columnName}` ${field.affinity}${field.notNull ? ' NOT NULL' : ''}')
        .join(', ');
    final createSql = fts == null
        ? 'CREATE TABLE IF NOT EXISTS `\${TABLE_NAME}` ($columns, PRIMARY KEY (`id`))'
        : 'CREATE VIRTUAL TABLE IF NOT EXISTS `\${TABLE_NAME}` $fts($columns)';
    return EntitySchema(
      name,
      createSql,
      fields,
      PrimaryKeySchema(primaryKey, false),
      indices,
      foreignKeys,
      false,
      fts,
    );
  }

  FieldSchema column(
    final String name, {
    final String affinity = 'TEXT',
    final bool notNull = false,
    final String? defaultValue,
  }) =>
      FieldSchema(name, affinity, notNull, defaultValue);

  final id = column('id', affinity: 'INTEGER', notNull: true);
  final person = table('Person', [id, column('name')]);

  DatabaseSchema schema(
    final int version,
    final List<EntitySchema> entities, [
    final List<ViewSchema> views = const [],
  ]) =>
      DatabaseSchema(version, entities, views);

  List<String> statements(
    final SchemaDiff diff, {
    final int from = 1,
    final int to = 2,
  }) =>
      AutoMigrationWriter(AutoMigration(from, to, null, false, diff))
          .getStatements();

  test('no changes', () {
    final actual = SchemaDiffer(schema(1, [person]), schema(2, [person]))
        .diffSchemas();

    expect(statements(actual), isEmpty);
  });

  test('added table with index', () {
    final song = table('Song', [id, column('title')], indices: [
      IndexSchema('index_Song_title', false, ['title'],
          'CREATE INDEX IF NOT EXISTS `index_Song_title` ON `\${TABLE_NAME}` (`title`)'),
    ]);

    final actual = SchemaDiffer(schema(1, [person]), schema(2, [person, song]))
        .diffSchemas();

    expect(statements(actual), [
      'CREATE TABLE IF NOT EXISTS `Song` (`id` INTEGER NOT NULL, `title` TEXT, PRIMARY KEY (`id`))',
      'CREATE INDEX IF NOT EXISTS `index_Song_title` ON `Song` (`title`)',
    ]);
  });

  test('added columns', () {
    final newPerson = table('Person', [
      id,
      column('name'),
      column('age', affinity: 'INTEGER', notNull: true, defaultValue: '0'),
      column('nickname'),
    ]);

    final actual =
        SchemaDiffer(schema(1, [person]), schema(2, [newPerson])).diffSchemas();

    expect(statements(actual), [
      'ALTER TABLE `Person` ADD COLUMN `age` INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE `Person` ADD COLUMN `nickname` TEXT',
    ]);
  });

  test('added NOT NULL column without default value fails', () {
    final newPerson =
        table('Person', [id, column('name'), column('age', notNull: true)]);

    final actual = () =>
        SchemaDiffer(schema(1, [person]), schema(2, [newPerson])).diffSchemas();

    expect(actual, throwsA(isA<SchemaDiffException>()));
  });

  test('deleted or renamed table without spec fails', () {
    final actual =
        () => SchemaDiffer(schema(1, [person]), schema(2, [])).diffSchemas();

    expect(
      actual,
      throwsA(isA<SchemaDiffException>().having((exception) => exception.message,
          'message', contains('@DeleteTable'))),
    );
  });

  test('deleted and renamed tables', () {
    final album = table('Album', [id]);
    final singer = table('Singer', [id, column('name')]);
    final artist = table('Artist', [id, column('name')]);

    final actual = SchemaDiffer(
      schema(1, [album, singer]),
      schema(2, [artist]),
      specName: 'Spec',
      renamedTables: [RenamedTable('Singer', 'Artist')],
      deletedTables: [DeletedTable('Album')],
    ).diffSchemas();

    expect(statements(actual), [
      'DROP TABLE `Album`',
      'ALTER TABLE `Singer` RENAME TO `_new_Artist`',
      'ALTER TABLE `_new_Artist` RENAME TO `Artist`',
    ]);
  });

  test('deleted or renamed column without spec fails', () {
    final newPerson = table('Person', [id]);

    final actual = () =>
        SchemaDiffer(schema(1, [person]), schema(2, [newPerson])).diffSchemas();

    expect(
      actual,
      throwsA(isA<SchemaDiffException>().having((exception) => exception.message,
          'message', contains('@DeleteColumn'))),
    );
  });

  test('renamed and deleted columns recreate the table', () {
    final oldPerson =
        table('Person', [id, column('name'), column('nickname')]);
    final newPerson = table('Person', [id, column('fullName')]);

    final actual = SchemaDiffer(
      schema(1, [oldPerson]),
      schema(2, [newPerson]),
      specName: 'Spec',
      renamedColumns: [RenamedColumn('Person', 'name', 'fullName')],
      deletedColumns: [DeletedColumn('Person', 'nickname')],
    ).diffSchemas();

    expect(statements(actual), [
      'CREATE TABLE IF NOT EXISTS `_new_Person` (`id` INTEGER NOT NULL, `fullName` TEXT, PRIMARY KEY (`id`))',
      'INSERT INTO `_new_Person` (`id`, `fullName`) SELECT `id`, `name` FROM `Person`',
      'DROP TABLE `Person`',
      'ALTER TABLE `_new_Person` RENAME TO `Person`',
    ]);
  });

  test('changed column type recreates the table', () {
    final newPerson =
        table('Person', [id, column('name', affinity: 'INTEGER')]);

    final actual =
        SchemaDiffer(schema(1, [person]), schema(2, [newPerson])).diffSchemas();

    expect(actual.complexChangedTables, hasLength(1));
    expect(statements(actual).first, contains('`_new_Person`'));
  });

  test('changed foreign key recreates the table', () {
    ForeignKeySchema foreignKey(final String onDelete) =>
        ForeignKeySchema('Person', ['ownerId'], ['id'], 'NO ACTION', onDelete);
    final fields = [id, column('ownerId', affinity: 'INTEGER')];
    final oldPet = table('Pet', fields, foreignKeys: [foreignKey('CASCADE')]);
    final newPet = table('Pet', fields, foreignKeys: [foreignKey('RESTRICT')]);

    final actual =
        SchemaDiffer(schema(1, [person, oldPet]), schema(2, [person, newPet]))
            .diffSchemas();

    expect(actual.complexChangedTables.single.toTable.tableName, 'Pet');
  });

  test('foreign keys to renamed tables recreate the table', () {
    final singer = table('Singer', [id]);
    final artist = table('Artist', [id]);
    final fields = [id, column('singerId', affinity: 'INTEGER')];
    ForeignKeySchema foreignKey(final String table) =>
        ForeignKeySchema(table, ['singerId'], ['id'], 'NO ACTION', 'NO ACTION');
    final oldSong = table('Song', fields, foreignKeys: [foreignKey('Singer')]);
    final newSong = table('Song', fields, foreignKeys: [foreignKey('Artist')]);

    final actual = SchemaDiffer(
      schema(1, [singer, oldSong]),
      schema(2, [artist, newSong]),
      specName: 'Spec',
      renamedTables: [RenamedTable('Singer', 'Artist')],
    ).diffSchemas();

    expect(actual.renamedTables, {'Singer': 'Artist'});
    expect(actual.complexChangedTables.single.toTable.tableName, 'Song');
  });

  test('changed FTS table is recreated after other tables', () {
    final fields = [column('rowid', affinity: 'INTEGER'), column('text')];
    final oldMail = table('Mail', fields, fts: 'USING fts4');
    final newMail =
        table('Mail', fields, fts: 'USING fts4 tokenize=unicode61');
    final newPerson =
        table('Person', [id, column('name', affinity: 'INTEGER')]);

    final actual = SchemaDiffer(
      schema(1, [oldMail, person]),
      schema(2, [newMail, newPerson]),
    ).diffSchemas();

    final creations = statements(actual)
        .where((statement) => statement.startsWith('CREATE'))
        .toList();
    expect(creations.first, contains('`_new_Person`'));
    expect(creations.last, contains('`_new_Mail` USING fts4 tokenize=unicode61'));
  });

  test('views are dropped and recreated', () {
    final actual = SchemaDiffer(
      schema(1, [person], [
        ViewSchema('Names', 'CREATE VIEW IF NOT EXISTS `Names` AS SELECT name FROM Person'),
      ]),
      schema(2, [person], [
        ViewSchema('Names', 'CREATE VIEW IF NOT EXISTS `Names` AS SELECT name, id FROM Person'),
      ]),
    ).diffSchemas();

    expect(statements(actual), [
      'DROP VIEW IF EXISTS `Names`',
      'CREATE VIEW IF NOT EXISTS `Names` AS SELECT name, id FROM Person',
    ]);
  });

  test('table with the temporary name of a recreated table fails', () {
    final newPerson =
        table('Person', [id, column('name', affinity: 'INTEGER')]);

    final actual = () => SchemaDiffer(
          schema(1, [person]),
          schema(2, [newPerson, table('_new_Person', [id])]),
        ).diffSchemas();

    expect(actual, throwsA(isA<SchemaDiffException>()));
  });

  test('table with the temporary name of a renamed table fails', () {
    final unchanged = table('_new_Artist', [id]);

    final actual = () => SchemaDiffer(
          schema(1, [table('Singer', [id]), unchanged]),
          schema(2, [table('Artist', [id]), unchanged]),
          renamedTables: [RenamedTable('Singer', 'Artist')],
        ).diffSchemas();

    expect(actual, throwsA(isA<SchemaDiffException>()));
  });

  test('new table with the prefix of temporary names without conflict', () {
    final actual = SchemaDiffer(
      schema(1, [person]),
      schema(2, [person, table('_new_items', [id])]),
    ).diffSchemas();

    expect(actual.addedTables.single.tableName, '_new_items');
  });

  test('recreated table without old columns copies no data', () {
    final oldSong = table('Song', [id, column('genre')]);
    final newSong = table('Song', [column('id'), column('year')]);

    final actual = SchemaDiffer(
      schema(1, [oldSong]),
      schema(2, [newSong]),
      specName: 'Spec',
      deletedColumns: [DeletedColumn('Song', 'id'), DeletedColumn('Song', 'genre')],
    ).diffSchemas();

    expect(
      statements(actual).where((statement) => statement.startsWith('INSERT')),
      isEmpty,
    );
  });

  test('deleted column of a renamed table', () {
    final singer = table('Singer', [id, column('name'), column('age')]);
    final artist = table('Artist', [id, column('name')]);

    final actual = SchemaDiffer(
      schema(1, [singer]),
      schema(2, [artist]),
      specName: 'Spec',
      renamedTables: [RenamedTable('Singer', 'Artist')],
      deletedColumns: [DeletedColumn('Singer', 'age')],
    ).diffSchemas();

    expect(statements(actual), [
      'CREATE TABLE IF NOT EXISTS `_new_Artist` (`id` INTEGER NOT NULL, `name` TEXT, PRIMARY KEY (`id`))',
      'INSERT INTO `_new_Artist` (`id`, `name`) SELECT `id`, `name` FROM `Singer`',
      'DROP TABLE `Singer`',
      'ALTER TABLE `_new_Artist` RENAME TO `Artist`',
    ]);
  });

  test('new table with the old name of a renamed table', () {
    final oldA = table('A', [id]);
    final newA = table('A', [id, column('name')]);
    final b = table('B', [id]);

    final actual = SchemaDiffer(
      schema(1, [oldA]),
      schema(2, [newA, b]),
      specName: 'Spec',
      renamedTables: [RenamedTable('A', 'B')],
    ).diffSchemas();

    expect(statements(actual), [
      'ALTER TABLE `A` RENAME TO `_new_B`',
      'ALTER TABLE `_new_B` RENAME TO `B`',
      'CREATE TABLE IF NOT EXISTS `A` (`id` INTEGER NOT NULL, `name` TEXT, PRIMARY KEY (`id`))',
    ]);
  });

  test('deleted table replaced by a renamed table', () {
    final a = table('A', [id]);
    final oldB = table('B', [id]);

    final actual = SchemaDiffer(
      schema(1, [a, oldB]),
      schema(2, [table('B', [id])]),
      specName: 'Spec',
      renamedTables: [RenamedTable('A', 'B')],
      deletedTables: [DeletedTable('B')],
    ).diffSchemas();

    expect(statements(actual), [
      'DROP TABLE `B`',
      'ALTER TABLE `A` RENAME TO `_new_B`',
      'ALTER TABLE `_new_B` RENAME TO `B`',
    ]);
  });

  test('new column with the old name of a renamed column gets no data', () {
    final oldSong = table('Song', [id, column('name')]);
    final newSong =
        table('Song', [id, column('title'), column('name', defaultValue: "''")]);

    final actual = SchemaDiffer(
      schema(1, [oldSong]),
      schema(2, [newSong]),
      specName: 'Spec',
      renamedColumns: [RenamedColumn('Song', 'name', 'title')],
    ).diffSchemas();

    expect(
      statements(actual),
      contains('INSERT INTO `_new_Song` (`id`, `title`) SELECT `id`, `name` FROM `Song`'),
    );
  });

  test('new NOT NULL column with the old name of a renamed column fails', () {
    final oldSong = table('Song', [id, column('name')]);
    final newSong =
        table('Song', [id, column('title'), column('name', notNull: true)]);

    final actual = () => SchemaDiffer(
          schema(1, [oldSong]),
          schema(2, [newSong]),
          specName: 'Spec',
          renamedColumns: [RenamedColumn('Song', 'name', 'title')],
        ).diffSchemas();

    expect(actual, throwsA(isA<SchemaDiffException>()));
  });

  for (final (description, differ) in [
    (
      'renamed column not in the new version',
      () => SchemaDiffer(
            schema(1, [table('Song', [id, column('name')])]),
            schema(2, [table('Song', [id, column('title')])]),
            renamedColumns: [RenamedColumn('Song', 'name', 'titel')],
          ),
    ),
    (
      'renamed column not in the old version',
      () => SchemaDiffer(
            schema(1, [table('Song', [id, column('name')])]),
            schema(2, [table('Song', [id, column('title')])]),
            renamedColumns: [RenamedColumn('Song', 'nam', 'title')],
          ),
    ),
    (
      'deleted table not in the old version',
      () => SchemaDiffer(
            schema(1, [person]),
            schema(2, [person]),
            deletedTables: [DeletedTable('Albums')],
          ),
    ),
    (
      'deleted column not in the old version',
      () => SchemaDiffer(
            schema(1, [person]),
            schema(2, [person]),
            deletedColumns: [DeletedColumn('Person', 'nickname')],
          ),
    ),
    (
      'column renamed to an existing column',
      () => SchemaDiffer(
            schema(1, [table('T', [id, column('a'), column('b')])]),
            schema(2, [table('T', [id, column('b')])]),
            renamedColumns: [RenamedColumn('T', 'a', 'b')],
          ),
    ),
    (
      'deleted column of a deleted table',
      () => SchemaDiffer(
            schema(1, [table('T', [id, column('x')])]),
            schema(2, [table('T', [id])]),
            deletedTables: [DeletedTable('T')],
            deletedColumns: [DeletedColumn('T', 'x')],
          ),
    ),
    (
      'tables renamed to the same table',
      () => SchemaDiffer(
            schema(1, [table('A', [id]), table('B', [id])]),
            schema(2, [table('C', [id])]),
            renamedTables: [RenamedTable('A', 'C'), RenamedTable('B', 'C')],
          ),
    ),
    (
      'table renamed to an existing table',
      () => SchemaDiffer(
            schema(1, [table('A', [id]), table('B', [id])]),
            schema(2, [table('B', [id])]),
            renamedTables: [RenamedTable('A', 'B')],
          ),
    ),
  ]) {
    test('spec with $description fails', () {
      expect(
        () => differ().diffSchemas(),
        throwsA(isA<SchemaDiffException>()),
      );
    });
  }

  test('deleted and added columns recreate the table once', () {
    final oldSong = table('Song', [id, column('genre')]);
    final newSong = table('Song', [id, column('year', defaultValue: '0')]);

    final actual = SchemaDiffer(
      schema(1, [oldSong]),
      schema(2, [newSong]),
      specName: 'Spec',
      deletedColumns: [DeletedColumn('Song', 'genre')],
    ).diffSchemas();

    expect(actual.addedColumns, isEmpty);
    expect(actual.complexChangedTables, hasLength(1));
  });

  test('added column with non-constant default value recreates the table', () {
    final newPerson = table('Person', [
      id,
      column('name'),
      column('createdAt', notNull: true, defaultValue: 'CURRENT_TIMESTAMP'),
    ]);

    final actual =
        SchemaDiffer(schema(1, [person]), schema(2, [newPerson])).diffSchemas();

    expect(actual.addedColumns, isEmpty);
    expect(statements(actual), [
      'CREATE TABLE IF NOT EXISTS `_new_Person` (`id` INTEGER NOT NULL, `name` TEXT, `createdAt` TEXT NOT NULL, PRIMARY KEY (`id`))',
      'INSERT INTO `_new_Person` (`id`, `name`) SELECT `id`, `name` FROM `Person`',
      'DROP TABLE `Person`',
      'ALTER TABLE `_new_Person` RENAME TO `Person`',
    ]);
  });

  test('renamed tables swapping their names', () {
    final a = table('A', [id, column('a')]);
    final b = table('B', [id, column('b')]);

    final actual = SchemaDiffer(
      schema(1, [a, b]),
      schema(2, [table('B', [id, column('a')]), table('A', [id, column('b')])]),
      specName: 'Spec',
      renamedTables: [RenamedTable('A', 'B'), RenamedTable('B', 'A')],
    ).diffSchemas();

    expect(statements(actual), [
      'ALTER TABLE `A` RENAME TO `_new_B`',
      'ALTER TABLE `B` RENAME TO `_new_A`',
      'ALTER TABLE `_new_B` RENAME TO `B`',
      'ALTER TABLE `_new_A` RENAME TO `A`',
    ]);
  });

  test('table renamed to the old name of a recreated table', () {
    final a = table('A', [id]);
    final b = table('B', [id, column('name')]);

    final actual = SchemaDiffer(
      schema(1, [a, b]),
      schema(2, [table('B', [id]), table('C', [id, column('title')])]),
      specName: 'Spec',
      renamedTables: [RenamedTable('A', 'B'), RenamedTable('B', 'C')],
      renamedColumns: [RenamedColumn('B', 'name', 'title')],
    ).diffSchemas();

    expect(statements(actual), [
      'ALTER TABLE `A` RENAME TO `_new_B`',
      'CREATE TABLE IF NOT EXISTS `_new_C` (`id` INTEGER NOT NULL, `title` TEXT, PRIMARY KEY (`id`))',
      'INSERT INTO `_new_C` (`id`, `title`) SELECT `id`, `name` FROM `B`',
      'DROP TABLE `B`',
      'ALTER TABLE `_new_B` RENAME TO `B`',
      'ALTER TABLE `_new_C` RENAME TO `C`',
    ]);
  });

  test('new table with the old name of a recreated renamed table', () {
    final x = table('X', [id]);

    final actual = SchemaDiffer(
      schema(1, [x]),
      schema(2, [table('Y', [id, column('name')]), table('X', [id])]),
      specName: 'Spec',
      renamedTables: [RenamedTable('X', 'Y')],
    ).diffSchemas();

    final creations = statements(actual);
    expect(creations.indexOf('DROP TABLE `X`'),
        lessThan(creations.indexWhere((statement) => statement.startsWith('CREATE TABLE IF NOT EXISTS `X`'))));
  });

  test('table both deleted and renamed fails', () {
    final actual = () => SchemaDiffer(
          schema(1, [table('A', [id])]),
          schema(2, [table('B', [id])]),
          renamedTables: [RenamedTable('A', 'B')],
          deletedTables: [DeletedTable('A')],
        ).diffSchemas();

    expect(actual, throwsA(isA<SchemaDiffException>()));
  });

  test('changed indices are dropped and created without recreating the table',
      () {
    IndexSchema index(final String column) => IndexSchema(
        'index_Person_$column',
        false,
        [column],
        'CREATE INDEX IF NOT EXISTS `index_Person_$column` ON `\${TABLE_NAME}` (`$column`)');
    final oldPerson = table('Person', [id, column('name'), column('age')],
        indices: [index('name')]);
    final newPerson = table('Person', [id, column('name'), column('age')],
        indices: [index('age')]);

    final actual =
        SchemaDiffer(schema(1, [oldPerson]), schema(2, [newPerson])).diffSchemas();

    expect(actual.complexChangedTables, isEmpty);
    expect(statements(actual), [
      'DROP INDEX IF EXISTS `index_Person_name`',
      'CREATE INDEX IF NOT EXISTS `index_Person_age` ON `Person` (`age`)',
    ]);
  });

  test('schema survives JSON round trip', () {
    final original = schema(1, [person], [ViewSchema('Names', 'CREATE VIEW')]);

    final actual = DatabaseSchema.fromJson(original.toJson());

    expect(actual.toJsonString(), equals(original.toJsonString()));
  });
}
