import 'package:analyzer/dart/element/element.dart';
import 'package:build_test/build_test.dart';
import 'package:froom_annotation/froom_annotation.dart' as annotations;
import 'package:froom_generator/processor/entity_processor.dart';
import 'package:froom_generator/processor/error/entity_processor_error.dart';
import 'package:froom_generator/processor/error/queryable_processor_error.dart';
import 'package:froom_generator/processor/field_processor.dart';
import 'package:froom_generator/value_object/entity.dart';
import 'package:froom_generator/value_object/foreign_key.dart';
import 'package:froom_generator/value_object/fts.dart';
import 'package:froom_generator/value_object/index.dart';
import 'package:froom_generator/value_object/primary_key.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  test('Process entity', () async {
    final classElement = await createClassElement('''
      @entity
      class Person {
        @primaryKey
        final int id;
      
        final String name;
      
        Person(this.id, this.name);
      }
    ''');

    final actual = EntityProcessor(classElement, {}).process();

    const name = 'Person';
    final fields = classElement.fields
        .map((fieldElement) => FieldProcessor(fieldElement, null).process())
        .toList();
    final primaryKey = PrimaryKey([fields[0]], false);
    const foreignKeys = <ForeignKey>[];
    const indices = <Index>[];
    const constructor = "Person(row['id'] as int, row['name'] as String)";
    const valueMapping = "<String, Object?>{'id': item.id, 'name': item.name}";
    final expected = Entity(
      classElement,
      name,
      fields,
      primaryKey,
      foreignKeys,
      indices,
      false,
      constructor,
      valueMapping,
      null,
    );
    expect(actual, equals(expected));
  });

  test(
      'Process entity with null fields falls back to defaults (should be prevented by non-nullable types)',
      () async {
    final classElement = await createClassElement('''
      @Entity(
      tableName:null,
      foreignKeys:null,
      indices:null,
      primaryKeys:null,
      withoutRowid:null,
      )
      @Fts3()
      class Person {
        @primaryKey
        final int id;
      
        final String name;
      
        Person(this.id, this.name);
      }
    ''');

    final actual = EntityProcessor(classElement, {}).process();

    const name = 'Person';
    final fields = classElement.fields
        .map((fieldElement) => FieldProcessor(fieldElement, null).process())
        .toList();
    final primaryKey = PrimaryKey([fields[0]], false);
    const foreignKeys = <ForeignKey>[];
    const indices = <Index>[];
    const constructor = "Person(row['id'] as int, row['name'] as String)";
    const valueMapping = "<String, Object?>{'id': item.id, 'name': item.name}";
    final expected = Entity(
      classElement,
      name,
      fields,
      primaryKey,
      foreignKeys,
      indices,
      false,
      constructor,
      valueMapping,
      Fts3(annotations.FtsTokenizer.simple, []),
    );
    expect(actual, equals(expected));
  });

  test('Process entity with compound primary key', () async {
    final classElement = await createClassElement('''
      @Entity(primaryKeys: ['id', 'name'])
      class Person {
        final int id;
      
        final String name;
      
        Person(this.id, this.name);
      }
    ''');

    final actual = EntityProcessor(classElement, {}).process();

    const name = 'Person';
    final fields = classElement.fields
        .map((fieldElement) => FieldProcessor(fieldElement, null).process())
        .toList();
    final primaryKey = PrimaryKey(fields, false);
    const foreignKeys = <ForeignKey>[];
    const indices = <Index>[];
    const constructor = "Person(row['id'] as int, row['name'] as String)";
    const valueMapping = "<String, Object?>{'id': item.id, 'name': item.name}";
    final expected = Entity(
      classElement,
      name,
      fields,
      primaryKey,
      foreignKeys,
      indices,
      false,
      constructor,
      valueMapping,
      null,
    );
    expect(actual, equals(expected));
  });

  test('Process entity with index', () async {
    final classElement = await createClassElement('''
      @Entity(indices: [Index(name:'i1', unique: true, value:['id']),Index(unique: false, value:['name', 'id'])])
      class Person {
        @primaryKey
        final int id;
      
        final String name;
      
        Person(this.id, this.name);
      }
    ''');

    final actual = EntityProcessor(classElement, {}).process();

    const name = 'Person';
    final fields = classElement.fields
        .map((fieldElement) => FieldProcessor(fieldElement, null).process())
        .toList();
    final primaryKey = PrimaryKey(fields.sublist(0, 1), false);
    const foreignKeys = <ForeignKey>[];
    final indices = [
      Index('i1', 'Person', true, ['id']),
      Index('index_Person_name_id', 'Person', false, ['name', 'id'])
    ];
    const constructor = "Person(row['id'] as int, row['name'] as String)";
    const valueMapping = "<String, Object?>{'id': item.id, 'name': item.name}";
    final expected = Entity(
      classElement,
      name,
      fields,
      primaryKey,
      foreignKeys,
      indices,
      false,
      constructor,
      valueMapping,
      null,
    );
    expect(actual, equals(expected));
  });

  test(
      'Process entity with named constructor declarations first, before unnamed ones.',
      () async {
    final classElement = await createClassElement('''
      @entity
      class Person {
        @primaryKey
        final int id;
      
        final String name;

        factory Person.from(Person other) {
          return Person(other.id, other.name);
        }
      
        Person(this.id, this.name);
      }
    ''');

    final actual = EntityProcessor(classElement, {}).process();

    const name = 'Person';
    final fields = classElement.fields
        .map((fieldElement) => FieldProcessor(fieldElement, null).process())
        .toList();
    final primaryKey = PrimaryKey([fields[0]], false);
    const foreignKeys = <ForeignKey>[];
    const indices = <Index>[];
    const constructor = "Person(row['id'] as int, row['name'] as String)";
    const valueMapping = "<String, Object?>{'id': item.id, 'name': item.name}";
    final expected = Entity(
      classElement,
      name,
      fields,
      primaryKey,
      foreignKeys,
      indices,
      false,
      constructor,
      valueMapping,
      null,
    );
    expect(actual, equals(expected));
  });

  test('Maps unset auto generated primary key to NULL when inserting',
      () async {
    final classElement = await createClassElement('''
      @entity
      class Person {
        @PrimaryKey(autoGenerate: true)
        final int id;
      
        final String name;
      
        Person(this.id, this.name);
      }
    ''');

    final actual = EntityProcessor(classElement, {}).process();

    expect(actual.valueMapping,
        equals("<String, Object?>{'id': item.id, 'name': item.name}"));
    expect(
      actual.insertionValueMapping,
      equals("<String, Object?>{'id': item.id == 0 ? null : item.id, "
          "'name': item.name}"),
    );
  });

  test('Keeps nullable auto generated primary key when inserting', () async {
    final classElement = await createClassElement('''
      @entity
      class Person {
        @PrimaryKey(autoGenerate: true)
        final int? id;
      
        final String name;
      
        Person(this.id, this.name);
      }
    ''');

    final actual = EntityProcessor(classElement, {}).process();

    expect(actual.insertionValueMapping, equals(actual.valueMapping));
  });

  test('Uses converter of non-nullable type for nullable fields', () async {
    final classElement = await createClassElement('''
      @entity
      @TypeConverters([DateTimeConverter])
      class Order {
        @primaryKey
        final int id;
      
        final DateTime createdAt;
      
        final DateTime? shippedAt;
      
        Order(this.id, this.createdAt, this.shippedAt);
      }
      
      class DateTimeConverter extends TypeConverter<DateTime, int> {
        @override
        DateTime decode(int databaseValue) =>
            DateTime.fromMillisecondsSinceEpoch(databaseValue);
      
        @override
        int encode(DateTime value) => value.millisecondsSinceEpoch;
      }
    ''');

    final actual = EntityProcessor(classElement, {}).process();

    expect(
      actual.constructor,
      equals("Order(row['id'] as int, "
          "_dateTimeConverter.decode(row['createdAt'] as int), "
          "row['shippedAt'] == null ? null : "
          "_dateTimeConverter.decode(row['shippedAt'] as int))"),
    );
    expect(
      actual.valueMapping,
      equals("<String, Object?>{'id': item.id, "
          "'createdAt': _dateTimeConverter.encode(item.createdAt), "
          "'shippedAt': item.shippedAt == null ? null : "
          "_dateTimeConverter.encode(item.shippedAt!)}"),
    );
    expect(
      actual.fields.map((field) => field.getDatabaseDefinition(false)),
      equals([
        '`id` INTEGER NOT NULL',
        '`createdAt` INTEGER NOT NULL',
        '`shippedAt` INTEGER',
      ]),
    );
  });

  test('Prefers the unnamed constructor over named ones declared before',
      () async {
    final classElement = await createClassElement('''
      @entity
      class Person {
        @primaryKey
        final int? id;
      
        final String? name;
      
        Person.empty() : id = null, name = null;
      
        Person(this.id, this.name);
      }
    ''');

    final actual = EntityProcessor(classElement, {}).process().constructor;

    expect(actual, equals("Person(row['id'] as int?, row['name'] as String?)"));
  });

  test('Calls a named constructor by its name', () async {
    final classElement = await createClassElement('''
      @entity
      class Person {
        @primaryKey
        final int id;
      
        final String name;
      
        Person.fromDatabase(this.id, this.name);
      }
    ''');

    final actual = EntityProcessor(classElement, {}).process().constructor;

    expect(
      actual,
      equals("Person.fromDatabase(row['id'] as int, row['name'] as String)"),
    );
  });

  test('Assigns fields not initialized by the constructor via setters',
      () async {
    final classElement = await createClassElement('''
      @entity
      class Person {
        @primaryKey
        int? id;
      
        String? name;
      
        bool active = false;
      
        final String constant = 'constant';
      }
    ''');

    final actual = EntityProcessor(classElement, {}).process().constructor;

    expect(
      actual,
      equals("Person()..id = (row['id'] as int?)"
          "..name = (row['name'] as String?)"
          "..active = ((row['active'] as int) != 0)"),
    );
  });

  test('Assigns only fields the constructor does not initialize', () async {
    final classElement = await createClassElement('''
      @entity
      class Person {
        @primaryKey
        final int id;
      
        String? name;
      
        Person(this.id);
      }
    ''');

    final actual = EntityProcessor(classElement, {}).process().constructor;

    expect(
      actual,
      equals("Person(row['id'] as int)..name = (row['name'] as String?)"),
    );
  });

  test('Process index on expressions', () async {
    final classElement = await createClassElement('''
      @Entity(indices: [Index(value: ['y + z', 'x'])])
      class Foo {
        @primaryKey
        final int x;
      
        final int y;
      
        final int z;
      
        Foo(this.x, this.y, this.z);
      }
    ''');

    final actual = EntityProcessor(classElement, {}).process().indices;

    expect(
      actual,
      equals([
        Index('index_Foo_y_z_x', 'Foo', false, ['y + z', 'x'],
            expressions: {'y + z'}),
      ]),
    );
  });

  test('Process index on column name containing special characters',
      () async {
    final classElement = await createClassElement('''
      @Entity(indices: [Index(value: ['first name'])])
      class Foo {
        @primaryKey
        final int id;
      
        @ColumnInfo(name: 'first name')
        final String firstName;
      
        Foo(this.id, this.firstName);
      }
    ''');

    final actual = EntityProcessor(classElement, {}).process().indices;

    expect(
      actual,
      equals([Index('index_Foo_first name', 'Foo', false, ['first name'])]),
    );
  });

  test('Process partial index', () async {
    final classElement = await createClassElement('''
      @Entity(indices: [
        Index(value: ['email'], unique: true, where: 'email IS NOT NULL')
      ])
      class Person {
        @primaryKey
        final int id;
      
        final String? email;
      
        Person(this.id, this.email);
      }
    ''');

    final actual = EntityProcessor(classElement, {}).process().indices;

    expect(
      actual,
      equals([
        Index('index_Person_email', 'Person', true, ['email'],
            where: 'email IS NOT NULL'),
      ]),
    );
  });

  test('Throws when a compound primary key column does not exist', () async {
    final classElement = await createClassElement('''
      @Entity(primaryKeys: ['foreign_id', 'time'])
      class Example {
        final int foreignId;
      
        final int time;
      
        Example(this.foreignId, this.time);
      }
    ''');

    final actual = () => EntityProcessor(classElement, {}).process();

    expect(
        actual,
        throwsInvalidGenerationSourceError(EntityProcessorError(classElement)
            .noMatchingPrimaryKeyColumn('foreign_id')));
  });

  group('foreign keys', () {
    test('foreign key holds correct values', () async {
      final classElements = await _createClassElements('''
        @entity
        class Person {
          @primaryKey
          final int id;
          
          final String name;
        
          Person(this.id, this.name);
        }
        
        @Entity(
          foreignKeys: [
            ForeignKey(
              childColumns: ['owner_id'],
              parentColumns: ['id'],
              entity: Person,
              onUpdate: ForeignKeyAction.cascade
              onDelete: ForeignKeyAction.setNull,
            )
          ],
        )
        class Dog {
          @primaryKey
          final int id;
        
          final String name;
        
          @ColumnInfo(name: 'owner_id')
          final int ownerId;
        
          Dog(this.id, this.name, this.ownerId);
        }
    ''');

      final actual =
          EntityProcessor(classElements[1], {}).process().foreignKeys[0];

      final expected = ForeignKey(
        'Person',
        ['id'],
        ['owner_id'],
        annotations.ForeignKeyAction.cascade,
        annotations.ForeignKeyAction.setNull,
      );
      expect(actual, equals(expected));
    });
  });

  group('fts keys', () {
    test('fts key with fts3', () async {
      final classElements = await _createClassElements('''
        
        @entity
        @fts3
        class MailInfo {
          @primaryKey
          @ColumnInfo(name: 'rowid')
          final int id;
        
          final String text;
        
          MailInfo(this.id, this.text);
        }
    ''');

      final actual = EntityProcessor(classElements[0], {}).process().fts;

      final Fts expected = Fts3('simple', []);

      expect(actual, equals(expected));
    });
  });

  group('fts keys', () {
    test('fts key with fts4', () async {
      final classElements = await _createClassElements('''
        
        @entity
        @fts4
        class MailInfo {
          @primaryKey
          @ColumnInfo(name: 'rowid')
          final int id;
        
          final String text;
        
          MailInfo(this.id, this.text);
        }
    ''');

      final actual = EntityProcessor(classElements[0], {}).process().fts;

      final Fts expected = Fts4('simple', []);

      expect(actual, equals(expected));
    });
  });

  group('fts5', () {
    test('creates the table without the row id and constraints', () async {
      final classElement = await createClassElement('''
        @entity
        @Fts5(
          tokenizer: FtsTokenizer.porter,
          tokenizerArgs: ['unicode61', 'remove_diacritics', '2'],
          prefixes: [2, 3],
          notIndexed: ['author'],
        )
        class Mail {
          @primaryKey
          @ColumnInfo(name: 'rowid')
          final int id;

          final String text;

          final String author;

          Mail(this.id, this.text, this.author);
        }
      ''');

      final actual = EntityProcessor(classElement, {}).process();

      expect(
        actual.fts,
        equals(Fts5('porter', ['unicode61', 'remove_diacritics', '2'], [2, 3],
            ['author'])),
      );
      expect(
        actual.getCreateTableStatement(),
        "CREATE VIRTUAL TABLE IF NOT EXISTS `Mail` USING fts5(`text`, "
        "`author` UNINDEXED, tokenize = 'porter unicode61 remove_diacritics 2', "
        "prefix = '2 3')",
      );
    });

    test('quotes tokenizer arguments which are not barewords', () async {
      final classElement = await createClassElement('''
        @entity
        @Fts5(tokenizerArgs: ['tokenchars', '-_', "'.'"], notIndexed: ['TEXT'])
        class Mail {
          @primaryKey
          @ColumnInfo(name: 'rowid')
          final int id;

          final String text;

          final String title;

          Mail(this.id, this.text, this.title);
        }
      ''');

      final actual = EntityProcessor(classElement, {}).process();

      expect(
        actual.getCreateTableStatement(),
        "CREATE VIRTUAL TABLE IF NOT EXISTS `Mail` USING fts5(`text` UNINDEXED, "
        "`title`, tokenize = 'unicode61 tokenchars ''-_'' ''.''')",
      );
    });

    test('uses the unicode61 tokenizer by default', () async {
      final classElement = await createClassElement('''
        @entity
        @fts5
        class Mail {
          @primaryKey
          @ColumnInfo(name: 'rowid')
          final int id;

          final String text;

          Mail(this.id, this.text);
        }
      ''');

      final actual = EntityProcessor(classElement, {}).process();

      expect(
        actual.getCreateTableStatement(),
        "CREATE VIRTUAL TABLE IF NOT EXISTS `Mail` USING fts5(`text`, "
        "tokenize = 'unicode61')",
      );
    });

    for (final (description, entity, error) in [
      (
        'primary key not of the row id',
        '''
        @entity
        @fts5
        class Mail {
          @primaryKey
          final int id;

          final String text;

          Mail(this.id, this.text);
        }
        ''',
        (EntityProcessorError error) => error.fts5PrimaryKeyIsNotRowid,
      ),
      (
        'row id column of another case',
        '''
        @entity
        @fts5
        class Mail {
          @primaryKey
          @ColumnInfo(name: 'RowId')
          final int id;

          final String text;

          Mail(this.id, this.text);
        }
        ''',
        (EntityProcessorError error) => error.fts5PrimaryKeyIsNotRowid,
      ),
      (
        'text row id',
        '''
        @entity
        @fts5
        class Mail {
          @primaryKey
          @ColumnInfo(name: 'rowid')
          final String id;

          final String text;

          Mail(this.id, this.text);
        }
        ''',
        (EntityProcessorError error) => error.fts5PrimaryKeyIsNotRowid,
      ),
      (
        'no columns besides the row id',
        '''
        @entity
        @fts5
        class Mail {
          @primaryKey
          @ColumnInfo(name: 'rowid')
          final int id;

          Mail(this.id);
        }
        ''',
        (EntityProcessorError error) => error.fts5WithoutColumns,
      ),
      (
        'unknown column of notIndexed',
        '''
        @entity
        @Fts5(notIndexed: ['autor'])
        class Mail {
          @primaryKey
          @ColumnInfo(name: 'rowid')
          final int id;

          final String text;

          Mail(this.id, this.text);
        }
        ''',
        (EntityProcessorError error) =>
            error.fts5UnknownNotIndexedColumns(['autor']),
      ),
      (
        'multiple FTS annotations',
        '''
        @entity
        @fts4
        @fts5
        class Mail {
          @primaryKey
          @ColumnInfo(name: 'rowid')
          final int id;

          final String text;

          Mail(this.id, this.text);
        }
        ''',
        (EntityProcessorError error) => error.multipleFts,
      ),
      (
        'column named rank',
        '''
        @Entity()
        @fts5
        class Mail {
          @primaryKey
          @ColumnInfo(name: 'rowid')
          final int id;

          final String rank;

          Mail(this.id, this.rank);
        }
        ''',
        (EntityProcessorError error) => error.fts5ReservedColumns(['rank']),
      ),
      (
        'column named like the table',
        '''
        @Entity(tableName: 'Mail')
        @fts5
        class Mail {
          @primaryKey
          @ColumnInfo(name: 'rowid')
          final int id;

          final String mail;

          Mail(this.id, this.mail);
        }
        ''',
        (EntityProcessorError error) => error.fts5ReservedColumns(['mail']),
      ),
      (
        'column named like the row id in another case',
        '''
        @entity
        @fts5
        class Mail {
          @primaryKey
          @ColumnInfo(name: 'rowid')
          final int id;

          @ColumnInfo(name: 'RowId')
          final String text;

          Mail(this.id, this.text);
        }
        ''',
        (EntityProcessorError error) => error.fts5ReservedColumns(['RowId']),
      ),
      (
        'FTS4 with a tokenizer of FTS5',
        '''
        @entity
        @Fts4(tokenizer: FtsTokenizer.trigram)
        class Mail {
          @primaryKey
          @ColumnInfo(name: 'rowid')
          final int id;

          final String text;

          Mail(this.id, this.text);
        }
        ''',
        (EntityProcessorError error) =>
            error.ftsUnsupportedTokenizer('trigram'),
      ),
      (
        'tokenizer of FTS4',
        '''
        @Entity()
        @Fts5(tokenizer: FtsTokenizer.simple)
        class Mail {
          @primaryKey
          @ColumnInfo(name: 'rowid')
          final int id;

          final String text;

          Mail(this.id, this.text);
        }
        ''',
        (EntityProcessorError error) =>
            error.fts5UnsupportedTokenizer('simple'),
      ),
      (
        'invalid prefix',
        '''
        @entity
        @Fts5(prefixes: [2, 1000])
        class Mail {
          @primaryKey
          @ColumnInfo(name: 'rowid')
          final int id;

          final String text;

          Mail(this.id, this.text);
        }
        ''',
        (EntityProcessorError error) => error.fts5InvalidPrefixes([2, 1000]),
      ),
      (
        'index',
        '''
        @Entity(indices: [Index(value: ['text'])])
        @fts5
        class Mail {
          @primaryKey
          @ColumnInfo(name: 'rowid')
          final int id;

          final String text;

          Mail(this.id, this.text);
        }
        ''',
        (EntityProcessorError error) => error.fts5TableConstraints,
      ),
    ]) {
      test('with $description fails', () async {
        final classElement = await createClassElement(entity);

        final actual = () => EntityProcessor(classElement, {}).process();

        expect(
          actual,
          throwsInvalidGenerationSourceError(
              error(EntityProcessorError(classElement))),
        );
      });
    }
  });

  test('Process entity with "WITHOUT ROWID"', () async {
    final classElement = await createClassElement('''
      @Entity(withoutRowid: true)
      class Person {
        @primaryKey
        final int id;
      
        final String name;
      
        Person(this.id, this.name);
      }
    ''');

    final actual = EntityProcessor(classElement, {}).process();

    const name = 'Person';
    final fields = classElement.fields
        .map((fieldElement) => FieldProcessor(fieldElement, null).process())
        .toList();
    final primaryKey = PrimaryKey([fields[0]], false);
    const foreignKeys = <ForeignKey>[];
    const indices = <Index>[];
    const constructor = "Person(row['id'] as int, row['name'] as String)";
    final expected = Entity(
      classElement,
      name,
      fields,
      primaryKey,
      foreignKeys,
      indices,
      true,
      constructor,
      "<String, Object?>{'id': item.id, 'name': item.name}",
      null,
    );
    expect(actual, equals(expected));
  });

  group('Value mapping', () {
    test('Non-nullable boolean value mapping', () async {
      final classElement = await createClassElement('''
      @entity
      class Person {
        @primaryKey
        final int id;
      
        final bool isSomething;
      
        Person(this.id, this.isSomething);
      }
    ''');

      final actual = EntityProcessor(classElement, {}).process().valueMapping;

      const expected = '<String, Object?>{'
          "'id': item.id, "
          "'isSomething': item.isSomething ? 1 : 0"
          '}';
      expect(actual, equals(expected));
    });

    test('Nullable boolean value mapping', () async {
      final classElement = await createClassElement('''
      @entity
      class Person {
        @primaryKey
        final int id;
      
        final bool? isSomething;
      
        Person(this.id, this.isSomething);
      }
    ''');

      final actual = EntityProcessor(classElement, {}).process().valueMapping;

      const expected = '<String, Object?>{'
          "'id': item.id, "
          "'isSomething': item.isSomething == null ? null : (item.isSomething! ? 1 : 0)"
          '}';
      expect(actual, equals(expected));
    });

    test('Non-nullable enum value mapping', () async {
      final classElement = await createClassElement('''
      
      $characterType
      
      @entity
      class Person {
        @primaryKey
        final int id;
      
        final CharacterType someType;
      
        Person(this.id, this.someType);
      }
    ''');

      final actual = EntityProcessor(classElement, {}).process().valueMapping;

      const expected = '<String, Object?>{'
          "'id': item.id, "
          "'someType': item.someType.index"
          '}';
      expect(actual, equals(expected));
    });

    test('Nullable enum value mapping', () async {
      final classElement = await createClassElement('''
      
      $characterType
      
      @entity
      class Person {
        @primaryKey
        final int id;
      
        final CharacterType? someType;
      
        Person(this.id, this.someType);
      }
    ''');

      final actual = EntityProcessor(classElement, {}).process().valueMapping;

      const expected = '<String, Object?>{'
          "'id': item.id, "
          "'someType': item.someType?.index"
          '}';
      expect(actual, equals(expected));
    });
  });

  group('expected errors', () {
    test('missing primary key', () async {
      final classElements = await createClassElement('''
          @entity
          class Person {
            final int id;
            
            final String name;
          
            Person(this.id, this.name);
          }
      ''');

      final processor = EntityProcessor(classElements, {});
      expect(
          processor.process,
          throwsInvalidGenerationSourceError(
              EntityProcessorError(classElements).missingPrimaryKey));
    });
    test('compound primary key mismatch', () async {
      final classElements = await createClassElement('''
          @Entity(
            primaryKeys:['notAField']
          )
          class Person {
            final int id;
            
            final String name;
          
            Person(this.id, this.name);
          }
      ''');

      final processor = EntityProcessor(classElements, {});
      expect(
          processor.process,
          throwsInvalidGenerationSourceError(
              EntityProcessorError(classElements)
                  .noMatchingPrimaryKeyColumn('notAField')));
    });
    test('missing parent columns', () async {
      final classElements = await _createClassElements('''
          @entity
          class Person {
            @primaryKey
            final int id;
            
            final String name;
          
            Person(this.id, this.name);
          }
          
          @Entity(
            foreignKeys: [
              ForeignKey(
                childColumns: ['owner_id'],
                parentColumns: [],
                entity: Person,
                onDelete: ForeignKeyAction.setNull,
              )
            ],
          )
          class Dog {
            @primaryKey
            final int id;
          
            final String name;
          
            @ColumnInfo(name: 'owner_id')
            final int ownerId;
          
            Dog(this.id, this.name, this.ownerId);
          }
      ''');

      final processor = EntityProcessor(classElements[1], {});
      expect(
          processor.process,
          throwsInvalidGenerationSourceError(
              EntityProcessorError(classElements[1]).missingParentColumns));
    });
    test('missing child columns', () async {
      final classElements = await _createClassElements('''
          @entity
          class Person {
            @primaryKey
            final int id;
            
            final String name;
          
            Person(this.id, this.name);
          }
          
          @Entity(
            foreignKeys: [
              ForeignKey(
                childColumns: [],
                parentColumns: ['id'],
                entity: Person,
                onDelete: ForeignKeyAction.setNull,
              )
            ],
          )
          class Dog {
            @primaryKey
            final int id;
          
            final String name;
          
            @ColumnInfo(name: 'owner_id')
            final int ownerId;
          
            Dog(this.id, this.name, this.ownerId);
          }
      ''');

      final processor = EntityProcessor(classElements[1], {});
      expect(
          processor.process,
          throwsInvalidGenerationSourceError(
              EntityProcessorError(classElements[1]).missingChildColumns));
    });
    test('foreignKey does not reference entity', () async {
      final classElement = await createClassElement('''
          enum Dummy { a, b }
          
          @Entity(
            foreignKeys: [
              ForeignKey(
                childColumns: ['owner_id'],
                parentColumns: ['id'],
                entity: Dummy,
                onDelete: ForeignKeyAction.setNull,
              )
            ],
          )
          class Dog {
            @primaryKey
            final int id;
          
            final String name;
          
            @ColumnInfo(name: 'owner_id')
            final int ownerId;
          
            Dog(this.id, this.name, this.ownerId);
          }
      ''');

      final processor = EntityProcessor(classElement, {});
      expect(
          processor.process,
          throwsInvalidGenerationSourceError(
              EntityProcessorError(classElement)
                  .foreignKeyDoesNotReferenceEntity));
    });
    test('foreign key reference does not exist', () async {
      final classElements = await createClassElement('''
          @Entity(
            foreignKeys: [
              ForeignKey(
                childColumns: ['owner_id'],
                parentColumns: ['id'],
                entity: Person,
                onDelete: ForeignKeyAction.setNull,
              )
            ],
          )
          class Dog {
            @primaryKey
            final int id;
          
            final String name;
          
            @ColumnInfo(name: 'owner_id')
            final int ownerId;
          
            Dog(this.id, this.name, this.ownerId);
          }
      ''');

      final processor = EntityProcessor(classElements, {});
      expect(
          processor.process,
          throwsInvalidGenerationSourceError(
              EntityProcessorError(classElements).foreignKeyNoEntity));
    });
    test('missing index column name', () async {
      final classElement = await createClassElement('''
          @Entity(
            indices:[Index(value:[])]
          )
          class Dog {
            @primaryKey
            final int id;
          
            final String name;
          
            @ColumnInfo(name: 'owner_id')
            final int ownerId;
          
            Dog(this.id, this.name, this.ownerId);
          }
      ''');

      final processor = EntityProcessor(classElement, {});
      expect(
          processor.process,
          throwsInvalidGenerationSourceError(
              EntityProcessorError(classElement).missingIndexColumnName));
    });
    test('no matching index column', () async {
      final classElement = await createClassElement('''
          @Entity(
            indices:[Index(value:['id', 'notAColumn'])]
          )
          class Dog {
            @primaryKey
            final int id;
          
            final String name;
          
            @ColumnInfo(name: 'owner_id')
            final int ownerId;
          
            Dog(this.id, this.name, this.ownerId);
          }
      ''');

      final processor = EntityProcessor(classElement, {});
      expect(
          processor.process,
          throwsInvalidGenerationSourceError(EntityProcessorError(classElement)
              .noMatchingColumn('notAColumn')));
    });
    test('auto-increment not usable with `WITHOUT ROWID`', () async {
      final classElement = await createClassElement('''
          @Entity(
            withoutRowid:true
          )
          class Dog {
            @PrimaryKey(autoGenerate:true)
            final int id;
          
            final String name;
          
            @ColumnInfo(name: 'owner_id')
            final int ownerId;
          
            Dog(this.id, this.name, this.ownerId);
          }
      ''');

      final processor = EntityProcessor(classElement, {});
      expect(
          processor.process,
          throwsInvalidGenerationSourceError(
              EntityProcessorError(classElement).autoIncrementInWithoutRowid));
    });

    test('missing unnamed constructor.', () async {
      final classElement = await createClassElement('''
      @entity
      class Person {
        @primaryKey
        final int id;
      
        final String name;

        factory Person.from(Person other) {
          return Person(other.id, other.name);
        }
      }
    ''');

      final actual = EntityProcessor(classElement, {});

      expect(
        actual.process,
        throwsInvalidGenerationSourceError(
          QueryableProcessorError(classElement).missingUnnamedConstructor,
        ),
      );
    });
  });
}

Future<List<ClassElement>> _createClassElements(final String classes) async {
  final library = await resolveSource(readAllSourcesFromFilesystem: true, '''
      library test;
      
      import 'package:froom_annotation/froom_annotation.dart';
      
      $classes
      ''', (resolver) async {
    return resolver
        .findLibraryByName('test')
        .then((value) => ArgumentError.checkNotNull(value))
        .then((value) => LibraryReader(value));
  });

  return library.classes.toList();
}
