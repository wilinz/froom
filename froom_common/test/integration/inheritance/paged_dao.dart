import 'package:froom_common/froom_common.dart';

const _defaultLimit = 1;

enum PageOrder { ascending, descending }

const _defaultOrder = PageOrder.descending;

abstract class PagedDao<T> {
  @Query('SELECT * FROM Person ORDER BY id LIMIT :limit')
  Future<List<T>> findPage({int limit = _defaultLimit});

  @transaction
  Future<List<T>> findOrderedPage({PageOrder order = _defaultOrder}) async {
    final page = await findPage(limit: 2);
    return order == PageOrder.ascending ? page : page.reversed.toList();
  }
}
