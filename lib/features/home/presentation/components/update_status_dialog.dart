import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class UpdateStatusDialog extends StatefulWidget {
  const UpdateStatusDialog({super.key});

  @override
  State<UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends State<UpdateStatusDialog> {
  late TextEditingController _statusController;

  @override
  void initState() {
    super.initState();
    _statusController = TextEditingController();
  }

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.background,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update your status',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _statusController,
              decoration: InputDecoration(
                hintText: 'What\'s your status?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.divider),
                ),
                suffixIcon: Tooltip(
                  message: 'Add status emoji',
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () async {
                        final selectedEmoji = await showDialog<String>(
                          context: context,
                          builder: (context) => const EmojiPickerDialog(),
                        );
                        if (selectedEmoji != null && mounted) {
                          setState(() {
                            _statusController.text += selectedEmoji;
                          });
                        }
                      },
                      child: Icon(
                        Icons.emoji_emotions_outlined,
                        color: colors.accent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: colors.textPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
