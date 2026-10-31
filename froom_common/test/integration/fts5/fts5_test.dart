import 'package:test/test.dart';

import 'note_database.dart';

void main() {
  group('FTS5', () {
    late NoteDatabase database;
    late NoteDao noteDao;

    setUp(() async {
      database = await $FroomNoteDatabase.inMemoryDatabaseBuilder().build();
      noteDao = database.noteDao;
    });

    tearDown(() => database.close());

    test('inserts with generated row ids and finds matches', () async {
      final firstId = await noteDao.insertNote(Note(0, 'hello world', 'ann'));
      final secondId = await noteDao.insertNote(Note(0, 'goodbye', 'bob'));

      expect(await noteDao.findAllNotes(), [
        Note(firstId, 'hello world', 'ann'),
        Note(secondId, 'goodbye', 'bob'),
      ]);
      expect(await noteDao.search('hello'), [Note(firstId, 'hello world', 'ann')]);
      // prefix queries
      expect(await noteDao.search('go*'), [Note(secondId, 'goodbye', 'bob')]);
    });

    test('indexes the token characters of the tokenizer', () async {
      await noteDao.insertNote(Note(1, 'well-known', 'ann'));

      expect(await noteDao.search('"well-known"'), hasLength(1));
      expect(await noteDao.search('known'), isEmpty);
    });

    test('does not index columns of notIndexed', () async {
      await noteDao.insertNote(Note(1, 'hello', 'ann'));

      expect(await noteDao.search('ann'), isEmpty);
    });

    test('updates, upserts and deletes by row id', () async {
      await noteDao.insertNote(Note(1, 'hello', 'ann'));

      await noteDao.updateNote(Note(1, 'updated', 'ann'));
      await noteDao.upsertNote(Note(1, 'upserted', 'bob'));
      await noteDao.upsertNote(Note(2, 'new', 'bob'));

      expect(await noteDao.findAllNotes(), [
        Note(1, 'upserted', 'bob'),
        Note(2, 'new', 'bob'),
      ]);
      expect(await noteDao.search('updated'), isEmpty);

      await noteDao.deleteNote(Note(1, 'upserted', 'bob'));

      expect(await noteDao.findAllNotes(), [Note(2, 'new', 'bob')]);
    });

    test('notifies streams', () async {
      final stream = noteDao.findAllNotesAsStream();
      final expectation = expectLater(
        stream,
        emitsInOrder([isEmpty, [Note(1, 'hello', 'ann')]]),
      );

      await noteDao.insertNote(Note(1, 'hello', 'ann'));

      await expectation;
    });
  });
}
