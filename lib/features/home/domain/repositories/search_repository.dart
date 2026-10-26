import 'package:zedu/core/core.dart';

import '../../data/models/search_result_item.dart';

abstract class SearchRepository {
  Future<Result<List<SearchResultItem>>> search({
    required String query,
    required String orgId,
    String? category,
    int page = 1,
    int limit = 20,
  });
}
