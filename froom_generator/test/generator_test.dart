import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:froom_generator/generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  late Directory schemaDirectory;

  setUp(() {
    schemaDirectory = Directory.systemTemp.createTempSync('froom_schemas');
  });

  tearDown(() {
    schemaDirectory.deleteSync(recursive: true);
  });

  FroomGenerator createGenerator() =>
      FroomGenerator(schemaLocation: schemaDirectory.path);

  test('generated code suppresses lints of the consuming project', () async {
    final database = await createClassElement('''
      @Database(version: 1, entities: [Person])
      abstract class TestDatabase extends FroomDatabase {}
      
      @entity
      class Person {
        @primaryKey
        final int id;
      
        final String name;
      
        Person(this.id, this.name);
      }
    ''');

    final actual = await createGenerator().generateForAnnotatedElement(
      database,
      ConstantReader(null),
      _FakeBuildStep(),
    );

    expect(actual, startsWith('// ignore_for_file: type=lint\n'));
  });

  test('generated code ignores unused type converter fields', () async {
    final database = await createClassElement('''
      @Database(version: 1, entities: [Order])
      @TypeConverters([DateTimeConverter])
      abstract class TestDatabase extends FroomDatabase {}
      
      class DateTimeConverter extends TypeConverter<DateTime, int> {
        @override
        DateTime decode(int databaseValue) {
          return DateTime.fromMillisecondsSinceEpoch(databaseValue);
        }
      
        @override
        int encode(DateTime value) {
          return value.millisecondsSinceEpoch;
        }
      }
      
      @entity
      class Order {
        @primaryKey
        final int id;
      
        final DateTime date;
      
        Order(this.id, this.date);
      }
    ''');

    final actual = await createGenerator().generateForAnnotatedElement(
      database,
      ConstantReader(null),
      _FakeBuildStep(),
    );

    expect(
      actual,
      startsWith('// ignore_for_file: type=lint, unused_element\n'),
    );
  });

  test('exports the schema of the database version', () async {
    final database = await createClassElement('''
      @Database(version: 2, entities: [Person], exportSchema: true)
      abstract class TestDatabase extends FroomDatabase {}
      
      @entity
      class Person {
        @primaryKey
        final int id;
      
        final String name;
      
        Person(this.id, this.name);
      }
    ''');

    await createGenerator().generateForAnnotatedElement(
      database,
      ConstantReader(null),
      _FakeBuildStep(),
    );

    final file = File(
        '${schemaDirectory.path}/lib/database/TestDatabase/2.json');
    final schema = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    final entities = (schema['database'] as Map)['entities'] as List;
    expect((entities.single as Map)['createSql'],
        contains(r'CREATE TABLE IF NOT EXISTS `${TABLE_NAME}`'));
  });

  test('exports no schema by default without automatic migrations', () async {
    final database = await createClassElement('''
      @Database(version: 1, entities: [Person])
      abstract class TestDatabase extends FroomDatabase {}
      
      @entity
      class Person {
        @primaryKey
        final int id;
      
        Person(this.id);
      }
    ''');

    await createGenerator().generateForAnnotatedElement(
      database,
      ConstantReader(null),
      _FakeBuildStep(),
    );

    expect(schemaDirectory.listSync(), isEmpty);
  });

  test('exports no schema with exportSchema: false', () async {
    final database = await createClassElement('''
      @Database(version: 1, entities: [Person], exportSchema: false)
      abstract class TestDatabase extends FroomDatabase {}
      
      @entity
      class Person {
        @primaryKey
        final int id;
      
        Person(this.id);
      }
    ''');

    await createGenerator().generateForAnnotatedElement(
      database,
      ConstantReader(null),
      _FakeBuildStep(),
    );

    expect(schemaDirectory.listSync(), isEmpty);
  });
}

class _FakeBuildStep implements BuildStep {
  @override
  AssetId get inputId => AssetId('test', 'lib/database.dart');

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError();
}
