import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final currentOrgIdProvider = Provider<String>((ref) {
  final workspace = ref.watch(workspaceProvider).selectedWorkspace;
  return workspace?.id ?? '';
});

final dmListProvider =
    AsyncNotifierProvider<DmListNotifier, List<DmConversation>>(() {
      return DmListNotifier();
    });

class SelectedDmNotifier extends Notifier<DmConversation?> {
  @override
  DmConversation? build() => null;

  void select(DmConversation? conversation) {
    state = conversation;
    if (conversation != null && ref.exists(dmListProvider)) {
      ref.read(dmListProvider.notifier).markRead(conversation.channelId);
    }
  }
}

final selectedDmProvider =
    NotifierProvider<SelectedDmNotifier, DmConversation?>(
      SelectedDmNotifier.new,
    );

class DmListNotifier extends AsyncNotifier<List<DmConversation>> {
  int _currentPage = 1;
  bool _hasMore = true;
  bool _refreshingUnread = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<DmConversation>> build() async {
    final orgId = ref.watch(currentOrgIdProvider);
    if (orgId.isEmpty) return const [];

    _currentPage = 1;
    _hasMore = true;
    final timer = Timer.periodic(const Duration(seconds: 10), (_) {
      refreshUnreadCounts();
    });
    ref.onDispose(timer.cancel);
    return _clearActiveUnread(await _fetchPage(orgId, 1));
  }

  List<DmConversation> _clearActiveUnread(List<DmConversation> conversations) {
    final selected = ref.read(homeSidebarProvider) == HomeSidebarType.dms
        ? ref.read(selectedDmProvider)?.channelId
        : null;
    return [
      for (final conversation in conversations)
        if (conversation.channelId == selected)
          _readActive(conversation)
        else
          conversation,
    ];
  }

  DmConversation _readActive(DmConversation conversation) {
    if (conversation.unreadCount > 0) {
      unawaited(_syncRead(conversation.channelId));
    }
    return conversation.copyWith(unreadCount: 0);
  }

  void markRead(String channelId) {
    final conversations = state.value;
    if (conversations == null) return;
    state = AsyncData([
      for (final conversation in conversations)
        if (conversation.channelId == channelId)
          conversation.copyWith(unreadCount: 0)
        else
          conversation,
    ]);
    if (ref.exists(dmRepositoryProvider)) {
      unawaited(_syncRead(channelId));
    }
  }

  Future<void> _syncRead(String channelId) async {
    try {
      await ref.read(dmRepositoryProvider).markRead(channelId);
    } catch (_) {
      // Background refresh reconciles unread counts if the read request fails.
    }
  }

  Future<void> refreshUnreadCounts() async {
    if (_refreshingUnread || !state.hasValue) return;
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId.isEmpty) return;
    _refreshingUnread = true;
    final pages = _currentPage;
    try {
      final repository = ref.read(dmRepositoryProvider);
      final conversations = <DmConversation>[];
      for (var page = 1; page <= pages; page++) {
        conversations.addAll(
          await repository.getConversations(orgId: orgId, page: page),
        );
      }
      if (!ref.mounted ||
          ref.read(currentOrgIdProvider) != orgId ||
          pages != _currentPage) {
        return;
      }
      state = AsyncData(_clearActiveUnread(conversations));
    } catch (_) {
      // Keep the visible list when a background request fails.
    } finally {
      _refreshingUnread = false;
    }
  }

  Future<List<DmConversation>> _fetchPage(String orgId, int page) async {
    final repository = ref.read(dmRepositoryProvider);
    final results = await repository.getConversations(orgId: orgId, page: page);
    if (results.length < DmRepository.pageSize) {
      _hasMore = false;
    }

    if (results.isEmpty && page == 1) {
      return [
        DmConversation(
          channelId: 'mock-channel-id-123',
          username: 'Test User',
          participantId: 'mock-user-id',
          previewMessage:
              'This is a test conversation. Tap to test the composer.',
          unreadCount: 0,
        ),
      ];
    }

    return results;
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId.isEmpty) return;

    final current = state.value ?? [];
    _currentPage++;
    final next = await _fetchPage(orgId, _currentPage);
    state = AsyncValue.data(_clearActiveUnread([...current, ...next]));
  }

  Future<void> refresh() async {
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId.isEmpty) return;

    _currentPage = 1;
    _hasMore = true;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () async => _clearActiveUnread(await _fetchPage(orgId, 1)),
    );
  }
}
