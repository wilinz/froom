import 'dart:async';

import 'package:froom_common/froom_common.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite;

import '../../test_util/database_factory.dart';

part 'note_database.g.dart';

@Entity(tableName: 'note')
@Fts5(tokenizerArgs: ['tokenchars', '-_'], prefixes: [2], notIndexed: ['author'])
class Note {
  @PrimaryKey(autoGenerate: true)
  @ColumnInfo(name: 'rowid')
  final int id;

  final String text;

  final String author;

  Note(this.id, this.text, this.author);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note &&
          id == other.id &&
          text == other.text &&
          author == other.author;

  @override
  int get hashCode => Object.hash(id, text, author);

  @override
  String toString() => 'Note{id: $id, text: $text, author: $author}';
}

@dao
abstract class NoteDao {
  // FTS5 tables don't return the row id for *
  @Query('SELECT rowid, * FROM note WHERE note MATCH :query ORDER BY rowid')
  Future<List<Note>> search(String query);

  @Query('SELECT rowid, * FROM note ORDER BY rowid')
  Future<List<Note>> findAllNotes();

  @Query('SELECT rowid, * FROM note ORDER BY rowid')
  Stream<List<Note>> findAllNotesAsStream();

  @insert
  Future<int> insertNote(Note note);

  @update
  Future<void> updateNote(Note note);

  @upsert
  Future<void> upsertNote(Note note);

  @delete
  Future<void> deleteNote(Note note);
}

@Database(version: 1, entities: [Note])
abstract class NoteDatabase extends FroomDatabase {
  NoteDao get noteDao;
}
