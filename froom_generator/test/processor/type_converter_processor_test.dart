import 'package:froom_generator/processor/type_converter_processor.dart';
import 'package:froom_generator/value_object/type_converter.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('TypeConverterProcessor', () {
    test('Creates type converter with given scope', () async {
      const typeConverterScope = TypeConverterScope.dao;
      final classElement = await '''
      class DateTimeConverter extends TypeConverter<DateTime, int> {
        @override
        int encode(DateTime value) {
          return value.millisecondsSinceEpoch;
        }
      
        @override
        DateTime decode(int databaseValue) {
          return DateTime.fromMillisecondsSinceEpoch(databaseValue);
        }
      }
    '''
          .asClassElement();

      final actual = TypeConverterProcessor(
        classElement,
        typeConverterScope,
      ).process();

      final expected = TypeConverter(
        'DateTimeConverter',
        await 'DateTime.now()'.asDartType(),
        await '1'.asDartType(),
        typeConverterScope,
      );
      expect(actual, equals(expected));
    });

    test('Creates type converter implementing TypeConverter', () async {
      final classElement = await '''
      class DateTimeConverter implements TypeConverter<DateTime, int>, Comparable<int> {
        @override
        int encode(DateTime value) => value.millisecondsSinceEpoch;
      
        @override
        DateTime decode(int databaseValue) =>
            DateTime.fromMillisecondsSinceEpoch(databaseValue);
      
        @override
        int compareTo(int other) => 0;
      }
    '''
          .asClassElement();

      final actual =
          TypeConverterProcessor(classElement, TypeConverterScope.dao).process();

      expect(actual.fieldType, equals(await 'DateTime.now()'.asDartType()));
      expect(actual.databaseType, equals(await '1'.asDartType()));
    });

    test('Creates type converter extending TypeConverter indirectly', () async {
      final classElement = await '''
      class DateTimeConverter extends MillisecondsConverter<DateTime> {
        @override
        int encode(DateTime value) => value.millisecondsSinceEpoch;
      
        @override
        DateTime decode(int databaseValue) =>
            DateTime.fromMillisecondsSinceEpoch(databaseValue);
      }
      
      abstract class MillisecondsConverter<T> extends TypeConverter<T, int> {}
    '''
          .asClassElement();

      final actual =
          TypeConverterProcessor(classElement, TypeConverterScope.dao).process();

      expect(actual.fieldType, equals(await 'DateTime.now()'.asDartType()));
      expect(actual.databaseType, equals(await '1'.asDartType()));
    });

    test("throws error when converter's database type is not supported",
        () async {
      final classElement = await '''
      class DateTimeConverter extends TypeConverter<DateTime, DateTime> {
        @override
        DateTime encode(DateTime value) {
          return value;
        }
      
        @override
        DateTime decode(DateTime databaseValue) {
          return DateTime.fromMillisecondsSinceEpoch(databaseValue);
        }
      }
    '''
          .asClassElement();

      final actual = () => TypeConverterProcessor(
            classElement,
            TypeConverterScope.dao,
          ).process();

      expect(actual, throwsProcessorError());
    });
  });
}
