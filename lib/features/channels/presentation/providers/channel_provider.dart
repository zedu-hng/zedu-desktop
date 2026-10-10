import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  final apiBaseService = locator<ApiBaseService>();
  final remoteDataSource = ChannelRemoteDataSourceImpl(
    apiBaseService: apiBaseService,
  );
  return ChannelRepositoryImpl(remoteDataSource: remoteDataSource);
});

class ChannelState {
  final List<Channel> channels;
  final bool isLoading;
  final String? errorMessage;

  const ChannelState({
    this.channels = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ChannelState copyWith({
    List<Channel>? channels,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ChannelState(
      channels: channels ?? this.channels,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ChannelNotifier extends Notifier<ChannelState> {
  // Counts fetches so an older request can't overwrite a newer one
  int _fetchGeneration = 0;

  @override
  ChannelState build() {
    // Reload channels whenever the selected workspace changes
    ref.watch(workspaceProvider.select((s) => s.selectedWorkspace?.id));
    Future.microtask(fetchChannels);
    return const ChannelState();
  }

  Future<void> fetchChannels() async {
    final workspaceState = ref.read(workspaceProvider);
    final String? orgId = workspaceState.selectedWorkspace?.id;
    if (orgId == null) return;

    final generation = ++_fetchGeneration;
    state = state.copyWith(isLoading: true, errorMessage: null);

    final repository = ref.read(channelRepositoryProvider);
    final result = await repository.fetchChannels(orgId);

    // Ignore the result if a newer fetch started or the workspace changed
    if (generation != _fetchGeneration ||
        ref.read(workspaceProvider).selectedWorkspace?.id != orgId) {
      return;
    }

    if (result is Success<List<Channel>>) {
      state = state.copyWith(isLoading: false, channels: result.value);
    } else if (result is Failure<List<Channel>>) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.error.message,
      );
    }
  }

  Future<bool> createChannel({
    required String name,
    required String description,
    required bool isPrivate,
    String? topic,
  }) async {
    final workspaceState = ref.read(workspaceProvider);
    final authState = ref.read(authNotifierProvider);
    final String? orgId = workspaceState.selectedWorkspace?.id;
    final String? username =
        authState.user?.username ?? authState.user?.email.split('@').first;

    if (orgId == null || username == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);

    final repository = ref.read(channelRepositoryProvider);
    final result = await repository.createChannel(
      name: name,
      description: description,
      orgId: orgId,
      username: username,
      isPrivate: isPrivate,
      topic: topic,
    );

    // Don't touch the list if the user switched workspace while creating
    if (ref.read(workspaceProvider).selectedWorkspace?.id != orgId) {
      return result is Success<Channel>;
    }

    if (result is Success<Channel>) {
      // Drop any older fetch still in flight so it can't hide the new channel
      _fetchGeneration++;
      state = state.copyWith(
        isLoading: false,
        channels: [
          ...state.channels.where((c) => c.id != result.value.id),
          result.value,
        ],
      );
      return true;
    }
    state = state.copyWith(
      isLoading: false,
      errorMessage: result is Failure<Channel> ? result.error.message : null,
    );
    return false;
  }

  Future<bool> updateChannelTopicOrDescription({
    required String channelId,
    String? topic,
    String? description,
  }) async {
    final repository = ref.read(channelRepositoryProvider);
    final result = await repository.updateChannelTopicOrDescription(
      channelId: channelId,
      topic: topic,
      description: description,
    );

    if (result is Success<void>) {
      // Update local state
      final updatedChannels = state.channels.map((c) {
        if (c.id == channelId) {
          return Channel(
            id: c.id,
            name: c.name,
            description: description ?? c.description,
            organisationId: c.organisationId,
            isPrivate: c.isPrivate,
            ownerId: c.ownerId,
            archived: c.archived,
            topic: topic ?? c.topic,
            unreadCount: c.unreadCount,
            membersCount: c.membersCount,
          );
        }
        return c;
      }).toList();
      state = state.copyWith(channels: updatedChannels);
      return true;
    }
    return false;
  }
}

final channelProvider = NotifierProvider<ChannelNotifier, ChannelState>(
  ChannelNotifier.new,
);
