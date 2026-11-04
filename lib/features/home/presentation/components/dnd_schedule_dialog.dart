import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class DndScheduleDialog extends ConsumerStatefulWidget {
  const DndScheduleDialog({super.key});

  @override
  ConsumerState<DndScheduleDialog> createState() => _DndScheduleDialogState();
}

class _DndScheduleDialogState extends ConsumerState<DndScheduleDialog> {
  late bool _enabled;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late bool _duringCalls;

  @override
  void initState() {
    super.initState();
    final schedule = ref.read(notificationSettingsProvider).schedule;
    _enabled = schedule.enabled;
    _start = schedule.start;
    _end = schedule.end;
    _duringCalls = schedule.duringCalls;
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await ref
        .read(notificationSettingsProvider.notifier)
        .setSchedule(
          DndSchedule(
            enabled: _enabled,
            start: _start,
            end: _end,
            duringCalls: _duringCalls,
          ),
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _enabled
                ? 'Do Not Disturb is scheduled for ${DndSchedule.formatTime(_start)} – ${DndSchedule.formatTime(_end)}.'
                : 'The Do Not Disturb schedule is off.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Schedule Do Not Disturb',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textHint, size: 20),
                    splashRadius: 18,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pause notifications automatically',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: _enabled,
                    activeThumbColor: colors.primary,
                    onChanged: (value) => setState(() => _enabled = value),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'From',
                      time: _start,
                      enabled: _enabled,
                      onTap: () => _pickTime(start: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeField(
                      label: 'To',
                      time: _end,
                      enabled: _enabled,
                      onTap: () => _pickTime(start: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'A window can cross midnight, for example 22:00 to 08:00. '
                'Notifications resume by themselves when the window ends.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textHint,
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _duringCalls,
                onChanged: (value) =>
                    setState(() => _duringCalls = value ?? false),
                activeColor: colors.primary,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'Also pause while I am in a call',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Applies while a Zedu call is active.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textHint,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.borderOutline),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.time,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: colors.borderOutline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textHint,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DndSchedule.formatTime(time),
              style: context.textTheme.bodyMedium?.copyWith(
                color: enabled ? colors.textPrimary : colors.textHint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
