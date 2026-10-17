import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ChannelDirectoryView extends ConsumerStatefulWidget {
  const ChannelDirectoryView({super.key});

  @override
  ConsumerState<ChannelDirectoryView> createState() =>
      _ChannelDirectoryViewState();
}

class _ChannelDirectoryViewState extends ConsumerState<ChannelDirectoryView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static final _defaultChannels = [
    Channel(
      id: 'general',
      name: 'general',
      description: 'General channel for workspace discussions',
      organisationId: '',
      ownerId: '',
      membersCount: 1,
      isJoined: true,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channelState = ref.watch(channelProvider);
    final colors = context.colors;
    final textTheme = context.textTheme;

    final sourceChannels =
        channelState.channels.isNotEmpty || channelState.isLoading
        ? channelState.channels
        : _defaultChannels;

    final filteredChannels = sourceChannels.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Material(
      color: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text(
              'Directories',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          _buildTabBar(colors, textTheme),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search for channels',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colors.textHint,
                ),
                prefixIcon: Icon(Icons.search, color: colors.textHint),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.primary),
                ),
              ),
              style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('All channels', colors, textTheme),
                const SizedBox(width: 8),
                _buildFilterChip('All channel type', colors, textTheme),
                const Spacer(),
                _buildFilterChip('A to Z', colors, textTheme),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: channelState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredChannels.isEmpty
                ? Center(
                    child: Text(
                      'No channels found.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredChannels.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: colors.divider),
                    itemBuilder: (context, index) {
                      final channel = filteredChannels[index];
                      return InkWell(
                        onTap: () {
                          ref
                              .read(activeChatProvider.notifier)
                              .selectChannel(channel.name);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 16.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '# ${channel.name}',
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (channel.isJoined) ...[
                                    Icon(
                                      Icons.check,
                                      size: 14,
                                      color: colors.success,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Joined',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    '${channel.membersCount} members',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppPalette colors, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, right: 24),
            child: Row(
              children: [
                Icon(Icons.group_outlined, size: 18, color: colors.textHint),
                const SizedBox(width: 8),
                Text(
                  'People',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.primary, width: 2.5),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '#',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Channels',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    AppPalette colors,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: colors.divider),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down, size: 16, color: colors.textHint),
        ],
      ),
    );
  }
}
