import 'dart:async';

import 'package:froom_common/froom_common.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite;
import 'package:test/test.dart';

import '../../test_util/database_factory.dart';

part 'double_test.g.dart';

void main() {
  group('doubles read from integer values', () {
    late TestDatabase database;
    late ItemDao itemDao;

    setUp(() async {
      database = await $FroomTestDatabase.inMemoryDatabaseBuilder().build();
      itemDao = database.itemDao;
    });

    tearDown(() async {
      await database.close();
    });

    test('scalar query returning a whole number', () async {
      expect(await itemDao.sumPrices(), equals(0.0));

      await itemDao.insertItem(Item(1, 2.5));
      await itemDao.insertItem(Item(2, 3.5));

      expect(await itemDao.sumPrices(), equals(6.0));
      expect(await itemDao.findMaxPrice(), equals(3.5));
    });

    test('view with integer values for double fields', () async {
      await itemDao.insertItem(Item(1, 2.5));

      final actual = await itemDao.findAllDiscounts();

      expect(actual.single.discount, equals(1.0));
    });
  });
}

@entity
class Item {
  @primaryKey
  final int id;

  final double price;

  Item(this.id, this.price);
}

@DatabaseView('SELECT id, 1 AS discount FROM Item', viewName: 'ItemDiscount')
class ItemDiscount {
  final int id;

  final double discount;

  ItemDiscount(this.id, this.discount);
}

@dao
abstract class ItemDao {
  @insert
  Future<void> insertItem(Item item);

  @Query('SELECT COALESCE(SUM(price), 0) FROM Item')
  Future<double?> sumPrices();

  @Query('SELECT MAX(price) FROM Item')
  Future<double?> findMaxPrice();

  @Query('SELECT * FROM ItemDiscount')
  Future<List<ItemDiscount>> findAllDiscounts();
}

@Database(version: 1, entities: [Item], views: [ItemDiscount])
abstract class TestDatabase extends FroomDatabase {
  ItemDao get itemDao;
}
