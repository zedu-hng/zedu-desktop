import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Lets the user pick the microphone, camera and speaker used by a Buzz call.
class CallDeviceSelector extends ConsumerStatefulWidget {
  const CallDeviceSelector({super.key});

  @override
  ConsumerState<CallDeviceSelector> createState() => _CallDeviceSelectorState();
}

class _CallDeviceSelectorState extends ConsumerState<CallDeviceSelector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(callDevicesProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final callDevices = ref.watch(callDevicesProvider).state;

    if (callDevices.isLoading && callDevices.devices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final notifier = ref.read(callDevicesProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final kind in CallDeviceKind.values) ...[
          Text(
            kind.label,
            style: TextStyle(fontSize: 12, color: colors.textHint),
          ),
          const SizedBox(height: 6),
          _DeviceDropdown(
            devices: callDevices.devices[kind] ?? [systemDefaultDevice(kind)],
            selected: notifier.selectedFor(kind),
            onChanged: (device) {
              notifier.select(kind, device);
            },
          ),
          const SizedBox(height: 14),
        ],
        if (callDevices.error != null)
          Text(
            'Some devices could not be listed. Close and reopen this dialog to try again.',
            style: TextStyle(fontSize: 12, color: colors.error),
          ),
      ],
    );
  }
}

class _DeviceDropdown extends StatelessWidget {
  const _DeviceDropdown({
    required this.devices,
    required this.selected,
    required this.onChanged,
  });

  final List<CallDevice> devices;
  final CallDevice selected;
  final ValueChanged<CallDevice> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = devices.contains(selected) ? selected : devices.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: colors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<CallDevice>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: colors.background,
        items: [
          for (final device in devices)
            DropdownMenuItem(
              value: device,
              child: Text(
                device.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: colors.textPrimary),
              ),
            ),
        ],
        onChanged: (device) {
          if (device != null) onChanged(device);
        },
      ),
    );
  }
}

/// Device picker shown before a call starts ([startCall]) or while it runs.
class CallDeviceSetupDialog extends StatelessWidget {
  const CallDeviceSetupDialog({super.key, this.startCall = false});

  final bool startCall;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                startCall ? 'Start call' : 'Call devices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose the microphone, camera and speaker this call should use.',
                style: TextStyle(fontSize: 12, color: colors.textHint),
              ),
              const SizedBox(height: 20),
              const CallDeviceSelector(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(startCall ? 'Cancel' : 'Close'),
                  ),
                  if (startCall) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Start call'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
