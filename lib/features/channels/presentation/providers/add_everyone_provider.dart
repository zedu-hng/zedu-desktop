import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Outcome of adding everyone in the organisation to #general.
sealed class AddEveryoneResult {
  const AddEveryoneResult();
}

class AddEveryoneAdded extends AddEveryoneResult {
  const AddEveryoneAdded(this.count);
  final int count;
}

class AddEveryoneNobodyToAdd extends AddEveryoneResult {
  const AddEveryoneNobodyToAdd();
}

class AddEveryoneFailed extends AddEveryoneResult {
  const AddEveryoneFailed(this.message);
  final String message;
}

const generalChannelName = 'general';

/// Organisation members who are not in the channel yet, without the current
/// user, duplicates or empty ids. Keeps the organisation list's order.
List<String> usersToAddToChannel({
  required List<String> organisationMemberIds,
  required List<String> channelMemberIds,
  String? currentUserId,
}) {
  final skip = {...channelMemberIds, ?currentUserId};
  final result = <String>[];
  for (final id in organisationMemberIds) {
    if (id.isEmpty || skip.contains(id)) continue;
    skip.add(id);
    result.add(id);
  }
  return result;
}

/// Adds every member of the selected organisation to its #general channel.
class AddEveryoneToGeneral {
  AddEveryoneToGeneral(this._ref);

  final Ref _ref;

  static const _genericError =
      'Could not add everyone to #general. Please try again.';

  Future<AddEveryoneResult> call() async {
    final orgId = _ref.read(workspaceProvider).selectedWorkspace?.id;
    if (orgId == null) {
      return const AddEveryoneFailed('No organisation is selected.');
    }
    final currentUserId = _ref.read(authNotifierProvider).user?.id;
    final repository = _ref.read(channelRepositoryProvider);

    final channelsResult = await repository.fetchChannels(orgId);
    if (channelsResult is Failure<List<Channel>>) {
      return _failed(channelsResult.error);
    }
    final channels = (channelsResult as Success<List<Channel>>).value;
    final general = channels
        .where((c) => !c.archived && c.name.toLowerCase() == generalChannelName)
        .firstOrNull;
    if (general == null) {
      return const AddEveryoneFailed(
        'Could not find #general in this organisation.',
      );
    }

    final orgMembersResult = await repository.fetchOrganisationMemberIds(orgId);
    if (orgMembersResult is Failure<List<String>>) {
      return _failed(orgMembersResult.error);
    }
    final channelMembersResult = await repository.fetchChannelMemberIds(
      general.id,
    );
    if (channelMembersResult is Failure<List<String>>) {
      return _failed(channelMembersResult.error);
    }

    final userIds = usersToAddToChannel(
      organisationMemberIds: (orgMembersResult as Success<List<String>>).value,
      channelMemberIds: (channelMembersResult as Success<List<String>>).value,
      currentUserId: currentUserId,
    );
    // The backend rejects an empty list, so say so instead of calling it.
    if (userIds.isEmpty) return const AddEveryoneNobodyToAdd();

    final addResult = await repository.addMembersToChannel(
      channelId: general.id,
      userIds: userIds,
    );
    if (addResult is Failure<void>) return _failed(addResult.error);
    return AddEveryoneAdded(userIds.length);
  }

  AddEveryoneFailed _failed(ApiFailure error) {
    final message = error.message.trim();
    return AddEveryoneFailed(message.isEmpty ? _genericError : message);
  }
}

final addEveryoneToGeneralProvider = Provider<AddEveryoneToGeneral>(
  AddEveryoneToGeneral.new,
);
