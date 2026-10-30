import 'package:froom_common/froom_common.dart';

const _defaultLimit = 1;

abstract class PagedDao<T> {
  @Query('SELECT * FROM Person ORDER BY id LIMIT :limit')
  Future<List<T>> findPage({int limit = _defaultLimit});
}
