import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  final apiBaseService = locator<ApiBaseService>();
  final remoteDataSource = ChannelRemoteDataSourceImpl(
    apiBaseService: apiBaseService,
  );
  return ChannelRepositoryImpl(remoteDataSource: remoteDataSource);
});

class ChannelNotifier extends AsyncNotifier<List<Channel>> {
  @override
  Future<List<Channel>> build() async {
    // Watching the workspace id rebuilds this provider when the workspace
    // changes, and Riverpod drops the result of the older request.
    final orgId = ref.watch(
      workspaceProvider.select((s) => s.selectedWorkspace?.id),
    );
    if (orgId == null) return const [];

    final timer = Timer.periodic(const Duration(seconds: 10), (_) {
      refreshUnreadCounts();
    });
    ref.onDispose(timer.cancel);

    final result = await ref
        .read(channelRepositoryProvider)
        .fetchChannels(orgId);

    return switch (result) {
      Success<List<Channel>>(:final value) => _clearActiveUnread(value),
      Failure<List<Channel>>(:final error) => throw error,
    };
  }

  bool _isCreating = false;
  bool _refreshingUnread = false;

  List<Channel> _clearActiveUnread(List<Channel> channels) {
    final active = ref.read(activeChatProvider);
    return [
      for (final channel in channels)
        if (ref.read(homeSidebarProvider) != HomeSidebarType.dms &&
            active.type == ActiveChatType.channel &&
            (channel.id == active.id || channel.name == active.id))
          _readActive(channel)
        else
          channel,
    ];
  }

  Channel _readActive(Channel channel) {
    if (channel.unreadCount > 0) {
      unawaited(_syncRead(channel.id));
    }
    return channel.copyWith(unreadCount: 0);
  }

  void markRead(String channelId) {
    final channels = state.value;
    if (channels == null) return;
    state = AsyncData([
      for (final channel in channels)
        if (channel.id == channelId || channel.name == channelId)
          channel.copyWith(unreadCount: 0)
        else
          channel,
    ]);
    if (ref.exists(channelRepositoryProvider)) {
      final channel = channels
          .where((c) => c.id == channelId || c.name == channelId)
          .firstOrNull;
      if (channel != null && channel.id.isNotEmpty) {
        unawaited(_syncRead(channel.id));
      }
    }
  }

  Future<void> _syncRead(String channelId) async {
    try {
      await ref.read(channelRepositoryProvider).markRead(channelId);
    } catch (_) {
      // Background refresh reconciles unread counts if the read request fails.
    }
  }

  Future<void> refreshUnreadCounts() async {
    if (_refreshingUnread || !state.hasValue) return;
    final orgId = ref.read(workspaceProvider).selectedWorkspace?.id;
    if (orgId == null) return;
    _refreshingUnread = true;
    try {
      final result = await ref
          .read(channelRepositoryProvider)
          .fetchChannels(orgId);
      if (!ref.mounted ||
          ref.read(workspaceProvider).selectedWorkspace?.id != orgId) {
        return;
      }
      if (result case Success<List<Channel>>(:final value)) {
        state = AsyncData(_clearActiveUnread(value));
      }
    } catch (_) {
      // A background refresh must not replace the visible list with an error.
    } finally {
      _refreshingUnread = false;
    }
  }

  /// Creates a channel and returns the outcome to the caller. The list state
  /// is only touched on success, so a create error never shows up as a load
  /// error and the dialog keeps its own error.
  Future<Result<Channel>> createChannel({
    required String name,
    required String description,
    required bool isPrivate,
    String? topic,
  }) async {
    // A second tap before the screen rebuilds must not start a second create.
    if (_isCreating) {
      return const Failure<Channel>(
        ApiFailure(
          message: 'A channel is already being created.',
          kind: ApiFailureKind.client,
        ),
      );
    }

    final String? orgId = ref.read(workspaceProvider).selectedWorkspace?.id;
    final authState = ref.read(authNotifierProvider);
    final String? username =
        authState.user?.username ?? authState.user?.email.split('@').first;

    if (orgId == null || username == null) {
      return const Failure<Channel>(
        ApiFailure(
          message: 'Could not create the channel. Please try again.',
          kind: ApiFailureKind.client,
        ),
      );
    }

    _isCreating = true;
    final Result<Channel> result;
    try {
      result = await ref
          .read(channelRepositoryProvider)
          .createChannel(
            name: name,
            description: description,
            orgId: orgId,
            username: username,
            isPrivate: isPrivate,
            topic: topic,
          );
    } finally {
      _isCreating = false;
    }

    // The workspace changed while creating, and build() has already reloaded
    // the list for the new one, so leave the state alone.
    if (ref.read(workspaceProvider).selectedWorkspace?.id != orgId) {
      return result;
    }

    if (result case Success<Channel>(:final value)) {
      final channels = state.value ?? const <Channel>[];
      state = AsyncData([
        ...channels.where((c) => c.id.isEmpty || c.id != value.id),
        value,
      ]);
    }
    return result;
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
      final updatedChannels = (state.value ?? const <Channel>[]).map((c) {
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
      state = AsyncData(updatedChannels);
      return true;
    }
    return false;
  }
}

final channelProvider = AsyncNotifierProvider<ChannelNotifier, List<Channel>>(
  ChannelNotifier.new,
  // A failed load is shown once instead of being retried in the background.
  retry: (_, _) => null,
);
