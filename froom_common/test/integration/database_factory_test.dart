import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

import 'database.dart';

void main() {
  test('database is opened by the provided database factory', () async {
    final directory = await Directory.systemTemp.createTemp('froom_factory');
    addTearDown(() => directory.delete(recursive: true));
    // databases paths are kept per factory
    final databaseFactory = createDatabaseFactoryFfi(noIsolate: true);
    await databaseFactory.setDatabasesPath(directory.path);

    final database = await $FroomTestDatabase
        .databaseBuilder('factory_test.db')
        .databaseFactory(databaseFactory)
        .build();
    addTearDown(database.close);

    expect(File(p.join(directory.path, 'factory_test.db')).existsSync(), isTrue);
    expect(await database.personDao.findAllPersons(), isEmpty);
  });
}
