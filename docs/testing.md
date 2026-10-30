# Testing

Simply instantiate an in-memory database and run the database tests on your local development machine as shown in the following snippet.
For more test references, check out the [project's tests](https://github.com/wilinz/froom/tree/develop/froom_common/test/integration).
They test the pure Dart package `froom_common` with `package:test`; in a Flutter project, import `package:froom/froom.dart` and use `flutter_test` as shown below.

In case you're running Linux, make sure to have sqlite3 and libsqlite3-dev installed.

```dart
import 'package:froom/froom.dart';
import 'package:flutter_test/flutter_test.dart';

// your imports follow here
import 'dao/person_dao.dart';
import 'database.dart';
import 'model/person.dart';

void main() {
  group('database tests', () {
    late TestDatabase database;
    late PersonDao personDao;

    setUp(() async {
      database = await $FroomTestDatabase
          .inMemoryDatabaseBuilder()
          .build();
      personDao = database.personDao;
    });

    tearDown(() async {
      await database.close();
    });

    test('find person by id', () async {
      final person = Person(1, 'Simon');
      await personDao.insertPerson(person);

      final actual = await personDao.findPersonById(person.id);

      expect(actual, equals(person));
    });
  });
}
```
