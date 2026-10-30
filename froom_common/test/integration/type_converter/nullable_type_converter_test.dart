import 'dart:async';

import 'package:froom_common/froom_common.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite;
import 'package:test/test.dart';

import '../../test_util/database_factory.dart';

part 'nullable_type_converter_test.g.dart';

void main() {
  group('converter of non-nullable type for nullable values', () {
    late TestDatabase database;
    late OrderDao orderDao;

    setUp(() async {
      database = await $FroomTestDatabase.inMemoryDatabaseBuilder().build();
      orderDao = database.orderDao;
    });

    tearDown(() async {
      await database.close();
    });

    test('writes and reads nullable and non-nullable fields', () async {
      final created = DateTime.fromMillisecondsSinceEpoch(1000);
      final orders = [
        Order(1, created, null),
        Order(2, created, DateTime.fromMillisecondsSinceEpoch(2000)),
      ];
      await orderDao.insertOrders(orders);

      final actual = await orderDao.findAllOrders();

      expect(actual, equals(orders));
    });

    test('maps null query results and binds null parameters', () async {
      expect(await orderDao.findLatestShipment(), isNull);

      final created = DateTime.fromMillisecondsSinceEpoch(1000);
      await orderDao.insertOrders([Order(1, created, null)]);

      expect(await orderDao.findLatestShipment(), isNull);
      expect(await orderDao.findOrdersShippedAt(null), hasLength(1));
    });
  });
}

class DateTimeConverter extends TypeConverter<DateTime, int> {
  @override
  DateTime decode(int databaseValue) =>
      DateTime.fromMillisecondsSinceEpoch(databaseValue);

  @override
  int encode(DateTime value) => value.millisecondsSinceEpoch;
}

@entity
class Order {
  @primaryKey
  final int id;

  final DateTime createdAt;

  final DateTime? shippedAt;

  Order(this.id, this.createdAt, this.shippedAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          createdAt == other.createdAt &&
          shippedAt == other.shippedAt;

  @override
  int get hashCode => id.hashCode ^ createdAt.hashCode ^ shippedAt.hashCode;

  @override
  String toString() =>
      'Order{id: $id, createdAt: $createdAt, shippedAt: $shippedAt}';
}

@dao
abstract class OrderDao {
  @insert
  Future<void> insertOrders(List<Order> orders);

  @Query('SELECT * FROM `Order` ORDER BY id')
  Future<List<Order>> findAllOrders();

  @Query('SELECT MAX(shippedAt) FROM `Order`')
  Future<DateTime?> findLatestShipment();

  @Query('SELECT * FROM `Order` WHERE shippedAt IS :shippedAt')
  Future<List<Order>> findOrdersShippedAt(DateTime? shippedAt);
}

@Database(version: 1, entities: [Order])
@TypeConverters([DateTimeConverter])
abstract class TestDatabase extends FroomDatabase {
  OrderDao get orderDao;
}
