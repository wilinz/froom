import 'dart:async';

import 'package:froom_common/froom_common.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite;
import 'package:test/test.dart';

import '../../test_util/database_factory.dart';

part 'implemented_type_converter_test.g.dart';

void main() {
  test('converter implementing TypeConverter and another interface', () async {
    final database = await $FroomTestDatabase.inMemoryDatabaseBuilder().build();
    addTearDown(database.close);
    final product = Product(1, const Price(1999));

    await database.productDao.insertProduct(product);

    final actual = await database.productDao.findAllProducts();
    expect(actual.single.price.cents, equals(1999));
  });
}

class Price {
  final int cents;

  const Price(this.cents);
}

/// An interface of another library, e.g. `JsonConverter` of json_annotation.
abstract class JsonLikeConverter<T, S> {
  T fromJson(S json);

  S toJson(T object);
}

class PriceConverter
    implements TypeConverter<Price, int>, JsonLikeConverter<Price, int> {
  const PriceConverter();

  @override
  Price decode(int databaseValue) => Price(databaseValue);

  @override
  int encode(Price value) => value.cents;

  @override
  Price fromJson(int json) => decode(json);

  @override
  int toJson(Price object) => encode(object);
}

@entity
class Product {
  @primaryKey
  final int id;

  final Price price;

  Product(this.id, this.price);
}

@dao
abstract class ProductDao {
  @insert
  Future<void> insertProduct(Product product);

  @Query('SELECT * FROM Product')
  Future<List<Product>> findAllProducts();
}

@Database(version: 1, entities: [Product])
@TypeConverters([PriceConverter])
abstract class TestDatabase extends FroomDatabase {
  ProductDao get productDao;
}
