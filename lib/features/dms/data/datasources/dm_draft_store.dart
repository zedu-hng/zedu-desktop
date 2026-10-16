import 'dart:convert';

import 'package:zedu/core/core.dart';

/// Client-side persistence for unsent message drafts, keyed by conversation id.
///
/// Mirrors the mobile app's draft keys (`user:org:scope:roomId`) closely enough
/// to be familiar, but is desktop-local storage only. Uses the app's existing
/// FlutterSecureStorage via SecureStorageService, following the same JSON
/// encoding pattern as ChatStorageService.
class DraftEntry {
  final String text;
  final int updatedAt;

  const DraftEntry({required this.text, required this.updatedAt});

  Map<String, dynamic> toJson() => {'text': text, 'updatedAt': updatedAt};

  factory DraftEntry.fromJson(Map<String, dynamic> json) => DraftEntry(
    text: json['text'] as String? ?? '',
    updatedAt: json['updatedAt'] as int? ?? 0,
  );
}

class DmDraftStore extends ChangeNotifier {
  static const _keyPrefix = 'dm_draft_';

  final SecureStorageService _storage;

  /// In-memory cache keyed by channel id so list tiles rebuild instantly.
  /// A null value means "known empty" (loaded from disk, nothing there, or
  /// cleared by the composer).
  final Map<String, DraftEntry?> _cache = {};

  /// Channel ids already read from storage at least once.
  final Set<String> _loaded = {};

  DmDraftStore(this._storage);

  /// Cached entry without triggering any IO. Null means "no draft" — either
  /// known-absent or not-yet-loaded (check [hasLoaded]).
  DraftEntry? peek(String channelId) => _cache[channelId];

  /// True when this conversation's storage has been read at least once.
  bool hasLoaded(String channelId) => _loaded.contains(channelId);

  Future<DraftEntry?> load(String channelId) async {
    _loaded.add(channelId);
    if (_cache.containsKey(channelId)) return _cache[channelId];

    final raw = await _storage.readData('$_keyPrefix$channelId');
    DraftEntry? entry;
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final parsed = DraftEntry.fromJson(decoded);
          // Whitespace-only drafts are not drafts (same rule as mobile).
          if (parsed.text.trim().isNotEmpty) entry = parsed;
        }
      } catch (_) {
        entry = null;
      }
    }
    _cache[channelId] = entry;
    notifyListeners();
    return entry;
  }

  Future<void> save(String channelId, String text, {int? updatedAt}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      await clear(channelId);
      return;
    }

    final entry = DraftEntry(
      text: text,
      updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
    );
    _cache[channelId] = entry;
    notifyListeners();
    try {
      await _storage.writeData(
        '$_keyPrefix$channelId',
        jsonEncode(entry.toJson()),
      );
    } catch (_) {
      // Storage failure should not break composing; cache stays valid.
    }
  }

  Future<void> clear(String channelId) async {
    _cache[channelId] = null;
    notifyListeners();
    try {
      await _storage.deleteValue('$_keyPrefix$channelId');
    } catch (_) {}
  }
}

final dmDraftStoreProvider = ChangeNotifierProvider<DmDraftStore>((ref) {
  return DmDraftStore(locator<SecureStorageService>());
});
