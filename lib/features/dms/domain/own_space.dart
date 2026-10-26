import 'package:zedu/features/features.dart';

/// Your own space is the direct message you have with yourself.
extension OwnSpace on DmConversation {
  /// Whether this conversation is the signed-in user's own space.
  ///
  /// The DM list names the other person in `participant_id`, which is you in
  /// your own space. When that field is missing, a conversation whose
  /// participants are all you counts too.
  bool isOwnSpaceOf(String? userId) {
    if (userId == null || userId.isEmpty) return false;
    if (participantId.isNotEmpty) return participantId == userId;
    return participants.isNotEmpty &&
        participants.every((p) => p.userId == userId);
  }
}

/// Returns [conversations] with the signed-in user's own space first.
///
/// Every other conversation keeps its order. When there is no own space, the
/// list comes back unchanged.
List<DmConversation> ownSpaceFirst(
  List<DmConversation> conversations,
  String? userId,
) {
  final index = conversations.indexWhere((c) => c.isOwnSpaceOf(userId));
  if (index <= 0) return conversations;
  return [
    conversations[index],
    ...conversations.take(index),
    ...conversations.skip(index + 1),
  ];
}
