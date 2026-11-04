import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('DndSchedule', () {
    test('matches times inside a same-day window', () {
      const schedule = DndSchedule(
        enabled: true,
        start: TimeOfDay(hour: 9, minute: 0),
        end: TimeOfDay(hour: 17, minute: 0),
      );

      expect(schedule.contains(DateTime(2026, 11, 4, 8, 59)), isFalse);
      expect(schedule.contains(DateTime(2026, 11, 4, 9, 0)), isTrue);
      expect(schedule.contains(DateTime(2026, 11, 4, 12, 30)), isTrue);
      expect(schedule.contains(DateTime(2026, 11, 4, 17, 0)), isFalse);
    });

    test('matches times across midnight', () {
      const schedule = DndSchedule(
        enabled: true,
        start: TimeOfDay(hour: 22, minute: 0),
        end: TimeOfDay(hour: 8, minute: 0),
      );

      expect(schedule.contains(DateTime(2026, 11, 4, 21, 59)), isFalse);
      expect(schedule.contains(DateTime(2026, 11, 4, 22, 0)), isTrue);
      expect(schedule.contains(DateTime(2026, 11, 5, 2, 0)), isTrue);
      expect(schedule.contains(DateTime(2026, 11, 5, 8, 0)), isFalse);
      expect(schedule.contains(DateTime(2026, 11, 5, 12, 0)), isFalse);
    });

    test('does nothing while disabled', () {
      const schedule = DndSchedule(
        enabled: false,
        start: TimeOfDay(hour: 0, minute: 0),
        end: TimeOfDay(hour: 23, minute: 59),
      );

      expect(schedule.contains(DateTime(2026, 11, 4, 12, 0)), isFalse);
    });

    test('treats equal start and end as a full day', () {
      const schedule = DndSchedule(
        enabled: true,
        start: TimeOfDay(hour: 10, minute: 0),
        end: TimeOfDay(hour: 10, minute: 0),
      );

      expect(schedule.contains(DateTime(2026, 11, 4, 3, 0)), isTrue);
      expect(schedule.contains(DateTime(2026, 11, 4, 23, 0)), isTrue);
    });

    test('round-trips through storage', () {
      const schedule = DndSchedule(
        enabled: true,
        start: TimeOfDay(hour: 22, minute: 15),
        end: TimeOfDay(hour: 7, minute: 45),
        duringCalls: true,
      );

      final parsed = DndSchedule.tryParse(schedule.encode());

      expect(parsed, isNotNull);
      expect(parsed!.enabled, isTrue);
      expect(parsed.start, const TimeOfDay(hour: 22, minute: 15));
      expect(parsed.end, const TimeOfDay(hour: 7, minute: 45));
      expect(parsed.duringCalls, isTrue);
    });

    test('rejects malformed schedules', () {
      expect(DndSchedule.tryParse(null), isNull);
      expect(DndSchedule.tryParse(''), isNull);
      expect(DndSchedule.tryParse('not json'), isNull);
      expect(DndSchedule.tryParse('{"enabled":true}'), isNull);
      expect(
        DndSchedule.tryParse(
          '{"start":{"hour":25,"minute":0},"end":{"hour":8,"minute":0}}',
        ),
        isNull,
      );
    });
  });

  group('NotificationSettings', () {
    const schedule = DndSchedule(
      enabled: true,
      start: TimeOfDay(hour: 22, minute: 0),
      end: TimeOfDay(hour: 8, minute: 0),
    );

    test('pauses inside the schedule and resumes afterwards', () {
      const settings = NotificationSettings(schedule: schedule);
      final during = DateTime(2026, 11, 4, 23, 30);
      final after = DateTime(2026, 11, 5, 9, 0);

      expect(settings.isPausedAt(during), isTrue);
      expect(settings.isPausedAt(after), isFalse);
    });

    test('still respects a manual pause outside the schedule', () {
      final settings = NotificationSettings(
        dndUntil: DateTime(2026, 11, 4, 14, 0),
        schedule: schedule,
      );

      expect(settings.isPausedAt(DateTime(2026, 11, 4, 13, 0)), isTrue);
      expect(settings.isPausedAt(DateTime(2026, 11, 4, 15, 0)), isFalse);
    });
  });
}
