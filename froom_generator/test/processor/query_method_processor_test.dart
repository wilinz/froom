import 'package:analyzer/dart/element/element.dart';
import 'package:build_test/build_test.dart';
import 'package:froom_annotation/froom_annotation.dart' as annotations;
import 'package:froom_generator/misc/type_utils.dart';
import 'package:froom_generator/processor/entity_processor.dart';
import 'package:froom_generator/processor/error/query_method_processor_error.dart';
import 'package:froom_generator/processor/error/query_processor_error.dart';
import 'package:froom_generator/processor/query_method_processor.dart';
import 'package:froom_generator/processor/view_processor.dart';
import 'package:froom_generator/value_object/entity.dart';
import 'package:froom_generator/value_object/query.dart';
import 'package:froom_generator/value_object/query_method.dart';
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

  test('create query method', () async {
    final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person')
      Future<List<Person>> findAllPersons();      
    ''');

    final actual =
        QueryMethodProcessor(methodElement, [...entities, ...views], {})
            .process();

    expect(
      actual,
      equals(
        QueryMethod(
          methodElement,
          'findAllPersons',
          Query('SELECT * FROM Person', []),
          await getDartTypeWithPerson('Future<List<Person>>'),
          await getDartTypeWithPerson('Person'),
          [],
          entities.first,
          {},
        ),
      ),
    );
  });

  group('FTS5 entities', () {
    for (final query in [
      'SELECT rowid, * FROM Mail',
      'SELECT Mail.rowid, text FROM Mail WHERE Mail MATCH :text',
      'SELECT _rowid_ AS "rowid", text FROM Mail',
      'SELECT * FROM (SELECT rowid, * FROM Mail) LIMIT 10',
      'WITH found AS (SELECT rowid, * FROM Mail) SELECT * FROM found',
      'SELECT ROWID, * FROM Mail',
      // also named rowid in results
      'SELECT oid, * FROM Mail',
      'SELECT rowid, * FROM Mail(:text)',
      'SELECT sub.*, 1 AS score FROM (SELECT rowid, * FROM Mail) sub',
      'SELECT rowid, *, bm25(Mail) FROM Mail WHERE Mail MATCH :text ORDER BY rank',
      'SELECT m._rowid_, m.* FROM Mail m',
      'SELECT rowid, * FROM Mail WHERE Mail MATCH :text UNION SELECT rowid, * FROM Mail',
    ]) {
      test('query selecting the rowid: $query', () async {
        final methodElement = await _createQueryMethodElement('''
          @Query('$query')
          Future<List<Mail>> findMails(String text);
        '''.replaceFirst(
            query.contains(':text') ? '' : '(String text)',
            query.contains(':text') ? '' : '()'));

        final actual =
            QueryMethodProcessor(methodElement, [...entities, ...views], {})
                .process();

        expect(actual.queryable, isA<Entity>());
      });
    }

    test('query selecting * of the table in a join fails', () async {
      final methodElement = await _createQueryMethodElement('''
        @Query('SELECT Mail.* FROM Mail JOIN Person ON Person.name = Mail.text')
        Future<List<Mail>> findAllMails();
      ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], {})
              .process();

      expect(
        actual,
        throwsInvalidGenerationSourceError(
            QueryMethodProcessorError(methodElement).fts5RowidNotSelected),
      );
    });

    for (final query in [
      'SELECT _rowid_ AS "ROWID", * FROM Mail',
      'SELECT Person.rowid, Mail.* FROM Mail JOIN Person ON Person.name = Mail.text',
      'SELECT m.* FROM Mail m',
      'SELECT * FROM Mail JOIN Person ON Person.name = Mail.text',
      'SELECT * FROM Mail UNION SELECT rowid, * FROM Mail',
      'SELECT * FROM (SELECT * FROM Mail)',
      'WITH found AS (SELECT * FROM Mail) SELECT * FROM found',
      // escaped in the source of the query
      "SELECT * FROM Mail(\\'text\\')",
    ]) {
      test('query selecting * of the table without the rowid fails: $query',
          () async {
        final methodElement = await _createQueryMethodElement('''
          @Query('$query')
          Future<List<Mail>> findAllMails();
        ''');

        final actual = () =>
            QueryMethodProcessor(methodElement, [...entities, ...views], {})
                .process();

        expect(
          actual,
          throwsInvalidGenerationSourceError(
              QueryMethodProcessorError(methodElement).fts5RowidNotSelected),
        );
      });
    }

    test('query of views selecting from later views checks the rowid',
        () async {
      // the first view selects from the second one
      final mailViews = await _getViews('''
        @DatabaseView('SELECT * FROM found_mail', viewName: 'shown_mail')
        class ShownMail {
          final String text;

          ShownMail(this.text);
        }

        @DatabaseView('SELECT * FROM Mail', viewName: 'found_mail')
        class FoundMail {
          final String text;

          FoundMail(this.text);
        }
      ''');
      final methodElement = await _createQueryMethodElement('''
        @Query('SELECT * FROM shown_mail')
        Future<List<Mail>> findAllMails();
      ''');

      final actual = () => QueryMethodProcessor(
              methodElement, [...entities, ...mailViews], {})
          .process();

      expect(
        actual,
        throwsInvalidGenerationSourceError(
            QueryMethodProcessorError(methodElement).fts5RowidNotSelected),
      );
    });

    test('query selecting columns without the rowid fails', () async {
      final methodElement = await _createQueryMethodElement('''
        @Query('SELECT text FROM Mail')
        Future<List<Mail>> findAllMails();
      ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], {})
              .process();

      expect(
        actual,
        throwsInvalidGenerationSourceError(
            QueryMethodProcessorError(methodElement).fts5RowidNotSelected),
      );
    });

    test('query not selecting the rowid fails', () async {
      final methodElement = await _createQueryMethodElement('''
        @Query('SELECT * FROM Mail')
        Future<List<Mail>> findAllMails();
      ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], {})
              .process();

      expect(
        actual,
        throwsInvalidGenerationSourceError(
            QueryMethodProcessorError(methodElement).fts5RowidNotSelected),
      );
    });
  });

  test('create query method for a view', () async {
    final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM name')
      Future<List<Name>> findAllNames();      
    ''');

    final actual =
        QueryMethodProcessor(methodElement, [...entities, ...views], {})
            .process();

    expect(
      actual,
      equals(
        QueryMethod(
          methodElement,
          'findAllNames',
          Query('SELECT * FROM name', []),
          await getDartTypeWithName('Future<List<Name>>'),
          await getDartTypeWithName('Name'),
          [],
          views.first,
          {},
        ),
      ),
    );
  });

  group('query parsing', () {
    test('parse query', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person WHERE id = :id')
      Future<Person?> findPerson(int id);
    ''');

      final actual =
          QueryMethodProcessor(methodElement, [], {}).process().query;

      expect(actual.sql, equals('SELECT * FROM Person WHERE id = ?1'));
      expect(actual.listParameters, equals(<ListParameter>[]));
    });

    test('parse query reusing a single parameter', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person WHERE id = :id AND id = :id')
      Future<Person?> findPerson(int id);
    ''');

      final actual =
          QueryMethodProcessor(methodElement, [], {}).process().query.sql;

      expect(actual, equals('SELECT * FROM Person WHERE id = ?1 AND id = ?1'));
    });

    test('parse query with multiple unordered parameters', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person WHERE name = :name AND id = :id AND id = :id AND name = :name')
      Future<Person?> findPerson(int id, String name);
    ''');

      final actual =
          QueryMethodProcessor(methodElement, [], {}).process().query.sql;

      expect(
          actual,
          equals('SELECT * FROM Person WHERE name = ?2'
              ' AND id = ?1 AND id = ?1 AND name = ?2'));
    });

    test('parse multiline query', () async {
      final methodElement = await _createQueryMethodElement("""
        @Query('''
          SELECT * FROM person
          WHERE id = :id AND custom_name = :name
        ''')
        Future<Person?> findPersonByIdAndName(int id, String name);
      """);

      final actual =
          QueryMethodProcessor(methodElement, [], {}).process().query.sql;

      expect(
        actual,
        equals(
            'SELECT * FROM person           WHERE id = ?1 AND custom_name = ?2'),
      );
    });

    test('parse concatenated string query', () async {
      final methodElement = await _createQueryMethodElement('''
        @Query('SELECT * FROM person '
            'WHERE id = :id AND custom_name = :name')
        Future<Person?> findPersonByIdAndName(int id, String name);    
      ''');

      final actual =
          QueryMethodProcessor(methodElement, [], {}).process().query.sql;

      expect(
        actual,
        equals('SELECT * FROM person WHERE id = ?1 AND custom_name = ?2'),
      );
    });

    test('Parse IN clause', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('update sports set rated = 1 where id in (:ids)')
      Future<void> setRated(List<int> ids);
    ''');

      final actual =
          QueryMethodProcessor(methodElement, [], {}).process().query;

      expect(
        actual.sql,
        equals(r'update sports set rated = 1 where id in (:varlist)'),
      );
      expect(actual.listParameters, equals([ListParameter(41, 'ids')]));
    });

    test('parses IN clause without space after IN', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('update sports set rated = 1 where id in(:ids)')
      Future<void> setRated(List<int> ids);
    ''');

      final actual =
          QueryMethodProcessor(methodElement, [], {}).process().query;

      expect(
        actual.sql,
        equals(r'update sports set rated = 1 where id in(:varlist)'),
      );
      expect(actual.listParameters, equals([ListParameter(40, 'ids')]));
    });

    test('parses IN clause with multiple spaces after IN', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('update sports set rated = 1 where id in      (:ids)')
      Future<void> setRated(List<int> ids);
    ''');

      final actual =
          QueryMethodProcessor(methodElement, [], {}).process().query;

      expect(
        actual.sql,
        equals(r'update sports set rated = 1 where id in      (:varlist)'),
      );
      expect(actual.listParameters, equals([ListParameter(46, 'ids')]));
    });

    test('Parse query with multiple IN clauses', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('update sports set rated = 1 where id in (:ids) and foo in (:bar)')
      Future<void> setRated(List<int> ids, List<int> bar);
    ''');

      final actual =
          QueryMethodProcessor(methodElement, [], {}).process().query;

      expect(
        actual.sql,
        equals(
          r'update sports set rated = 1 where id in (:varlist) '
          r'and foo in (:varlist)',
        ),
      );
      expect(actual.listParameters,
          equals([ListParameter(41, 'ids'), ListParameter(63, 'bar')]));
    });

    test('Parse query with IN clause and other parameter', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('update sports set rated = 1 where id in (:ids) AND foo = :bar')
      Future<void> setRated(List<int> ids, int bar);
    ''');

      final actual =
          QueryMethodProcessor(methodElement, [], {}).process().query;

      expect(
        actual.sql,
        equals(
          r'update sports set rated = 1 where id in (:varlist) '
          r'AND foo = ?1',
        ),
      );
      expect(actual.listParameters, equals([ListParameter(41, 'ids')]));
    });

    test('Parse query with mixed IN clauses and other parameters', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('update sports set rated = 1 where id in (:ids) AND foo = :bar AND name in (:names) and :bar = :foo')
      Future<void> setRated(String foo, List<String> names, List<int> ids, int bar);
    ''');

      final actual =
          QueryMethodProcessor(methodElement, [], {}).process().query;

      expect(
        actual.sql,
        equals(
          r'update sports set rated = 1 where id in (:varlist) AND foo = ?2 '
          r'AND name in (:varlist) and ?2 = ?1',
        ),
      );
      expect(actual.listParameters,
          equals([ListParameter(41, 'ids'), ListParameter(77, 'names')]));
    });

    test('Parse query with LIKE operator', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Persons WHERE name LIKE :name')
      Future<List<Person>> findPersonsWithNamesLike(String name);
    ''');

      final actual =
          QueryMethodProcessor(methodElement, [], {}).process().query.sql;

      expect(actual, equals('SELECT * FROM Persons WHERE name LIKE ?1'));
    });

    test('Parse query with commas', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person WHERE name IN (:name, :otherName)')
      Future<List<Person>> findPersonsWithNames(String name, String otherName);
    ''');

      final actual =
          QueryMethodProcessor(methodElement, [], {}).process().query.sql;
      expect(actual, equals('SELECT * FROM Person WHERE name IN (?1, ?2)'));
    });
  });

  group('errors', () {
    test('exception when method does not return future', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person')
      List<Person?> findAllPersons();
    ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], {})
              .process();

      final error =
          QueryMethodProcessorError(methodElement).doesNotReturnFutureNorStream;
      expect(actual, throwsInvalidGenerationSourceError(error));
    });

    test('exception when query is empty string', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('')
      Future<List<Person>> findAllPersons();
    ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], {})
              .process();

      final error = QueryMethodProcessorError(methodElement).noQueryDefined;
      expect(actual, throwsInvalidGenerationSourceError(error));
    });

    test('exception when query is null', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query()
      Future<List<Person>> findAllPersons();
    ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], {})
              .process();

      final error = QueryMethodProcessorError(methodElement).noQueryDefined;
      expect(actual, throwsInvalidGenerationSourceError(error));
    });

    test(
        'exception when query arguments do not match method parameters, no list vs list',
        () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person WHERE id = :id')
      Future<Person?> findPersonByIdAndName(List<int> id);
    ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], {})
              .process();

      final error = QueryProcessorError(methodElement)
          .queryMethodParameterIsListButVariableIsNot(':id');
      expect(actual, throwsProcessorError(error));
    });

    test('accepts list parameters after IN on a new line', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person WHERE id\\nIN (:ids)')
      Future<List<Person>> findPersonsByIds(List<int> ids);
    ''');

      final actual =
          QueryMethodProcessor(methodElement, [...entities, ...views], {})
              .process();

      expect(actual.query.listParameters, hasLength(1));
    });

    for (final call in [
      'lower(:names)',
      'abs(:names)',
      '`lower`(:names)',
      '[lower](:names)',
      'lower((:names))',
    ]) {
      test('exception when list parameter is the argument of $call',
          () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person WHERE name = $call')
      Future<List<Person>> findPersonsByNames(List<String> names);
    ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], {})
              .process();

      final error = QueryProcessorError(methodElement)
          .queryMethodParameterIsListButVariableIsNot(':names');
      expect(actual, throwsProcessorError(error));
      });
    }

    test(
        'exception when query arguments do not match method parameters, list vs no list',
        () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person WHERE id IN (:id)')
      Future<Person?> findPersonByIdAndName(int id);
    ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], {})
              .process();

      final error = QueryProcessorError(methodElement)
          .queryMethodParameterIsNormalButVariableIsList(':id');
      expect(actual, throwsProcessorError(error));
    });

    test('exception when query arguments do not match method parameters',
        () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person WHERE id = :id AND name = :name')
      Future<Person?> findPersonByIdAndName(int id);
    ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], {})
              .process();

      final error =
          QueryProcessorError(methodElement).unknownQueryVariable(':name');
      expect(actual, throwsProcessorError(error));
    });

    test('exception when query is invalid', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('DELETE * FROM Person')
      Future<void> deleteAll();
    ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], {})
              .process();

      final error = QueryMethodProcessorError(methodElement)
          .invalidQuery('DELETE * FROM Person');
      expect(actual, throwsInvalidGenerationSourceError(error));
    });

    test('exception when return type can not be resolved', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Staff WHERE id = :id')
      Future<Staff?> findStaffById(int id);
    ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], {})
              .process();

      final error =
          QueryMethodProcessorError(methodElement).unresolvedReturnType;
      expect(actual, throwsInvalidGenerationSourceError(error));
    });

    test('exception when passing nullable list parameter to query method',
        () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person WHERE id IN (:ids)')
      Future<List<Person>> findPersonsByIds(List<int>? ids);
    ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], {})
              .process();

      final parameterElement = methodElement.formalParameters.first;
      final error = QueryProcessorError(methodElement)
          .queryMethodParameterIsNullable(parameterElement);
      expect(actual, throwsProcessorError(error));
    });

    test('exception when query arguments do not match method parameters',
        () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person WHERE id = :id')
      Future<Person?> findPersonByIdAndName(int id, String name);
    ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], {})
              .process();

      final error = QueryProcessorError(methodElement)
          .unusedQueryMethodParameter(methodElement.formalParameters[1]);
      expect(actual, throwsProcessorError(error));
    });

    test(
        'throws when method returns Future of non-nullable type for single item query',
        () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person WHERE id = :id')
      Future<Person> findPersonById(int id);      
    ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], {})
              .process();

      expect(actual, throwsProcessorError());
    });

    test(
        'throws when method returns Stream of non-nullable type for single item query',
        () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person WHERE id = :id')
      Stream<Person> findPersonById(int id);      
    ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], {})
              .process();

      expect(actual, throwsProcessorError());
    });
  });
}

Future<MethodElement> _createQueryMethodElement(
  final String method,
) async {
  final library = await resolveSource(readAllSourcesFromFilesystem: true, '''
      library test;
      
      import 'package:froom_annotation/froom_annotation.dart';
      
      @dao
      abstract class PersonDao {
        $method 
      }
      
      @entity
      class Person {
        @primaryKey
        final int id;
      
        final String name;
      
        Person(this.id, this.name);
      }

      @entity
      @fts5
      class Mail {
        @primaryKey
        @ColumnInfo(name: 'rowid')
        final int id;

        final String text;

        Mail(this.id, this.text);
      }
      
      @DatabaseView("SELECT DISTINCT(name) AS name from person")
      class Name {
        final String name;
      
        Name(this.name);
      }
    ''', (resolver) async {
    return resolver
        .findLibraryByName('test')
        .then((value) => ArgumentError.checkNotNull(value))
        .then((value) => LibraryReader(value));
  });

  return library.classes.first.methods.first;
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

      @entity
      @fts5
      class Mail {
        @primaryKey
        @ColumnInfo(name: 'rowid')
        final int id;

        final String text;

        Mail(this.id, this.text);
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

Future<List<View>> _getViews([
  final String views = '''
      @DatabaseView("SELECT DISTINCT(name) AS name from person")
      class Name {
        final String name;
      
        Name(this.name);
      }
  ''',
]) async {
  final library = await resolveSource(readAllSourcesFromFilesystem: true, '''
      library test;
      
      import 'package:froom_annotation/froom_annotation.dart';
      
      $views
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
