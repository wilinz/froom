import 'dart:async';

import 'package:froom_common/froom_common.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite;
import 'package:test/test.dart';

import '../../test_util/database_factory.dart';

part 'upsert_test.g.dart';

void main() {
  group('upsert tests', () {
    late TestDatabase database;
    late BookDao bookDao;

    final publisher = Publisher('p1', 'publisher 1');
    final book = Book('b1', 'book 1', 'p1', 'description 1', null);

    setUp(() async {
      database = await $FroomTestDatabase.inMemoryDatabaseBuilder().build();
      bookDao = database.bookDao;
    });

    tearDown(() async {
      await database.close();
    });

    group('multiple parameters', () {
      test('upsert publisher and book', () async {
        await bookDao.upsertPublisherAndBook(publisher, book);

        expect(await bookDao.findAllPublishers(), equals([publisher]));
        expect(await bookDao.findAllBooks(), equals([book]));

        final changedPublisher = Publisher('p1', 'changed name');
        final changedBook = book.copyWith(title: 'changed title');
        await bookDao.upsertPublisherAndBook(changedPublisher, changedBook);

        expect(await bookDao.findAllPublishers(), equals([changedPublisher]));
        expect(await bookDao.findAllBooks(), equals([changedBook]));
      });

      test('upsert item and list parameters', () async {
        await bookDao.upsertPublishers(publisher, [
          Publisher('p2', 'publisher 2'),
          Publisher('p1', 'changed publisher 1'),
        ]);

        expect(
          await bookDao.findAllPublishers(),
          equals([
            Publisher('p1', 'changed publisher 1'),
            Publisher('p2', 'publisher 2'),
          ]),
        );
      });

      test('rolls back all parameters on failure', () async {
        final bookOfUnknownPublisher = book.copyWith(publisherId: 'unknown');

        final actual =
            bookDao.upsertPublisherAndBook(publisher, bookOfUnknownPublisher);

        await expectLater(actual, throwsA(isA<sqflite.DatabaseException>()));
        expect(await bookDao.findAllPublishers(), isEmpty);
        expect(await bookDao.findAllBooks(), isEmpty);
      });

      test('upsert within a transaction method', () async {
        await bookDao.upsertInTransaction(publisher, book);

        expect(await bookDao.findAllPublishers(), equals([publisher]));
        expect(await bookDao.findAllBooks(), equals([book]));
      });

      test('emits stream updates', () async {
        await bookDao.upsertPublisherAndBook(publisher, book);
        final changedBook = book.copyWith(title: 'changed title');

        final actual = bookDao.findAllBooksAsStream();
        expect(actual, emits([book]));

        await bookDao.upsertPublisherAndBook(publisher, changedBook);
        expect(actual, emits([changedBook]));
      });
    });

    group('partial entity', () {
      setUp(() async {
        await bookDao.upsertPublisherAndBook(publisher, book);
      });

      test('insert partial entity', () async {
        await bookDao.upsertMiniBook(MiniBook('b2', 'book 2', 'p1'));

        final actual = await bookDao.findBookById('b2');
        expect(actual, equals(Book('b2', 'book 2', 'p1', null, null)));
      });

      test('update only columns of partial entity', () async {
        await bookDao.upsertMiniBook(MiniBook('b1', 'changed title', 'p1'));

        final actual = await bookDao.findBookById('b1');
        expect(actual, equals(book.copyWith(title: 'changed title')));
      });

      test('upsert list of partial entities and return ids', () async {
        final actual = await bookDao.upsertMiniBooks([
          MiniBook('b1', 'changed title', 'p1'),
          MiniBook('b2', 'book 2', 'p1'),
        ]);

        expect(actual, equals([-1, 2]));
        expect(
          await bookDao.findAllBooks(),
          equals([
            book.copyWith(title: 'changed title'),
            Book('b2', 'book 2', 'p1', null, null),
          ]),
        );
      });

      test('upsert partial entity with type converter', () async {
        final publishedAt = DateTime(2026, 10, 30);

        await bookDao.upsertBookPublication(
          BookPublication('b1', 'book 1', 'p1', publishedAt),
        );

        final actual = await bookDao.findBookById('b1');
        expect(actual, equals(book.copyWith(publishedAt: publishedAt)));
      });

      test('insert partial entity without auto generated primary key',
          () async {
        await bookDao.upsertNoteContent(NoteContent('first'));
        await bookDao.upsertNoteContent(NoteContent('second'));

        final actual = await bookDao.findAllNotes();
        expect(
          actual,
          equals([Note(1, 'first', null), Note(2, 'second', null)]),
        );
      });
    });

    test('conflict on other unique index is rethrown', () async {
      await bookDao.upsertPublisher(publisher);

      final actual = bookDao.upsertPublisher(Publisher('p2', publisher.name));

      await expectLater(actual, throwsA(isA<sqflite.DatabaseException>()));
      expect(await bookDao.findAllPublishers(), equals([publisher]));
    });

    test('foreign key constraint failure is rethrown', () async {
      await bookDao.upsertPublisherAndBook(publisher, book);

      final actual = bookDao.upsertBook(book.copyWith(publisherId: 'unknown'));

      await expectLater(actual, throwsA(isA<sqflite.DatabaseException>()));
    });
  });
}

class DateTimeConverter extends TypeConverter<DateTime?, int?> {
  @override
  DateTime? decode(int? databaseValue) {
    return databaseValue == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(databaseValue);
  }

  @override
  int? encode(DateTime? value) {
    return value?.millisecondsSinceEpoch;
  }
}

@Entity(
  indices: [
    Index(value: ['name'], unique: true)
  ],
)
class Publisher {
  @primaryKey
  final String id;

  final String name;

  Publisher(this.id, this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Publisher &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() {
    return 'Publisher{id: $id, name: $name}';
  }
}

@Entity(
  foreignKeys: [
    ForeignKey(
      childColumns: ['publisher_id'],
      parentColumns: ['id'],
      entity: Publisher,
    )
  ],
)
class Book {
  @primaryKey
  final String id;

  final String title;

  @ColumnInfo(name: 'publisher_id')
  final String publisherId;

  final String? description;

  @ColumnInfo(name: 'published_at')
  final DateTime? publishedAt;

  Book(
    this.id,
    this.title,
    this.publisherId,
    this.description,
    this.publishedAt,
  );

  Book copyWith({
    String? title,
    String? publisherId,
    DateTime? publishedAt,
  }) {
    return Book(
      id,
      title ?? this.title,
      publisherId ?? this.publisherId,
      description,
      publishedAt ?? this.publishedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          publisherId == other.publisherId &&
          description == other.description &&
          publishedAt == other.publishedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      publisherId.hashCode ^
      description.hashCode ^
      publishedAt.hashCode;

  @override
  String toString() {
    return 'Book{id: $id, title: $title, publisherId: $publisherId, description: $description, publishedAt: $publishedAt}';
  }
}

/// Partial entity of [Book].
class MiniBook {
  final String id;

  final String title;

  @ColumnInfo(name: 'publisher_id')
  final String publisherId;

  MiniBook(this.id, this.title, this.publisherId);
}

/// Partial entity of [Book] with a type converted column.
class BookPublication {
  final String id;

  final String title;

  @ColumnInfo(name: 'publisher_id')
  final String publisherId;

  @ColumnInfo(name: 'published_at')
  final DateTime? publishedAt;

  BookPublication(this.id, this.title, this.publisherId, this.publishedAt);
}

@entity
class Note {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String content;

  final String? tag;

  Note(this.id, this.content, this.tag);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          content == other.content &&
          tag == other.tag;

  @override
  int get hashCode => id.hashCode ^ content.hashCode ^ tag.hashCode;

  @override
  String toString() {
    return 'Note{id: $id, content: $content, tag: $tag}';
  }
}

/// Partial entity of [Note] without its auto generated primary key.
class NoteContent {
  final String content;

  NoteContent(this.content);
}

@Database(version: 1, entities: [Publisher, Book, Note])
@TypeConverters([DateTimeConverter])
abstract class TestDatabase extends FroomDatabase {
  BookDao get bookDao;
}

@dao
abstract class BookDao {
  @Query('SELECT * FROM Publisher')
  Future<List<Publisher>> findAllPublishers();

  @Query('SELECT * FROM Book')
  Future<List<Book>> findAllBooks();

  @Query('SELECT * FROM Book')
  Stream<List<Book>> findAllBooksAsStream();

  @Query('SELECT * FROM Book WHERE id = :id')
  Future<Book?> findBookById(String id);

  @Query('SELECT * FROM Note')
  Future<List<Note>> findAllNotes();

  @upsert
  Future<void> upsertPublisher(Publisher publisher);

  @upsert
  Future<void> upsertBook(Book book);

  @upsert
  Future<void> upsertPublisherAndBook(Publisher publisher, Book book);

  @upsert
  Future<void> upsertPublishers(
    Publisher publisher,
    List<Publisher> publishers,
  );

  @Upsert(entity: Book)
  Future<void> upsertMiniBook(MiniBook miniBook);

  @Upsert(entity: Book)
  Future<List<int>> upsertMiniBooks(List<MiniBook> miniBooks);

  @Upsert(entity: Book)
  Future<void> upsertBookPublication(BookPublication bookPublication);

  @Upsert(entity: Note)
  Future<void> upsertNoteContent(NoteContent noteContent);

  @transaction
  Future<void> upsertInTransaction(Publisher publisher, Book book) async {
    await upsertPublisherAndBook(publisher, book);
  }
}
