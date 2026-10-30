import 'package:analyzer/dart/element/element.dart';
import 'package:build_test/build_test.dart';
import 'package:froom_annotation/froom_annotation.dart' as annotations;
import 'package:froom_generator/misc/type_utils.dart';
import 'package:froom_generator/processor/entity_processor.dart';
import 'package:froom_generator/processor/error/change_method_processor_error.dart';
import 'package:froom_generator/processor/upsertion_method_processor.dart';
import 'package:froom_generator/misc/extension/type_converter_element_extension.dart';
import 'package:froom_generator/value_object/entity.dart';
import 'package:froom_generator/value_object/type_converter.dart';
import 'package:froom_generator/value_object/upsertion_method.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  test('Collects entity of upserted parameter', () async {
    final (actual, entities) = await _process('''
      @upsert
      Future<void> upsertPerson(Person person);
    ''');

    expect(actual.parameters, hasLength(1));
    expect(actual.parameters.first.entity, equals(entities['Person']));
    expect(actual.parameters.first.partialEntity, isNull);
  });

  test('Collects multiple parameters', () async {
    final (actual, entities) = await _process('''
      @upsert
      Future<void> upsertPersonAndDogs(Person person, List<Dog> dogs);
    ''');

    expect(
      actual.parameters.map((parameter) => parameter.entity),
      equals([entities['Person'], entities['Dog']]),
    );
    expect(
      actual.parameters.map((parameter) => parameter.changesMultipleItems),
      equals([false, true]),
    );
  });

  test('Collects partial entity of target entity', () async {
    final (actual, entities) = await _process('''
      @Upsert(entity: Person)
      Future<void> upsertPersonName(PersonName personName);
    ''');

    final parameter = actual.parameters.first;
    expect(parameter.entity, equals(entities['Person']));
    expect(parameter.partialEntity?.classElement.displayName,
        equals('PersonName'));
    expect(parameter.partialEntity?.fields.map((field) => field.columnName),
        equals(['id', 'custom_name']));
    expect(
      parameter.valueMapping,
      equals("<String, Object?>{'id': item.id, 'custom_name': item.name}"),
    );
  });

  test('Uses target entity itself when parameter has its type', () async {
    final (actual, entities) = await _process('''
      @Upsert(entity: Person)
      Future<void> upsertPerson(Person person);
    ''');

    expect(actual.parameters.first.entity, equals(entities['Person']));
    expect(actual.parameters.first.partialEntity, isNull);
  });

  test('Allows partial entity without auto generated primary key', () async {
    final (actual, _) = await _process('''
      @Upsert(entity: Dog)
      Future<void> upsertDogName(DogName dogName);
    ''');

    expect(
      actual.parameters.first.partialEntity?.fields
          .map((field) => field.columnName),
      equals(['name', 'owner_id']),
    );
  });

  test('Names adapters of partial entities after their target entity',
      () async {
    final (partial, _) = await _process('''
      @Upsert(entity: Person)
      Future<void> upsertPersonName(PersonName personName);
    ''');
    final (entity, _) = await _process('''
      @upsert
      Future<void> upsertPerson(Person person);
    ''');

    expect(partial.parameters.first.adapterName,
        equals('_personNameToPersonUpsertionAdapter'));
    expect(entity.parameters.first.adapterName,
        equals('_personUpsertionAdapter'));
  });

  test('Uses type converter of target entity for partial entity', () async {
    final (actual, _) = await _process('''
      @Upsert(entity: Event)
      Future<void> upsertEventDate(EventDate eventDate);
    ''');

    expect(
      actual.parameters.first.valueMapping,
      equals(
          "<String, Object?>{'id': item.id, 'date': _dateTimeConverter.encode(item.date)}"),
    );
  });

  test('Allows partial entity to omit columns with a default value',
      () async {
    final (actual, _) = await _process('''
      @Upsert(entity: Article)
      Future<void> upsertArticleTitle(ArticleTitle articleTitle);
    ''');

    expect(
      actual.parameters.first.partialEntity?.fields
          .map((field) => field.columnName),
      equals(['id', 'title']),
    );
  });

  group('expected errors', () {
    test('when not returning Future', () async {
      final method = await '''
      @upsert
      void upsertPerson(Person person);
    '''
          .asDaoMethodElement();
      final entities = await getPersonEntity();

      final actual = () => UpsertionMethodProcessor(
              method, [entities], {}, 'personDao', 'TestDatabase')
          .process();

      expect(
          actual,
          throwsInvalidGenerationSourceError(
              ChangeMethodProcessorError(method, 'Upsertion')
                  .doesNotReturnFuture));
    });

    test('when not returning int or void or List<int>', () async {
      final method = await '''
      @upsert
      Future<bool> upsertPerson(Person person);
    '''
          .asDaoMethodElement();
      final entities = await getPersonEntity();

      final actual = () => UpsertionMethodProcessor(
              method, [entities], {}, 'personDao', 'TestDatabase')
          .process();

      expect(
          actual,
          throwsInvalidGenerationSourceError(
              ChangeMethodProcessorError(method, 'Upsertion')
                  .doesNotReturnVoidNorIntNorListInt));
    });

    test('when having no parameter', () async {
      final (method, actual) = await _processLazily('''
        @upsert
        Future<void> upsertNothing();
      ''');

      expect(
          actual,
          throwsA(isA<InvalidGenerationSourceError>().having(
              (error) => error.message,
              'message',
              contains('There is no parameter supplied'))));
    });

    test('when multiple parameters do not return void', () async {
      final (method, actual) = await _processLazily('''
        @upsert
        Future<int> upsertPersonAndDog(Person person, Dog dog);
      ''');

      expect(
          actual,
          throwsInvalidGenerationSourceError(
              ChangeMethodProcessorError(method, 'Upsertion')
                  .multipleParametersDoNotReturnVoid));
    });

    test('when list parameter returns int', () async {
      final (method, actual) = await _processLazily('''
        @upsert
        Future<int> upsertPersons(List<Person> persons);
      ''');

      expect(
          actual,
          throwsInvalidGenerationSourceError(
              ChangeMethodProcessorError(method, 'Upsertion')
                  .listParameterDoesNotReturnList));
    });

    test('when single item parameter returns list', () async {
      final (method, actual) = await _processLazily('''
        @upsert
        Future<List<int>> upsertPerson(Person person);
      ''');

      expect(
          actual,
          throwsInvalidGenerationSourceError(
              ChangeMethodProcessorError(method, 'Upsertion')
                  .singleParameterReturnsList));
    });

    test('when partial entity misses primary key', () async {
      final (_, actual) = await _processLazily('''
        @Upsert(entity: Person)
        Future<void> upsertPersonWithoutId(PersonWithoutId person);
      ''');

      expect(
          actual,
          throwsA(isA<InvalidGenerationSourceError>().having(
              (error) => error.message,
              'message',
              contains('missing the primary key columns id'))));
    });

    test('when partial entity misses non-nullable column', () async {
      final (_, actual) = await _processLazily('''
        @Upsert(entity: Dog)
        Future<void> upsertDogWithoutOwner(DogWithoutOwner dog);
      ''');

      expect(
          actual,
          throwsA(isA<InvalidGenerationSourceError>().having(
              (error) => error.message,
              'message',
              contains('missing the non-nullable columns owner_id'))));
    });

    test('when partial entity has unknown column', () async {
      final (_, actual) = await _processLazily('''
        @Upsert(entity: Person)
        Future<void> upsertPersonWithAge(PersonWithAge person);
      ''');

      expect(
          actual,
          throwsA(isA<InvalidGenerationSourceError>().having(
              (error) => error.message,
              'message',
              contains('does not match any column of person'))));
    });

    test('when partial entity maps two fields to the same column', () async {
      final (_, actual) = await _processLazily('''
        @Upsert(entity: Person)
        Future<void> upsertPerson(PersonWithDuplicateColumn person);
      ''');

      expect(
          actual,
          throwsA(isA<InvalidGenerationSourceError>().having(
              (error) => error.message,
              'message',
              contains('another field maps to already'))));
    });

    test('when partial entity has unknown field of unsupported type',
        () async {
      final (_, actual) = await _processLazily('''
        @Upsert(entity: Person)
        Future<void> upsertPerson(PersonWithTags person);
      ''');

      expect(
          actual,
          throwsA(isA<InvalidGenerationSourceError>().having(
              (error) => error.message,
              'message',
              contains('tags of the partial entity PersonWithTags does not match any column'))));
    });

    test('when partial entity has different column type', () async {
      final (_, actual) = await _processLazily('''
        @Upsert(entity: Person)
        Future<void> upsertPersonWithIntName(PersonWithIntName person);
      ''');

      expect(
          actual,
          throwsA(isA<InvalidGenerationSourceError>().having(
              (error) => error.message,
              'message',
              contains('does not have the same type as the column'))));
    });

    test('when partial entity field has a different type of same SQL type',
        () async {
      final (_, actual) = await _processLazily('''
        @Upsert(entity: Person)
        Future<void> upsertPersonWithBoolId(PersonWithBoolId person);
      ''');

      expect(
          actual,
          throwsA(isA<InvalidGenerationSourceError>().having(
              (error) => error.message,
              'message',
              contains('does not have the same type as the column'))));
    });

    test('when partial entity field uses another type converter', () async {
      final (_, actual) = await _processLazily('''
        @Upsert(entity: Event)
        Future<void> upsertEventDate(EventDateWithOwnConverter eventDate);
      ''');

      expect(
          actual,
          throwsA(isA<InvalidGenerationSourceError>().having(
              (error) => error.message,
              'message',
              contains('does not use the same type converter'))));
    });

    test('when parameter is nullable', () async {
      final (method, actual) = await _processLazily('''
        @upsert
        Future<void> upsertPerson(Person? person);
      ''');

      expect(
          actual,
          throwsInvalidGenerationSourceError(
              ChangeMethodProcessorError(method, 'Upsertion')
                  .nullableParameter(method.formalParameters.first)));
    });

    test('when list items are nullable', () async {
      final (method, actual) = await _processLazily('''
        @upsert
        Future<void> upsertPersons(List<Person?> persons);
      ''');

      expect(
          actual,
          throwsInvalidGenerationSourceError(
              ChangeMethodProcessorError(method, 'Upsertion')
                  .nullableParameter(method.formalParameters.first)));
    });

    test('when returning list of void', () async {
      final (method, actual) = await _processLazily('''
        @upsert
        Future<List<void>> upsertPersons(List<Person> persons);
      ''');

      expect(
          actual,
          throwsInvalidGenerationSourceError(
              ChangeMethodProcessorError(method, 'Upsertion')
                  .doesNotReturnVoidNorIntNorListInt));
    });

    test('when target entity is not an entity', () async {
      final (method, actual) = await _processLazily('''
        @Upsert(entity: PersonName)
        Future<void> upsertPersonName(PersonName personName);
      ''');

      expect(
          actual,
          throwsInvalidGenerationSourceError(
              ChangeMethodProcessorError(method, 'Upsertion')
                  .targetEntityIsNotAnEntity));
    });

    test('when partial entity field is nullable but column is not', () async {
      final (_, actual) = await _processLazily('''
        @Upsert(entity: Person)
        Future<void> upsertNullableName(PersonWithNullableName person);
      ''');

      expect(
          actual,
          throwsA(isA<InvalidGenerationSourceError>().having(
              (error) => error.message,
              'message',
              contains('is nullable, but the column is not nullable'))));
    });

    test('when parameter is a core type with target entity', () async {
      final (method, actual) = await _processLazily('''
        @Upsert(entity: Person)
        Future<void> upsertId(int id);
      ''');

      expect(
          actual,
          throwsInvalidGenerationSourceError(
              ChangeMethodProcessorError(method, 'Upsertion')
                  .parameterIsNotAClass(method.formalParameters.first)));
    });

    test('when parameter is not an entity without target entity', () async {
      final (_, actual) = await _processLazily('''
        @upsert
        Future<void> upsertPersonName(PersonName personName);
      ''');

      expect(
          actual,
          throwsA(isA<InvalidGenerationSourceError>().having(
              (error) => error.message,
              'message',
              contains('not an entity'))));
    });
  });
}

Future<(UpsertionMethod, Map<String, Entity>)> _process(
  final String methodSignature,
) async {
  final (method, entities, typeConverters) = await _resolve(methodSignature);
  final upsertionMethod = UpsertionMethodProcessor(
    method,
    entities.values.toList(),
    typeConverters,
    'personDao',
    'TestDatabase',
  ).process();
  return (upsertionMethod, entities);
}

Future<(MethodElement, UpsertionMethod Function())> _processLazily(
  final String methodSignature,
) async {
  final (method, entities, typeConverters) = await _resolve(methodSignature);
  return (
    method,
    () => UpsertionMethodProcessor(
          method,
          entities.values.toList(),
          typeConverters,
          'personDao',
          'TestDatabase',
        ).process(),
  );
}

/// Resolves the method of a DAO, which declares a DAO level type converter
/// for `DateTime` encoding seconds instead of milliseconds.
Future<(MethodElement, Map<String, Entity>, Set<TypeConverter>)> _resolve(
  final String methodSignature,
) async {
  final library = await resolveSource(readAllSourcesFromFilesystem: true, '''
      library test;
      
      import 'package:froom_annotation/froom_annotation.dart';
      
      @dao
      @TypeConverters([DateTimeSecondsConverter])
      abstract class PersonDao {
        $methodSignature
      }
      
      @Entity(tableName: 'person')
      class Person {
        @primaryKey
        final int id;
      
        @ColumnInfo(name: 'custom_name')
        final String name;
      
        Person(this.id, this.name);
      }
      
      @entity
      class Dog {
        @PrimaryKey(autoGenerate: true)
        final int? id;
      
        final String name;
      
        @ColumnInfo(name: 'nick_name')
        final String? nickName;
      
        @ColumnInfo(name: 'owner_id')
        final int ownerId;
      
        Dog(this.id, this.name, this.nickName, this.ownerId);
      }
      
      class PersonName {
        final int id;
      
        @ColumnInfo(name: 'custom_name')
        final String name;
      
        PersonName(this.id, this.name);
      }
      
      class PersonWithoutId {
        @ColumnInfo(name: 'custom_name')
        final String name;
      
        PersonWithoutId(this.name);
      }
      
      class PersonWithAge {
        final int id;
      
        @ColumnInfo(name: 'custom_name')
        final String name;
      
        final int age;
      
        PersonWithAge(this.id, this.name, this.age);
      }
      
      class PersonWithIntName {
        final int id;
      
        @ColumnInfo(name: 'custom_name')
        final int name;
      
        PersonWithIntName(this.id, this.name);
      }
      
      class DogName {
        final String name;
      
        @ColumnInfo(name: 'owner_id')
        final int ownerId;
      
        DogName(this.name, this.ownerId);
      }
      
      class PersonWithNullableName {
        final int id;
      
        @ColumnInfo(name: 'custom_name')
        final String? name;
      
        PersonWithNullableName(this.id, this.name);
      }
      
      class DateTimeSecondsConverter extends TypeConverter<DateTime, int> {
        @override
        DateTime decode(int databaseValue) {
          return DateTime.fromMillisecondsSinceEpoch(databaseValue * 1000);
        }
      
        @override
        int encode(DateTime value) {
          return value.millisecondsSinceEpoch ~/ 1000;
        }
      }
      
      @entity
      class Article {
        @primaryKey
        final int id;
      
        final String title;
      
        @ColumnInfo(defaultValue: 'draft')
        final String status;
      
        Article(this.id, this.title, this.status);
      }
      
      class ArticleTitle {
        final int id;
      
        final String title;
      
        ArticleTitle(this.id, this.title);
      }
      
      class PersonWithDuplicateColumn {
        final int id;
      
        @ColumnInfo(name: 'custom_name')
        final String name;
      
        @ColumnInfo(name: 'custom_name')
        final String title;
      
        PersonWithDuplicateColumn(this.id, this.name, this.title);
      }
      
      class PersonWithTags {
        final int id;
      
        @ColumnInfo(name: 'custom_name')
        final String name;
      
        final List<String> tags;
      
        PersonWithTags(this.id, this.name, this.tags);
      }
      
      class PersonWithBoolId {
        final bool id;
      
        @ColumnInfo(name: 'custom_name')
        final String name;
      
        PersonWithBoolId(this.id, this.name);
      }
      
      class EventDateWithOwnConverter {
        final int id;
      
        @TypeConverters([DateTimeSecondsConverter])
        final DateTime date;
      
        EventDateWithOwnConverter(this.id, this.date);
      }
      
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
      @TypeConverters([DateTimeConverter])
      class Event {
        @primaryKey
        final int id;
      
        final DateTime date;
      
        Event(this.id, this.date);
      }
      
      class EventDate {
        final int id;
      
        final DateTime date;
      
        EventDate(this.id, this.date);
      }
      
      class DogWithoutOwner {
        final int id;
      
        final String name;
      
        DogWithoutOwner(this.id, this.name);
      }
      ''', (resolver) async {
    return resolver
        .findLibraryByName('test')
        .then((value) => ArgumentError.checkNotNull(value))
        .then((value) => LibraryReader(value));
  });

  final daoClass = library.classes.firstWhere((classElement) =>
      classElement.hasAnnotation(annotations.dao.runtimeType));
  final method = daoClass.methods.first;
  final typeConverters = daoClass.getTypeConverters(TypeConverterScope.dao);
  final entities = {
    for (final classElement in library.classes
        .where((classElement) => classElement.hasAnnotation(annotations.Entity)))
      classElement.displayName: EntityProcessor(classElement, {}).process(),
  };
  return (method, entities, typeConverters);
}
