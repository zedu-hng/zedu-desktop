import 'package:zedu/core/core.dart';

import '../../domain/repositories/search_repository.dart';
import '../models/search_result_item.dart';

class SearchRepositoryImpl implements SearchRepository {
  final ApiBaseService apiBaseService;

  SearchRepositoryImpl({required this.apiBaseService});

  @override
  Future<Result<List<SearchResultItem>>> search({
    required String query,
    required String orgId,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'query': query,
        'page': page,
        'limit': limit,
      };

      if (category != null && category.isNotEmpty && category != 'all') {
        queryParams['type'] = category;
        queryParams['category'] = category;
      }

      final response = await apiBaseService.get<Map<String, dynamic>>(
        path: '/organisations/$orgId/search',
        queryParameters: queryParams,
      );

      final data = response.data;
      final rawList = data['data'] ?? data['results'] ?? data['messages'];

      final list = (rawList is List<dynamic> ? rawList : const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(SearchResultItem.fromJson)
          .toList();

      return Success(list);
    } on ApiFailure catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(ApiFailure(message: e.toString()));
    }
  }
}
