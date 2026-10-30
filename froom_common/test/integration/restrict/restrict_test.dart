import 'dart:async';
import 'dart:io';

import 'package:froom_common/froom_common.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqlite_api.dart' as sqflite;
import 'package:test/test.dart';

import '../../test_util/database_factory.dart';

part 'restrict_test.g.dart';

void main() {
  group('RESTRICT foreign keys', () {
    test('clearing all tables deletes parents with children', () async {
      final database =
          await $FroomRestrictDatabase.inMemoryDatabaseBuilder().build();
      addTearDown(database.close);
      await database.ownerDao.insertOwner(Owner(1));
      await database.ownerDao.insertPet(Pet(2, 1));

      await database.clearAllTables();

      expect(await database.ownerDao.findAllOwners(), isEmpty);
      expect(await database.ownerDao.findAllPets(), isEmpty);
      // foreign keys are enforced again
      final actual = database.ownerDao.insertPet(Pet(3, 42));
      await expectLater(actual, throwsA(isA<sqflite.DatabaseException>()));
    });

    test('destructive downgrade drops parents with children', () async {
      final directory = await Directory.systemTemp.createTemp('froom_restrict');
      addTearDown(() => directory.delete(recursive: true));
      final path = p.join(directory.path, 'restrict.db');

      final newer = await $FroomNewerRestrictDatabase.databaseBuilder(path).build();
      await newer.seedDao.insertOwner(Owner(1));
      await newer.seedDao.insertPet(Pet(2, 1));
      await newer.close();

      final database = await $FroomRestrictDatabase
          .databaseBuilder(path)
          .fallbackToDestructiveMigration()
          .build();
      addTearDown(database.close);

      expect(await database.ownerDao.findAllOwners(), isEmpty);
      expect(await database.ownerDao.findAllPets(), isEmpty);
    });
  });
}

@entity
class Owner {
  @primaryKey
  final int id;

  Owner(this.id);
}

@Entity(foreignKeys: [
  ForeignKey(
    childColumns: ['ownerId'],
    parentColumns: ['id'],
    entity: Owner,
    onDelete: ForeignKeyAction.restrict,
  ),
])
class Pet {
  @primaryKey
  final int id;

  final int ownerId;

  Pet(this.id, this.ownerId);
}

@dao
abstract class OwnerDao {
  @insert
  Future<void> insertOwner(Owner owner);

  @insert
  Future<void> insertPet(Pet pet);

  @Query('SELECT * FROM Owner')
  Future<List<Owner>> findAllOwners();

  @Query('SELECT * FROM Pet')
  Future<List<Pet>> findAllPets();
}

@Database(version: 1, entities: [Owner, Pet])
abstract class RestrictDatabase extends FroomDatabase {
  OwnerDao get ownerDao;
}

@dao
abstract class SeedDao {
  @insert
  Future<void> insertOwner(Owner owner);

  @insert
  Future<void> insertPet(Pet pet);
}

@Database(version: 2, entities: [Owner, Pet])
abstract class NewerRestrictDatabase extends FroomDatabase {
  SeedDao get seedDao;
}
