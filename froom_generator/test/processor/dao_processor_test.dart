// ignore_for_file: import_of_legacy_library_into_null_safe
import 'package:analyzer/dart/element/element.dart';
import 'package:build_test/build_test.dart';
import 'package:froom_annotation/froom_annotation.dart' as annotations;
import 'package:froom_generator/misc/type_utils.dart';
import 'package:froom_generator/processor/dao_processor.dart';
import 'package:froom_generator/processor/entity_processor.dart';
import 'package:froom_generator/processor/view_processor.dart';
import 'package:froom_generator/value_object/dao.dart';
import 'package:froom_generator/value_object/entity.dart';
import 'package:froom_generator/value_object/view.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  late List<Entity> entities;
  late List<View> views;

  setUpAll(() async {
    entities = await _getEntities();
    views = await _getViews();
  });

  test('Includes methods from abstract parent class', () async {
    final classElement = await _createDao('''
      @dao
      abstract class PersonDao extends AbstractDao<Person> {
        @Query('SELECT * FROM person')
        Future<List<Person>> findAllPersons();
      }
      
      abstract class AbstractDao<T> {
        @insert
        Future<void> insertItem(T item);
      }
    ''');

    final actual = DaoProcessor(classElement, '', '', entities, views, {})
        .process()
        .methodsLength;

    expect(actual, equals(2));
  });

  test('Includes overridden methods only once', () async {
    final classElement = await _createDao('''
      @dao
      abstract class PersonDao extends AbstractDao<Person> {
        @override
        @Query('SELECT * FROM person WHERE id > 0')
        Future<List<Person>> findAll();
      }
      
      abstract class AbstractDao<T> extends AnotherAbstractDao<T> {
        @override
        @Query('SELECT * FROM person WHERE id > 1')
        Future<List<T>> findAll();
      }
      
      abstract class AnotherAbstractDao<T> {
        @Query('SELECT * FROM person')
        Future<List<T>> findAll();
      }
    ''');

    final actual =
        DaoProcessor(classElement, '', '', entities, views, {}).process();

    expect(actual.queryMethods, hasLength(1));
    expect(actual.queryMethods.first.query.sql,
        equals('SELECT * FROM person WHERE id > 0'));
  });

  test('Keeps concrete methods between redeclaration and annotated method',
      () async {
    final classElement = await _createDao('''
      @dao
      abstract class PersonDao extends AbstractDao<Person> {
        @override
        Future<List<Person>> findAll();
      }
      
      abstract class AbstractDao<T> extends AnotherAbstractDao<T> {
        @override
        Future<List<T>> findAll() async => [];
      }
      
      abstract class AnotherAbstractDao<T> {
        @Query('SELECT * FROM person')
        Future<List<T>> findAll();
      }
    ''');

    final actual =
        DaoProcessor(classElement, '', '', entities, views, {}).process();

    expect(actual.queryMethods, isEmpty);
  });

  test('Prefers concrete methods of superclasses over interfaces', () async {
    final classElement = await _createDao('''
      @dao
      abstract class PersonDao extends BaseDao implements ContractDao {}
      
      abstract class BaseDao extends RootDao {}
      
      abstract class RootDao {
        Future<List<Person>> findAll() async => [];
      }
      
      abstract class ContractDao {
        @Query('SELECT * FROM person')
        Future<List<Person>> findAll();
      }
    ''');

    final actual =
        DaoProcessor(classElement, '', '', entities, views, {}).process();

    expect(actual.queryMethods, isEmpty);
  });

  test('Rejects redeclarations with another signature without annotation',
      () async {
    final classElement = await _createDao('''
      @dao
      abstract class PersonDao extends AbstractDao<Person> {
        @override
        Future<List<Person>> findAll({int limit = 10});
      }
      
      abstract class AbstractDao<T> {
        @Query('SELECT * FROM person LIMIT :limit')
        Future<List<T>> findAll({int limit = 1});
      }
    ''');

    final actual = () =>
        DaoProcessor(classElement, '', '', entities, views, {}).process();

    expect(actual, throwsInvalidGenerationSourceError());
  });

  test('Accepts redeclarations with the same signature', () async {
    final classElement = await _createDao('''
      @dao
      abstract class PersonDao extends AbstractDao<Person> {
        @override
        Future<List<Person>> findAll({int b = 2, int a = 0x1, int? c});
      }
      
      abstract class AbstractDao<T> {
        @Query('SELECT * FROM person WHERE :c IS NULL LIMIT :a OFFSET :b')
        Future<List<T>> findAll({int a = 1, int b = 2, int? c = null});
      }
    ''');

    final actual =
        DaoProcessor(classElement, '', '', entities, views, {}).process();

    expect(actual.queryMethods, hasLength(1));
  });

  test('Ignores @transaction on query and change methods', () async {
    final classElement = await _createDao('''
      @dao
      abstract class PersonDao {
        @insert
        @transaction
        Future<int> insertPerson(Person person);
      
        @Query('SELECT * FROM person')
        @transaction
        Future<List<Person>> findAll();
      }
    ''');

    final actual =
        DaoProcessor(classElement, '', '', entities, views, {}).process();

    expect(actual.insertionMethods, hasLength(1));
    expect(actual.queryMethods, hasLength(1));
    expect(actual.transactionMethods, isEmpty);
  });

  test('Prefers methods of later mixins', () async {
    final classElement = await _createDao('''
      @dao
      abstract class PersonDao with FirstMixin, SecondMixin {}
      
      mixin FirstMixin {
        @Query('SELECT * FROM person WHERE id > 1')
        Future<List<Person>> findAll();
      }
      
      mixin SecondMixin {
        @Query('SELECT * FROM person WHERE id > 2')
        Future<List<Person>> findAll();
      }
    ''');

    final actual =
        DaoProcessor(classElement, '', '', entities, views, {}).process();

    expect(actual.queryMethods, hasLength(1));
    expect(actual.queryMethods.first.query.sql,
        equals('SELECT * FROM person WHERE id > 2'));
  });

  test("Includes methods from abstract parent's abstract parent class",
      () async {
    final classElement = await _createDao('''
      @dao
      abstract class PersonDao extends AbstractDao<Person> {
        @Query('SELECT * FROM person')
        Future<List<Person>> findAllPersons();
      }

      abstract class AbstractDao<T> extends AnotherAbstractDao<T> {
        @insert
        Future<void> insertItem(T item);
      }
      
      abstract class AnotherAbstractDao<T> {
        @update
        Future<void> updateItem(T item);      
      }
    ''');

    final actual = DaoProcessor(classElement, '', '', entities, views, {})
        .process()
        .methodsLength;

    expect(actual, equals(3));
  });

  test('Includes methods from mixin', () async {
    final classElement = await _createDao('''
      @dao
      abstract class PersonDao with MixinDao<Person> {
        @Query('SELECT * FROM person')
        Future<List<Person>> findAllPersons();
      }

      class MixinDao<T> {
        @insert
        Future<void> insertItem(T item);
      }
    ''');

    final actual = DaoProcessor(classElement, '', '', entities, views, {})
        .process()
        .methodsLength;

    expect(actual, equals(2));
  });

  test('Includes methods from super class', () async {
    final classElement = await _createDao('''
      @dao
      abstract class PersonDao extends SuperClassDao<Person> {
        @Query('SELECT * FROM person')
        Future<List<Person>> findAllPersons();
      }

      class SuperClassDao<T> {
        @insert
        Future<void> insertItem(T item);
      }
    ''');

    final actual = DaoProcessor(classElement, '', '', entities, views, {})
        .process()
        .methodsLength;

    expect(actual, equals(2));
  });

  test('Includes methods from interface', () async {
    final classElement = await _createDao('''
      @dao
      abstract class PersonDao implements InterfaceDao<Person> {
        @Query('SELECT * FROM person')
        Future<List<Person>> findAllPersons();
      }

      class InterfaceDao<T> {
        @insert
        Future<void> insertItem(T item);
      }
    ''');

    final actual = DaoProcessor(classElement, '', '', entities, views, {})
        .process()
        .methodsLength;

    expect(actual, equals(2));
  });

  test('Includes streamable view method from super class', () async {
    final classElement = await _createDao('''
        @dao
        abstract class PersonDao extends SuperClassDao<Person> {
          @Query('SELECT * FROM person')
          Future<List<Person>> findAllPersons();

          @Query('SELECT Name.name from Name')
          Stream<List<Name>> getAllNamesStream();
        }

        class SuperClassDao<T> {
          @insert
          Future<void> insertItem(T item);

          @Query('SELECT DISTINCT Name.name from Name')
          Stream<List<Name>> getAllDistinctNamesStream();
        }
      ''');

    final processedDao =
        DaoProcessor(classElement, '', '', entities, views, {}).process();

    expect(processedDao.methodsLength, equals(4));
    expect(processedDao.streamViews, equals(views));
    expect(processedDao.streamEntities, equals(<Entity>[]));
  });
}

extension on Dao {
  int get methodsLength {
    return [
      ...queryMethods,
      ...insertionMethods,
      ...updateMethods,
      ...deletionMethods,
      ...transactionMethods
    ].length;
  }
}

Future<ClassElement> _createDao(final String dao) async {
  final library = await resolveSource(readAllSourcesFromFilesystem: true, '''
      library test;
      
      import 'package:froom_annotation/froom_annotation.dart';
      
      $dao
      
      @entity
      class Person {
        @primaryKey
        final int id;
      
        final String name;
      
        Person(this.id, this.name);
      }
      
      @DatabaseView("SELECT name FROM Person")
      class Name {
        final String name;
      
        Person(this.name);
      }

      ''', (resolver) async {
    return resolver
        .findLibraryByName('test')
        .then((value) => ArgumentError.checkNotNull(value))
        .then((value) => LibraryReader(value));
  });

  return library.classes.first;
}

Future<List<Entity>> _getEntities() async {
  final library = await resolveSource(readAllSourcesFromFilesystem: true, '''
      library test;
      
      import 'package:froom_annotation/froom_annotation.dart';
      
      @entity
      class Person {
        @primaryKey
        final int id;
      
        final String name;
      
        Person(this.id, this.name);
      }
    ''', (resolver) async {
    return resolver
        .findLibraryByName('test')
        .then((value) => ArgumentError.checkNotNull(value))
        .then((value) => LibraryReader(value));
  });

  return library.classes
      .where((classElement) => classElement.hasAnnotation(annotations.Entity))
      .map((classElement) => EntityProcessor(classElement, {}).process())
      .toList();
}

Future<List<View>> _getViews() async {
  final library = await resolveSource(readAllSourcesFromFilesystem: true, '''
      library test;
      
      import 'package:froom_annotation/froom_annotation.dart';
      
      @DatabaseView("SELECT name FROM Person")
      class Name {
        final String name;
      
        Person(this.name);
      }
    ''', (resolver) async {
    return resolver
        .findLibraryByName('test')
        .then((value) => ArgumentError.checkNotNull(value))
        .then((value) => LibraryReader(value));
  });

  return library.classes
      .where((classElement) =>
          classElement.hasAnnotation(annotations.DatabaseView))
      .map((classElement) => ViewProcessor(classElement, {}).process())
      .toList();
}
