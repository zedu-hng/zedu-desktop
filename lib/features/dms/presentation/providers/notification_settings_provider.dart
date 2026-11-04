import 'dart:async';
import 'dart:convert';

import 'package:zedu/core/core.dart';

import 'active_call_provider.dart';

/// A repeating window in which desktop notifications and sounds stay paused.
class DndSchedule {
  const DndSchedule({
    this.enabled = false,
    this.start = const TimeOfDay(hour: 22, minute: 0),
    this.end = const TimeOfDay(hour: 8, minute: 0),
    this.duringCalls = false,
  });

  final bool enabled;
  final TimeOfDay start;
  final TimeOfDay end;

  /// Also pause while the user is in an active Zedu call.
  final bool duringCalls;

  bool contains(DateTime now) {
    if (!enabled) return false;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final minutes = now.hour * 60 + now.minute;
    if (startMinutes == endMinutes) return true;
    if (startMinutes < endMinutes) {
      return minutes >= startMinutes && minutes < endMinutes;
    }
    return minutes >= startMinutes || minutes < endMinutes;
  }

  DndSchedule copyWith({
    bool? enabled,
    TimeOfDay? start,
    TimeOfDay? end,
    bool? duringCalls,
  }) {
    return DndSchedule(
      enabled: enabled ?? this.enabled,
      start: start ?? this.start,
      end: end ?? this.end,
      duringCalls: duringCalls ?? this.duringCalls,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'start': {'hour': start.hour, 'minute': start.minute},
    'end': {'hour': end.hour, 'minute': end.minute},
    'duringCalls': duringCalls,
  };

  String encode() => jsonEncode(toJson());

  static DndSchedule? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      TimeOfDay? timeFrom(Object? value) {
        if (value is! Map<String, dynamic>) return null;
        final hour = value['hour'];
        final minute = value['minute'];
        if (hour is! int || minute is! int) return null;
        if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
        return TimeOfDay(hour: hour, minute: minute);
      }

      final start = timeFrom(decoded['start']);
      final end = timeFrom(decoded['end']);
      if (start == null || end == null) return null;

      return DndSchedule(
        enabled: decoded['enabled'] == true,
        start: start,
        end: end,
        duringCalls: decoded['duringCalls'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  static String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get label => '${formatTime(start)} – ${formatTime(end)}';
}

class NotificationSettings {
  final DateTime? dndUntil;
  final Set<String> mutedParticipantIds;
  final DndSchedule schedule;

  const NotificationSettings({
    this.dndUntil,
    this.mutedParticipantIds = const {},
    this.schedule = const DndSchedule(),
  });

  /// Whether notifications are paused at [now], from either the manual pause
  /// or the scheduled window.
  bool isPausedAt(DateTime now) {
    final manual = dndUntil != null && dndUntil!.isAfter(now);
    return manual || schedule.contains(now);
  }

  bool get isDndActive => isPausedAt(DateTime.now());
  bool isMuted(String participantId) =>
      mutedParticipantIds.contains(participantId);

  NotificationSettings copyWith({
    DateTime? dndUntil,
    Set<String>? mutedParticipantIds,
    DndSchedule? schedule,
  }) {
    return NotificationSettings(
      dndUntil: dndUntil ?? this.dndUntil,
      mutedParticipantIds: mutedParticipantIds ?? this.mutedParticipantIds,
      schedule: schedule ?? this.schedule,
    );
  }
}

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  static const String scheduleStorageKey = 'desktop_dnd_schedule';

  Timer? _dndExpiry;
  Timer? _scheduleTick;

  @override
  NotificationSettings build() {
    ref.onDispose(() {
      _dndExpiry?.cancel();
      _scheduleTick?.cancel();
    });
    unawaited(_loadSchedule());
    return const NotificationSettings();
  }

  Future<void> _loadSchedule() async {
    if (!locator.isRegistered<SecureStorageService>()) return;
    try {
      final raw = await locator<SecureStorageService>().readData(
        scheduleStorageKey,
      );
      final schedule = DndSchedule.tryParse(raw);
      if (schedule == null) return;
      state = NotificationSettings(
        dndUntil: state.dndUntil,
        mutedParticipantIds: state.mutedParticipantIds,
        schedule: schedule,
      );
      _scheduleBoundaryRefresh();
    } catch (error, stackTrace) {
      AppLogger.w(
        'Could not load the Do Not Disturb schedule',
        tag: 'NotificationSettings',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// True when a manual pause, the schedule, or an active call should stop
  /// notifications from being delivered.
  bool get notificationsPaused {
    final inCall =
        state.schedule.duringCalls &&
        ref.read(activeCallProvider).state.status == CallStatus.active;
    return state.isDndActive || inCall;
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
      schedule: state.schedule,
    );
  }

  Future<void> setSchedule(DndSchedule schedule) async {
    state = NotificationSettings(
      dndUntil: state.dndUntil,
      mutedParticipantIds: state.mutedParticipantIds,
      schedule: schedule,
    );
    _scheduleBoundaryRefresh();
    if (!locator.isRegistered<SecureStorageService>()) return;
    try {
      await locator<SecureStorageService>().writeData(
        scheduleStorageKey,
        schedule.encode(),
      );
    } catch (error, stackTrace) {
      AppLogger.w(
        'Could not save the Do Not Disturb schedule',
        tag: 'NotificationSettings',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Rebuilds listeners when the window starts or ends so the UI reflects the
  /// current state without polling.
  void _scheduleBoundaryRefresh() {
    _scheduleTick?.cancel();
    final untilBoundary = _untilNextBoundary(DateTime.now());
    if (untilBoundary == null) return;
    _scheduleTick = Timer(untilBoundary, () {
      state = NotificationSettings(
        dndUntil: state.dndUntil,
        mutedParticipantIds: state.mutedParticipantIds,
        schedule: state.schedule,
      );
      _scheduleBoundaryRefresh();
    });
  }

  Duration? _untilNextBoundary(DateTime now) {
    final current = state.schedule;
    if (!current.enabled) return null;

    DateTime at(TimeOfDay time, {int dayOffset = 0}) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: dayOffset));
      return DateTime(day.year, day.month, day.day, time.hour, time.minute);
    }

    final candidates = [
      for (final offset in [0, 1, 2])
        for (final time in [current.start, current.end])
          at(time, dayOffset: offset),
    ].where((candidate) => candidate.isAfter(now)).toList()..sort();

    if (candidates.isEmpty) return null;
    final wait = candidates.first.difference(now);
    return wait.isNegative || wait < const Duration(seconds: 1)
        ? const Duration(seconds: 1)
        : wait;
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
