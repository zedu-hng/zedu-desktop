import 'dart:async';

import 'package:zedu/core/core.dart';

class NotificationSettings {
  final DateTime? dndUntil;
  final Set<String> mutedParticipantIds;
  final Set<String> mutedChannelIds;

  const NotificationSettings({
    this.dndUntil,
    this.mutedParticipantIds = const {},
    this.mutedChannelIds = const {},
  });

  bool get isDndActive => dndUntil != null && dndUntil!.isAfter(DateTime.now());
  bool isMuted(String participantId) =>
      mutedParticipantIds.contains(participantId);
  bool isChannelMuted(String channelId) => mutedChannelIds.contains(channelId);

  NotificationSettings copyWith({
    DateTime? dndUntil,
    Set<String>? mutedParticipantIds,
    Set<String>? mutedChannelIds,
  }) {
    return NotificationSettings(
      dndUntil: dndUntil ?? this.dndUntil,
      mutedParticipantIds: mutedParticipantIds ?? this.mutedParticipantIds,
      mutedChannelIds: mutedChannelIds ?? this.mutedChannelIds,
    );
  }
}

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  Timer? _dndExpiry;

  @override
  NotificationSettings build() {
    ref.onDispose(() => _dndExpiry?.cancel());
    return const NotificationSettings();
  }

  /// Pauses notifications; the pause ends by itself when it runs out.
  void setDndMode(Duration duration) {
    state = state.copyWith(dndUntil: DateTime.now().add(duration));
    _dndExpiry?.cancel();
    _dndExpiry = Timer(duration, clearDndMode);
  }

  void clearDndMode() {
    _dndExpiry?.cancel();
    _dndExpiry = null;
    state = NotificationSettings(
      dndUntil: null,
      mutedParticipantIds: state.mutedParticipantIds,
      mutedChannelIds: state.mutedChannelIds,
    );
  }

  void muteChannel(String channelId) {
    state = state.copyWith(
      mutedChannelIds: {...state.mutedChannelIds, channelId},
    );
  }

  void unmuteChannel(String channelId) {
    state = state.copyWith(
      mutedChannelIds: {...state.mutedChannelIds}..remove(channelId),
    );
  }

  void muteParticipant(String participantId) {
    final newMuted = Set<String>.from(state.mutedParticipantIds)
      ..add(participantId);
    state = state.copyWith(mutedParticipantIds: newMuted);
  }

  void unmuteParticipant(String participantId) {
    final newMuted = Set<String>.from(state.mutedParticipantIds)
      ..remove(participantId);
    state = state.copyWith(mutedParticipantIds: newMuted);
  }

  bool isMuted(String participantId) {
    return state.mutedParticipantIds.contains(participantId);
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
      NotificationSettingsNotifier.new,
    );
