import 'dart:async';

import 'package:froom_common/froom_common.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite;
import 'package:test/test.dart';

import '../../test_util/database_factory.dart';

part 'setter_test.g.dart';

void main() {
  group('fields assigned via setters', () {
    late TestDatabase database;
    late SpaceDao spaceDao;

    setUp(() async {
      database = await $FroomTestDatabase.inMemoryDatabaseBuilder().build();
      spaceDao = database.spaceDao;
    });

    tearDown(() async {
      await database.close();
    });

    test('reads fields of an entity without constructor parameters', () async {
      final space = Space()
        ..id = 1
        ..name = 'Office'
        ..shared = true;
      await spaceDao.insertSpace(space);

      final actual = await spaceDao.findAllSpaces();

      expect(actual, equals([space]));
    });

    test('reads fields of mixins', () async {
      final note = Note(1, 'Buy milk')..createdAt = 42;
      await spaceDao.insertNote(note);

      final actual = await spaceDao.findAllNotes();

      expect(actual, equals([note]));
    });

    test('reads fields missing in the constructor', () async {
      final room = Room(1)..label = 'Kitchen';
      await spaceDao.insertRoom(room);

      final actual = await spaceDao.findRoomById(1);

      expect(actual?.label, equals('Kitchen'));
    });
  });
}

@entity
class Space {
  @primaryKey
  int? id;

  String? name;

  bool shared = false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Space &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          shared == other.shared;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ shared.hashCode;

  @override
  String toString() => 'Space{id: $id, name: $name, shared: $shared}';
}

@entity
class Room {
  @primaryKey
  final int id;

  String? label;

  Room(this.id);
}

mixin Timestamped {
  int? createdAt;
}

/// Mimics `EquatableMixin` of the equatable package.
mixin EquatableLike {
  List<Object?> get props;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquatableLike &&
          runtimeType == other.runtimeType &&
          props.length == other.props.length &&
          Iterable.generate(props.length)
              .every((index) => props[index] == other.props[index]);

  @override
  int get hashCode => Object.hashAll(props);
}

@entity
class Note with Timestamped, EquatableLike {
  @primaryKey
  final int id;

  final String text;

  Note(this.id, this.text);

  @override
  List<Object?> get props => [id, text, createdAt];
}

@dao
abstract class SpaceDao {
  @insert
  Future<void> insertNote(Note note);

  @Query('SELECT * FROM Note')
  Future<List<Note>> findAllNotes();

  @insert
  Future<void> insertSpace(Space space);

  @Query('SELECT * FROM Space')
  Future<List<Space>> findAllSpaces();

  @insert
  Future<void> insertRoom(Room room);

  @Query('SELECT * FROM Room WHERE id = :id')
  Future<Room?> findRoomById(int id);
}

@Database(version: 1, entities: [Space, Room, Note])
abstract class TestDatabase extends FroomDatabase {
  SpaceDao get spaceDao;
}
