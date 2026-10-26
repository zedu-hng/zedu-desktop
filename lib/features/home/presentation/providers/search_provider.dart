import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../data/repositories/search_repository_impl.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final apiBaseService = locator<ApiBaseService>();
  return SearchRepositoryImpl(apiBaseService: apiBaseService);
});

/// Controls whether the right-side search panel overlay is visible
final searchPanelProvider = StateProvider<bool>((ref) => false);

enum SearchCategory {
  all('All', 'all'),
  messages('Messages', 'messages'),
  channels('Channels', 'channels'),
  files('Files', 'files');

  final String label;
  final String value;
  const SearchCategory(this.label, this.value);
}

class SearchState {
  final String query;
  final SearchCategory selectedCategory;
  final bool isLoading;
  final String? errorMessage;
  final List<SearchResultItem> results;
  final bool hasSearched;

  const SearchState({
    this.query = '',
    this.selectedCategory = SearchCategory.all,
    this.isLoading = false,
    this.errorMessage,
    this.results = const [],
    this.hasSearched = false,
  });

  SearchState copyWith({
    String? query,
    SearchCategory? selectedCategory,
    bool? isLoading,
    String? errorMessage,
    List<SearchResultItem>? results,
    bool? hasSearched,
  }) {
    return SearchState(
      query: query ?? this.query,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      results: results ?? this.results,
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() {
    return const SearchState();
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        query: '',
        results: const [],
        hasSearched: false,
        isLoading: false,
        errorMessage: null,
      );
      return;
    }

    final workspaceState = ref.read(workspaceProvider);
    final String? orgId = workspaceState.selectedWorkspace?.id;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      query: trimmed,
      hasSearched: true,
    );

    if (orgId == null || orgId.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No active workspace selected.',
      );
      return;
    }

    final repository = ref.read(searchRepositoryProvider);
    final result = await repository.search(
      query: trimmed,
      orgId: orgId,
      category: state.selectedCategory.value,
    );

    if (result is Success<List<SearchResultItem>>) {
      state = state.copyWith(
        isLoading: false,
        results: result.value,
        errorMessage: null,
      );
    } else if (result is Failure<List<SearchResultItem>>) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.error.message,
      );
    }
  }

  void setCategory(SearchCategory category) {
    if (state.selectedCategory == category) return;
    state = state.copyWith(selectedCategory: category);
    if (state.query.isNotEmpty) {
      search(state.query);
    }
  }

  void clear() {
    state = const SearchState();
  }
}

final searchNotifierProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);
