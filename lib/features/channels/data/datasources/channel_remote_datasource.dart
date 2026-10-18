import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

abstract class ChannelRemoteDataSource {
  Future<List<Channel>> fetchChannels(String orgId);
  Future<Channel> createChannel({
    required String name,
    required String description,
    required String orgId,
    required String username,
    required bool isPrivate,
    String? topic,
  });
  Future<void> updateChannelTopicOrDescription({
    required String channelId,
    String? topic,
    String? description,
  });
  Future<void> archiveChannel(String channelId, bool archived);
}

class ChannelRemoteDataSourceImpl implements ChannelRemoteDataSource {
  final ApiBaseService apiBaseService;

  ChannelRemoteDataSourceImpl({required this.apiBaseService});

  @override
  Future<List<Channel>> fetchChannels(String orgId) async {
    final response = await apiBaseService.get<Map<String, dynamic>>(
      path: '/organisations/$orgId/channels',
    );
    final data = response.data['data'] as List?;
    if (data == null) return [];
    return data
        .map((e) => Channel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Channel> createChannel({
    required String name,
    required String description,
    required String orgId,
    required String username,
    required bool isPrivate,
    String? topic,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'description': description,
      'organisation_id': orgId,
      'username': username,
      'is_private': isPrivate,
      if (topic != null && topic.isNotEmpty) 'topic': topic,
    };
    final response = await apiBaseService.post<Map<String, dynamic>>(
      path: '/channels',
      data: body,
    );
    final data = response.data['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('No data returned from create channel');
    return Channel.fromJson(data);
  }

  @override
  Future<void> updateChannelTopicOrDescription({
    required String channelId,
    String? topic,
    String? description,
  }) async {
    final data = <String, dynamic>{};
    if (topic != null) data['topic'] = topic;
    if (description != null) data['description'] = description;

    await apiBaseService.put<Map<String, dynamic>>(
      path: '/channels/$channelId/',
      data: data,
    );
  }

  @override
  Future<void> archiveChannel(String channelId, bool archived) async {
    await apiBaseService.put<Map<String, dynamic>>(
      path: '/channels/$channelId/archive',
      data: {'archived': archived},
    );
  }
}
