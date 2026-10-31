@TestOn('browser')
library;

import 'dart:async';

import 'package:froom/froom.dart';
import 'package:froom/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:test/test.dart';

part 'web_database_test.g.dart';

@entity
class Note {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String text;

  Note(this.id, this.text);
}

@dao
abstract class NoteDao {
  @Query('SELECT * FROM Note')
  Future<List<Note>> findAllNotes();

  @Query('SELECT * FROM Note')
  Stream<List<Note>> findAllNotesAsStream();

  @insert
  Future<int> insertNote(Note note);
}

@Database(version: 1, entities: [Note])
abstract class NoteDatabase extends FroomDatabase {
  NoteDao get noteDao;
}

void main() {
  // the sqlite3.wasm set up next to this test by
  // `dart run sqflite_common_ffi_web:setup --dir test/web`
  final databaseFactory = createDatabaseFactoryFfiWeb(
    noWebWorker: true,
    options: SqfliteFfiWebOptions(sqlite3WasmUri: Uri.parse('sqlite3.wasm')),
  );

  test('the default database factory is the web one', () {
    expect(sqfliteDatabaseFactory, same(databaseFactoryFfiWeb));
  });

  test('database works on the web', () async {
    final database = await $FroomNoteDatabase
        .databaseBuilder('web_database_test.db')
        .databaseFactory(databaseFactory)
        .build();
    addTearDown(() async {
      await database.close();
      await databaseFactory.deleteDatabase(
          await databaseFactory.getDatabasePath('web_database_test.db'));
    });
    final noteDao = database.noteDao;
    final notes = noteDao.findAllNotesAsStream().map(
        (notes) => notes.map((note) => note.text).toList());
    final expectation = expectLater(notes, emitsInOrder([isEmpty, ['web']]));

    final id = await noteDao.insertNote(Note(null, 'web'));

    await expectation;
    expect(id, 1);
    expect((await noteDao.findAllNotes()).single.text, 'web');
  });

  // the sqlite3.wasm of sqflite_common_ffi_web can't encrypt
  test('password fails on the web', () async {
    const name = 'web_password_test.db';
    addTearDown(() async => databaseFactory
        .deleteDatabase(await databaseFactory.getDatabasePath(name)));

    await expectLater(
      $FroomNoteDatabase
          .databaseBuilder(name)
          .databaseFactory(databaseFactory)
          .password('password')
          .build(),
      throwsA(isA<DatabaseEncryptionException>()),
    );
  });

  test('password fails while the database is open on the web', () async {
    const name = 'web_open_password_test.db';
    final builder = $FroomNoteDatabase
        .databaseBuilder(name)
        .databaseFactory(databaseFactory);
    final database = await builder.build();
    addTearDown(() async {
      await database.close();
      await databaseFactory
          .deleteDatabase(await databaseFactory.getDatabasePath(name));
    });

    await expectLater(
      builder.password('password').build(),
      throwsA(isA<DatabaseEncryptionException>()),
    );
  });
}
