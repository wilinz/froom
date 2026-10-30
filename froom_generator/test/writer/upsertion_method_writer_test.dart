import 'package:code_builder/code_builder.dart';
import 'package:froom_generator/value_object/upsertion_method.dart';
import 'package:froom_generator/writer/upsertion_method_writer.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  useDartfmt();

  group('void return upsert', () {
    test('upsert single person', () async {
      final upsertionMethod = await _createUpsertionMethod('''
        @upsert
        Future<void> upsertPerson(Person person);
      ''');

      final actual = UpsertionMethodWriter(upsertionMethod).write();

      expect(actual, equalsDart(r'''
        @override
        Future<void> upsertPerson(Person person) async {
          await _personUpsertionAdapter.upsert(person);
        }
      '''));
    });

    test('upsert person list', () async {
      final upsertionMethod = await _createUpsertionMethod('''
        @upsert
        Future<void> upsertPersons(List<Person> persons);
      ''');

      final actual = UpsertionMethodWriter(upsertionMethod).write();

      expect(actual, equalsDart('''
        @override
        Future<void> upsertPersons(List<Person> persons) async {
          await _personUpsertionAdapter.upsertList(persons);
        }
      '''));
    });
  });

  group('int return upsert', () {
    test('upsert single person', () async {
      final upsertionMethod = await _createUpsertionMethod('''
        @upsert
        Future<int> upsertPersonWithReturn(Person person);
      ''');

      final actual = UpsertionMethodWriter(upsertionMethod).write();

      expect(actual, equalsDart('''
        @override
        Future<int> upsertPersonWithReturn(Person person) {
          return _personUpsertionAdapter.upsertAndReturnId(person);
        }
      '''));
    });

    test('upsert person list', () async {
      final upsertionMethod = await _createUpsertionMethod('''
        @upsert
        Future<List<int>> upsertPersonsWithReturn(List<Person> persons);
      ''');

      final actual = UpsertionMethodWriter(upsertionMethod).write();

      expect(actual, equalsDart('''
        @override
        Future<List<int>> upsertPersonsWithReturn(List<Person> persons) {
          return _personUpsertionAdapter.upsertListAndReturnIds(persons);
        }
      '''));
    });
  });

  test('upsert multiple parameters in a transaction', () async {
    final upsertionMethod = await _createUpsertionMethod('''
        @upsert
        Future<void> upsertPersons(Person person, List<Person> persons);
      ''');

    final actual = UpsertionMethodWriter(upsertionMethod).write();

    expect(actual, equalsDart(r'''
        @override
        Future<void> upsertPersons(
          Person person,
          List<Person> persons,
        ) async {
          if (database is sqflite.Transaction) {
            await _personUpsertionAdapter.upsert(person);
            await _personUpsertionAdapter.upsertList(persons);
          } else {
            await (database as sqflite.Database).transaction<void>((transaction) async {
              final transactionDatabase = _$TestDatabase(changeListener)..database = transaction;
              await transactionDatabase.personDao.upsertPersons(person, persons);
            });
          }
        }
      '''));
  });
}

Future<UpsertionMethod> _createUpsertionMethod(
  final String methodSignature,
) async {
  final dao = await createDao(methodSignature);
  return dao.upsertionMethods.first;
}
