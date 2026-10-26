import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class SearchPanel extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const SearchPanel({super.key, required this.onClose});

  @override
  ConsumerState<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends ConsumerState<SearchPanel> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchInputChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchInputChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchInputChanged() {
    setState(() {});
  }

  void _performSearch(String query) {
    ref.read(searchNotifierProvider.notifier).search(query);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchNotifierProvider.notifier).clear();
    _focusNode.requestFocus();
  }

  void _handleResultClick(SearchResultItem result) {
    final conversationId = result.conversationId;
    if (conversationId != null && conversationId.isNotEmpty) {
      final activeChatNotifier = ref.read(activeChatProvider.notifier);
      if (result.conversationType == 'dm') {
        activeChatNotifier.selectDirectMessage(conversationId);
      } else if (result.conversationType == 'group_dm') {
        activeChatNotifier.selectGroupDm(conversationId);
      } else {
        activeChatNotifier.selectChannel(conversationId);
      }
    }
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final searchState = ref.watch(searchNotifierProvider);

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(left: BorderSide(color: colors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header with Close Button
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Search',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(Icons.close, color: colors.textHint),
                  splashRadius: 20,
                  tooltip: 'Close search',
                ),
              ],
            ),
          ),

          // 2. Search Input Field with Clear Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search messages, channels, files...',
                hintStyle: TextStyle(color: colors.textHint, fontSize: 13),
                prefixIcon: Icon(
                  Icons.search,
                  color: colors.textHint,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 18,
                          color: colors.textHint,
                        ),
                        onPressed: _clearSearch,
                        splashRadius: 16,
                        tooltip: 'Clear input',
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),

          // 3. Category Filter Pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: SearchCategory.values.map((category) {
                  final isSelected = searchState.selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        ref
                            .read(searchNotifierProvider.notifier)
                            .setCategory(category);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primary
                              : colors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? colors.primary : colors.divider,
                          ),
                        ),
                        child: Text(
                          category.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? colors.onPrimary
                                : colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 8),
          Divider(height: 1, color: colors.divider),

          // 4. Results Area
          Expanded(
            child: Builder(
              builder: (context) {
                // Loading State
                if (searchState.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: colors.primary,
                          strokeWidth: 2.5,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Searching workspace...',
                          style: TextStyle(
                            color: colors.textHint,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Error State
                if (searchState.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: colors.error,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            searchState.errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _performSearch(_searchController.text),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Initial Empty / Prompt State
                if (!searchState.hasSearched && searchState.results.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.manage_search_rounded,
                            color: colors.textHint.withValues(alpha: 0.6),
                            size: 48,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Find anything in Zedu',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Search for announcements, assignment questions, files, and discussion messages.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.textHint,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Zero Results Found State
                if (searchState.hasSearched && searchState.results.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            color: colors.textHint,
                            size: 44,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No results found',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No matches found for "${searchState.query}". Try a different search term or filter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.textHint,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Results List
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  itemCount: searchState.results.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: colors.divider),
                  itemBuilder: (context, index) {
                    final item = searchState.results[index];
                    return InkWell(
                      onTap: () => _handleResultClick(item),
                      borderRadius: BorderRadius.circular(8),
                      hoverColor: colors.primary.withValues(alpha: 0.06),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author & Location Header
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: colors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  child: Text(
                                    item.authorName.isNotEmpty
                                        ? item.authorName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.authorName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (item.conversationTitle != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.primaryBg,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: colors.divider),
                                    ),
                                    child: Text(
                                      '# ${item.conversationTitle}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.textHint,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  item.timestamp,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textHint,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Snippet / Match Text
                            Padding(
                              padding: const EdgeInsets.only(left: 32),
                              child: Text(
                                item.content,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textPrimary.withValues(
                                    alpha: 0.85,
                                  ),
                                  height: 1.35,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
