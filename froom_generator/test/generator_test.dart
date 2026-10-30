import 'package:build/build.dart';
import 'package:froom_generator/generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
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

    final actual = await FroomGenerator().generateForAnnotatedElement(
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

    final actual = await FroomGenerator().generateForAnnotatedElement(
      database,
      ConstantReader(null),
      _FakeBuildStep(),
    );

    expect(
      actual,
      startsWith('// ignore_for_file: type=lint, unused_element\n'),
    );
  });
}

class _FakeBuildStep implements BuildStep {
  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError();
}
