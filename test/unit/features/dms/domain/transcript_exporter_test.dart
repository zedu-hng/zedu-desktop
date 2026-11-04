import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

Map<String, dynamic> _message({
  String? id,
  String? content,
  String? createdAt,
  String? senderName,
  String? userId,
  List<dynamic> media = const [],
}) {
  return {
    'id': id ?? 'id',
    'content': content ?? '',
    'created_at': createdAt,
    'sender_name': senderName,
    'user_id': userId,
    'media': media,
  };
}

void main() {
  group('oldestFirst', () {
    test('orders messages by creation time', () {
      final messages = [
        _message(id: 'c', createdAt: '2026-11-04T12:00:00'),
        _message(id: 'a', createdAt: '2026-11-04T10:00:00'),
        _message(id: 'b', createdAt: '2026-11-04T11:00:00'),
      ];

      final ordered = oldestFirst(messages);

      expect(ordered.map((message) => message['id']), ['a', 'b', 'c']);
    });

    test('keeps server order for messages without a timestamp', () {
      final messages = [
        _message(id: 'x'),
        _message(id: 'y'),
        _message(id: 'z', createdAt: '2026-11-04T10:00:00'),
      ];

      final ordered = oldestFirst(messages);

      expect(ordered.map((message) => message['id']), ['z', 'x', 'y']);
    });
  });

  group('renderTranscriptText', () {
    test('lists every message with its timestamp and author', () {
      final text = renderTranscriptText(
        conversationName: 'Ada Lovelace',
        messages: [
          _message(
            content: '<p>Morning!</p>',
            createdAt: '2026-11-04T09:05:00',
            senderName: 'Ada Lovelace',
          ),
          _message(
            content: 'Hi Ada',
            createdAt: '2026-11-04T09:06:00',
            userId: 'me',
          ),
        ],
        exportedAt: DateTime.utc(2026, 11, 4, 10),
        currentUserId: 'me',
        currentUserName: 'Joshua Akuma',
      );

      expect(text, contains('Conversation with Ada Lovelace'));
      expect(text, contains('[2026-11-04 09:05] Ada Lovelace: Morning!'));
      expect(text, contains('[2026-11-04 09:06] Joshua Akuma: Hi Ada'));
      expect(text.indexOf('Morning!'), lessThan(text.indexOf('Hi Ada')));
    });

    test('uses placeholders for attachments and empty history', () {
      final withAttachment = renderTranscriptText(
        conversationName: 'Ada',
        messages: [
          _message(
            createdAt: '2026-11-04T09:05:00',
            senderName: 'Ada',
            media: [
              {'url': 'file'},
            ],
          ),
        ],
        exportedAt: DateTime.utc(2026, 11, 4),
        currentUserId: 'me',
        currentUserName: 'Joshua',
      );
      expect(withAttachment, contains('Ada: [Attachment]'));

      final empty = renderTranscriptText(
        conversationName: 'Ada',
        messages: const [],
        exportedAt: DateTime.utc(2026, 11, 4),
        currentUserId: 'me',
        currentUserName: 'Joshua',
      );
      expect(empty, contains('No messages in this conversation.'));
    });
  });

  group('messageBody', () {
    test('strips html tags and decodes entities', () {
      expect(
        messageBody(_message(content: '<p>Fish &amp; chips<br/>today</p>')),
        'Fish & chips\ntoday',
      );
    });
  });

  group('renderTranscriptPdf', () {
    test('produces a readable PDF document', () {
      final bytes = renderTranscriptPdf(
        conversationName: 'Ada',
        messages: [
          _message(
            content: 'Morning! 😀',
            createdAt: '2026-11-04T09:05:00',
            senderName: 'Ada',
          ),
          _message(
            content: 'Hi Ada',
            createdAt: '2026-11-04T09:06:00',
            userId: 'me',
          ),
        ],
        exportedAt: DateTime.utc(2026, 11, 4),
        currentUserId: 'me',
        currentUserName: 'Joshua',
      );

      final content = latin1.decode(bytes);
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(content, contains('Conversation with Ada'));
      expect(content, contains('Morning! ?'));
      expect(content, contains('Hi Ada'));
      expect(content.trimRight(), endsWith('%%EOF'));
    });

    test('paginates long conversations', () {
      final bytes = renderTranscriptPdf(
        conversationName: 'Long chat',
        messages: [
          for (var i = 0; i < 200; i++)
            _message(
              content: 'Message number $i',
              createdAt: '2026-11-04T09:00:00',
              senderName: 'Ada',
            ),
        ],
        exportedAt: DateTime.utc(2026, 11, 4),
        currentUserId: 'me',
        currentUserName: 'Joshua',
      );

      final content = latin1.decode(bytes);
      expect(
        RegExp(r'/Type /Page[^s]').allMatches(content).length,
        greaterThan(1),
      );
      expect(content, contains('Message number 199'));
    });
  });
}
