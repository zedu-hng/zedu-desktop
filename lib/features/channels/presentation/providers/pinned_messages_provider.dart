import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// The messages pinned in a channel (Ziki #17).
final pinnedMessagesProvider = FutureProvider.autoDispose
    .family<List<PinnedMessage>, String>(
      // A failure shows the dialog's Try again button, not a silent retry.
      retry: (_, _) => null,
      (ref, channelId) async {
        final result = await ref
            .watch(channelRepositoryProvider)
            .fetchPinnedMessages(channelId);
        return switch (result) {
          Success<List<PinnedMessage>>(:final value) => value,
          Failure<List<PinnedMessage>>(:final error) => throw error,
        };
      },
    );
