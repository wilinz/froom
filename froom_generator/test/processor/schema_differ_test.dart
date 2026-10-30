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
      'ALTER TABLE `Singer` RENAME TO `Artist`',
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

  test('new table with the prefix of recreated tables fails', () {
    final actual = () => SchemaDiffer(
          schema(1, [person]),
          schema(2, [person, table('_new_Song', [id])]),
        ).diffSchemas();

    expect(actual, throwsA(isA<SchemaDiffException>()));
  });

  test('schema survives JSON round trip', () {
    final original = schema(1, [person], [ViewSchema('Names', 'CREATE VIEW')]);

    final actual = DatabaseSchema.fromJson(original.toJson());

    expect(actual.toJsonString(), equals(original.toJsonString()));
  });
}
