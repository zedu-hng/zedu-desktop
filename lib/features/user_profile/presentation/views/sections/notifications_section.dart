import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class NotificationsSection extends StatefulWidget {
  const NotificationsSection({
    super.key,
    required this.preferences,
    required this.isSaving,
    required this.onSave,
    required this.onRevert,
  });

  final NotificationPreferences preferences;
  final bool isSaving;
  final Future<void> Function(NotificationPreferences) onSave;
  final Future<void> Function(NotificationPreferences) onRevert;

  @override
  State<NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<NotificationsSection> {
  late NotificationPreferences _draft;
  late NotificationPreferences _original;

  @override
  void initState() {
    super.initState();
    _draft = widget.preferences;
    _original = widget.preferences;
  }

  @override
  void didUpdateWidget(covariant NotificationsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences != widget.preferences) {
      _draft = widget.preferences;
      _original = widget.preferences;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionHeader(
          title: 'Your Notification Preferences',
          subtitle: 'Manage when and why you get notified.',
        ),
        const SizedBox(height: 28),
        _Section(
          title: 'Send notifications for:',
          child: Column(
            children: [
              _RadioLine(
                label: 'All new messages',
                value: NotificationMode.allMessages,
                groupValue: _draft.mode,
                onChanged: (value) => _setDraft(_draft.copyWith(mode: value)),
              ),
              _RadioLine(
                label: 'Mentions',
                value: NotificationMode.mentionsOnly,
                groupValue: _draft.mode,
                onChanged: (value) => _setDraft(_draft.copyWith(mode: value)),
              ),
              _RadioLine(
                label: 'Nothing',
                value: NotificationMode.none,
                groupValue: _draft.mode,
                onChanged: (value) => _setDraft(_draft.copyWith(mode: value)),
              ),
            ],
          ),
        ),
        const Divider(height: 48, color: Color(0xFFF3F4F6)),
        _Section(
          title: 'Receive notifications only within:',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TimeSelect(
                    label: 'From',
                    value: _draft.fromTime,
                    onChanged: (value) =>
                        _setDraft(_draft.copyWith(fromTime: value)),
                  ),
                  const SizedBox(width: 14),
                  _TimeSelect(
                    label: 'To',
                    value: _draft.toTime,
                    onChanged: (value) =>
                        _setDraft(_draft.copyWith(toTime: value)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Note: Outside this time, notifications are paused.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 48, color: Color(0xFFF3F4F6)),
        _Section(
          title: 'To keep me informed:',
          child: Column(
            children: [
              _CheckboxLine(
                label: 'Use different settings for mobile devices',
                value: _draft.useDesktopSettings,
                onChanged: (value) =>
                    _setDraft(_draft.copyWith(useDesktopSettings: value)),
              ),
              _CheckboxLine(
                label: 'Receive notifications via email',
                value: _draft.emailNotifications,
                onChanged: (value) =>
                    _setDraft(_draft.copyWith(emailNotifications: value)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 56),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppButton.outlined(
              label: 'Revert changes',
              expand: false,
              height: 44,
              disabled: !_hasChanges,
              onPressed: () async {
                // revert to last saved and persist automatically
                setState(() => _draft = _original);
                await widget.onRevert(_original);
              },
            ),
            const SizedBox(width: 16),
            AppButton(
              label: 'Save changes',
              expand: false,
              height: 44,
              loading: widget.isSaving,
              disabled: !_hasChanges,
              onPressed: () async {
                await widget.onSave(_draft);
              },
            ),
          ],
        ),
      ],
    );
  }

  void _setDraft(NotificationPreferences preferences) {
    setState(() => _draft = preferences);
  }
}

bool _arePrefsEqual(NotificationPreferences a, NotificationPreferences b) {
  return a.mode == b.mode &&
      a.fromTime == b.fromTime &&
      a.toTime == b.toTime &&
      a.useDesktopSettings == b.useDesktopSettings &&
      a.emailNotifications == b.emailNotifications;
}

class _TimeSelect extends StatelessWidget {
  const _TimeSelect({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  List<String> _generateTimeOptions() {
    final list = <String>[];
    for (var h = 0; h < 24; h++) {
      for (var m = 0; m < 60; m += 30) {
        final tod = TimeOfDay(hour: h, minute: m);
        list.add(_formatTimeOfDay(tod));
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final timeOptions = _generateTimeOptions();
    if (!timeOptions.contains(value)) {
      timeOptions.add(value);
      timeOptions.sort((a, b) {
        final ta = _parseTimeOfDay(a) ?? const TimeOfDay(hour: 0, minute: 0);
        final tb = _parseTimeOfDay(b) ?? const TimeOfDay(hour: 0, minute: 0);
        final am = ta.hour * 60 + ta.minute;
        final bm = tb.hour * 60 + tb.minute;
        return am.compareTo(bm);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileFieldLabel(label),
        const SizedBox(height: 6),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String>(
            initialValue: value,
            // Let the selected time use the field's full width and ellipsize
            // rather than overflow its box.
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF6458F5)),
              ),
            ),
            dropdownColor: Colors.white,
            icon: const Icon(
              Icons.access_time,
              size: 16,
              color: Color(0xFF6B7280),
            ),
            style: context.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF111827),
            ),
            items: timeOptions.map((time) {
              return DropdownMenuItem<String>(
                value: time,
                child: Text(time, maxLines: 1, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          ),
        ),
      ],
    );
  }
}

TimeOfDay? _parseTimeOfDay(String s) {
  try {
    final parts = s.split(' ');
    if (parts.isEmpty) return null;
    final hm = parts[0].split(':');
    var hour = int.parse(hm[0]);
    final minute = int.parse(hm[1]);
    final period = parts.length > 1 ? parts[1].toUpperCase() : 'AM';
    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  } catch (_) {
    return null;
  }
}

String _formatTimeOfDay(TimeOfDay t) {
  final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final minute = t.minute.toString().padLeft(2, '0');
  final period = t.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

extension on _NotificationsSectionState {
  bool get _hasChanges => !_arePrefsEqual(_draft, _original);
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _RadioLine extends StatelessWidget {
  const _RadioLine({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final NotificationMode value;
  final NotificationMode groupValue;
  final ValueChanged<NotificationMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF6458F5)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF6458F5),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(label, style: context.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _CheckboxLine extends StatelessWidget {
  const _CheckboxLine({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: (v) => v != null ? onChanged(v) : null,
                activeColor: const Color(0xFF6458F5),
              ),
            ),
            const SizedBox(width: 10),
            Text(label, style: context.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
