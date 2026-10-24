import 'package:zedu/core/core.dart';

class NotificationSettings {
  final DateTime? dndUntil;
  final Set<String> mutedParticipantIds;

  const NotificationSettings({
    this.dndUntil,
    this.mutedParticipantIds = const {},
  });

  bool get isDndActive => dndUntil != null && dndUntil!.isAfter(DateTime.now());
  bool isMuted(String participantId) =>
      mutedParticipantIds.contains(participantId);

  NotificationSettings copyWith({
    DateTime? dndUntil,
    Set<String>? mutedParticipantIds,
  }) {
    return NotificationSettings(
      dndUntil: dndUntil ?? this.dndUntil,
      mutedParticipantIds: mutedParticipantIds ?? this.mutedParticipantIds,
    );
  }
}

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() {
    return const NotificationSettings();
  }

  void setDndMode() {
    state = state.copyWith(dndUntil: DateTime(2099, 1, 1));
  }

  void clearDndMode() {
    state = NotificationSettings(
      dndUntil: null,
      mutedParticipantIds: state.mutedParticipantIds,
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
