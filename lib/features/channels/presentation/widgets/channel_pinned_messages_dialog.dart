import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Lists the messages pinned in [channel] (Ziki #17).
class ChannelPinnedMessagesDialog extends ConsumerWidget {
  final Channel channel;

  const ChannelPinnedMessagesDialog({super.key, required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final pinned = ref.watch(pinnedMessagesProvider(channel.id));

    return AlertDialog(
      title: Text('#${channel.name} pinned messages'),
      content: SizedBox(
        width: 420,
        child: pinned.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Couldn't load the pinned messages.",
                  style: TextStyle(color: colors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(pinnedMessagesProvider(channel.id)),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
          data: (messages) => messages.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No pinned messages yet',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: messages.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _PinnedMessageTile(message: messages[index]),
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _PinnedMessageTile extends StatelessWidget {
  final PinnedMessage message;

  const _PinnedMessageTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final localizations = MaterialLocalizations.of(context);
    final createdAt = message.createdAt;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  message.senderName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (createdAt != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${localizations.formatShortDate(createdAt)} '
                  '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(createdAt))}',
                  style: TextStyle(fontSize: 12, color: colors.textHint),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(message.text, style: TextStyle(color: colors.textPrimary)),
        ],
      ),
    );
  }
}
