import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:zedu/core/core.dart';

import '../data/dm_repository.dart';

enum TranscriptFormat {
  text('Text (.txt)', 'txt'),
  pdf('PDF (.pdf)', 'pdf');

  const TranscriptFormat(this.label, this.extension);

  final String label;
  final String extension;
}

/// Builds and saves a conversation transcript with one line per message,
/// oldest first, showing the timestamp and the author.
class TranscriptExporter {
  TranscriptExporter(this._repository);

  final DmRepository _repository;

  Future<String?> export({
    required String channelId,
    required String conversationName,
    required TranscriptFormat format,
    required String currentUserId,
    required String currentUserName,
  }) async {
    final messages = oldestFirst(await _repository.getAllMessages(channelId));
    final exportedAt = DateTime.now();

    final bytes = switch (format) {
      TranscriptFormat.text => Uint8List.fromList(
        utf8.encode(
          renderTranscriptText(
            conversationName: conversationName,
            messages: messages,
            exportedAt: exportedAt,
            currentUserId: currentUserId,
            currentUserName: currentUserName,
          ),
        ),
      ),
      TranscriptFormat.pdf => renderTranscriptPdf(
        conversationName: conversationName,
        messages: messages,
        exportedAt: exportedAt,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
      ),
    };

    final fileName =
        'zedu-transcript-${_slug(conversationName)}-'
        '${_fileStamp(exportedAt)}.${format.extension}';
    final path = await FilePicker.saveFile(
      dialogTitle: 'Save transcript',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [format.extension],
      bytes: bytes,
    );
    if (path == null) return null;
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }
}

final transcriptExporterProvider = Provider<TranscriptExporter>((ref) {
  return TranscriptExporter(ref.read(dmRepositoryProvider));
});

/// Sorts [messages] by their creation time, keeping the server order for
/// messages without a timestamp.
List<Map<String, dynamic>> oldestFirst(List<Map<String, dynamic>> messages) {
  final indexed = messages.indexed.toList();
  indexed.sort((a, b) {
    final aTime = _createdAt(a.$2);
    final bTime = _createdAt(b.$2);
    if (aTime == null && bTime == null) return a.$1.compareTo(b.$1);
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    final byTime = aTime.compareTo(bTime);
    return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
  });
  return [for (final entry in indexed) entry.$2];
}

String renderTranscriptText({
  required String conversationName,
  required List<Map<String, dynamic>> messages,
  required DateTime exportedAt,
  required String currentUserId,
  required String currentUserName,
}) {
  final buffer = StringBuffer()
    ..writeln('Conversation with $conversationName')
    ..writeln('Exported ${_stamp(exportedAt.toLocal())}')
    ..writeln();

  if (messages.isEmpty) {
    buffer.writeln('No messages in this conversation.');
    return buffer.toString();
  }

  for (final message in messages) {
    final createdAt = _createdAt(message)?.toLocal();
    final time = createdAt == null ? 'unknown time' : _stamp(createdAt);
    final author = authorName(
      message,
      currentUserId: currentUserId,
      currentUserName: currentUserName,
    );
    buffer.writeln('[$time] $author: ${messageBody(message)}');
  }
  return buffer.toString();
}

/// Renders a paginated, dependency-free PDF using the standard Helvetica
/// fonts, which keeps the export working without shipping a font asset.
Uint8List renderTranscriptPdf({
  required String conversationName,
  required List<Map<String, dynamic>> messages,
  required DateTime exportedAt,
  required String currentUserId,
  required String currentUserName,
}) {
  const pageWidth = 595.0;
  const pageHeight = 842.0;
  const margin = 36.0;
  const usableWidth = pageWidth - margin * 2;

  final lines = <_PdfLine>[
    for (final line in _wrapLines(
      'Conversation with $conversationName',
      16,
      usableWidth,
    ))
      _PdfLine(line, 16, bold: true),
    for (final line in _wrapLines(
      'Exported ${_stamp(exportedAt.toLocal())}',
      9,
      usableWidth,
    ))
      _PdfLine(line, 9),
    const _PdfLine('', 6),
  ];

  if (messages.isEmpty) {
    lines.add(const _PdfLine('No messages in this conversation.', 10));
  } else {
    for (final message in messages) {
      final createdAt = _createdAt(message)?.toLocal();
      final author = authorName(
        message,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
      );
      final time = createdAt == null ? 'unknown time' : _stamp(createdAt);
      for (final line in _wrapLines('$author  ·  $time', 9, usableWidth)) {
        lines.add(_PdfLine(line, 9, bold: true));
      }
      for (final line in _wrapLines(messageBody(message), 10, usableWidth)) {
        lines.add(_PdfLine(line, 10));
      }
      lines.add(const _PdfLine('', 4));
    }
  }

  final pages = <List<_PlacedLine>>[];
  var placed = <_PlacedLine>[];
  var y = pageHeight - margin;
  for (final line in lines) {
    final leading = line.fontSize * 1.35;
    if (placed.isNotEmpty && y - leading < margin) {
      pages.add(placed);
      placed = <_PlacedLine>[];
      y = pageHeight - margin;
    }
    y -= leading;
    placed.add(_PlacedLine(line, y));
  }
  if (placed.isNotEmpty || pages.isEmpty) pages.add(placed);

  final objects = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids ['
        '${[for (var i = 0; i < pages.length; i++) '${5 + i * 2} 0 R'].join(' ')}'
        '] /Count ${pages.length} >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica '
        '/Encoding /WinAnsiEncoding >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold '
        '/Encoding /WinAnsiEncoding >>',
  ];

  for (var i = 0; i < pages.length; i++) {
    final contentObject = 6 + i * 2;
    final stream = StringBuffer();
    for (final line in pages[i]) {
      if (line.line.text.isEmpty) continue;
      final font = line.line.bold ? '/F2' : '/F1';
      stream
        ..writeln('BT')
        ..writeln('$font ${line.line.fontSize} Tf')
        ..writeln(
          '1 0 0 1 ${margin.toStringAsFixed(2)} '
          '${line.y.toStringAsFixed(2)} Tm',
        )
        ..writeln('${_pdfString(line.line.text)} Tj')
        ..writeln('ET');
    }
    final streamText = stream.toString();
    objects
      ..add(
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
        '/Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> '
        '/Contents $contentObject 0 R >>',
      )
      ..add(
        '<< /Length ${streamText.length} >>\n'
        'stream\n'
        '$streamText'
        'endstream',
      );
  }

  final buffer = BytesBuilder();
  buffer.add(latin1.encode('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n'));
  final offsets = <int>[];
  var offset = buffer.length;
  for (var i = 0; i < objects.length; i++) {
    final object = '${i + 1} 0 obj\n${objects[i]}\nendobj\n';
    offsets.add(offset);
    buffer.add(latin1.encode(object));
    offset += object.length;
  }

  final xref = StringBuffer('xref\n0 ${objects.length + 1}\n')
    ..writeln('0000000000 65535 f ');
  for (final objectOffset in offsets) {
    xref.writeln('${objectOffset.toString().padLeft(10, '0')} 00000 n ');
  }
  xref
    ..writeln('trailer')
    ..writeln('<< /Size ${objects.length + 1} /Root 1 0 R >>')
    ..writeln('startxref')
    ..writeln(offset)
    ..writeln('%%EOF');
  buffer.add(latin1.encode(xref.toString()));
  return buffer.takeBytes();
}

class _PdfLine {
  const _PdfLine(this.text, this.fontSize, {this.bold = false});

  final String text;
  final double fontSize;
  final bool bold;
}

class _PlacedLine {
  const _PlacedLine(this.line, this.y);

  final _PdfLine line;
  final double y;
}

/// Greedy word wrap based on the average glyph width of Helvetica, which is a
/// close enough approximation to avoid measuring every character.
List<String> _wrapLines(String text, double fontSize, double width) {
  final maxChars = (width / (fontSize * 0.52)).floor().clamp(8, 400).toInt();
  final result = <String>[];
  for (final paragraph in text.split('\n')) {
    final trimmed = paragraph.trimRight();
    if (trimmed.isEmpty) {
      result.add('');
      continue;
    }
    var remaining = trimmed;
    while (remaining.length > maxChars) {
      var cut = remaining.lastIndexOf(' ', maxChars);
      if (cut <= 0) cut = maxChars;
      result.add(remaining.substring(0, cut));
      remaining = remaining.substring(cut).trimLeft();
    }
    if (remaining.isNotEmpty) result.add(remaining);
  }
  return result.isEmpty ? [''] : result;
}

String _pdfString(String value) {
  final buffer = StringBuffer('(');
  for (final rune in value.runes) {
    final char = rune > 0xFF ? '?' : String.fromCharCode(rune);
    if (char == '\\') {
      buffer.write('\\\\');
    } else if (char == '(') {
      buffer.write('\\(');
    } else if (char == ')') {
      buffer.write('\\)');
    } else {
      buffer.write(char);
    }
  }
  buffer.write(')');
  return buffer.toString();
}

String authorName(
  Map<String, dynamic> message, {
  required String currentUserId,
  required String currentUserName,
}) {
  final name = (message['sender_name'] ?? message['username'] ?? '')
      .toString()
      .trim();
  if (name.isNotEmpty) return name;
  final senderId = (message['user_id'] ?? message['userId']).toString();
  if (senderId == currentUserId || senderId == 'me') return currentUserName;
  return 'Unknown';
}

String messageBody(Map<String, dynamic> message) {
  var content = (message['content'] ?? '').toString();
  content = content.replaceAll(
    RegExp(r'<br\s*/?>', caseSensitive: false),
    '\n',
  );
  content = content.replaceAll(RegExp(r'<[^>]+>'), '');
  content = content
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .trim();

  if (content.isNotEmpty) return content;
  final media = message['media'];
  if (media is List && media.isNotEmpty) return '[Attachment]';
  return '[Message]';
}

DateTime? _createdAt(Map<String, dynamic> message) {
  return DateTime.tryParse(message['created_at']?.toString() ?? '');
}

String _stamp(DateTime time) {
  final year = time.year.toString().padLeft(4, '0');
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}

String _fileStamp(DateTime time) =>
    _stamp(time).replaceAll('-', '').replaceAll(' ', '-').replaceAll(':', '');

String _slug(String value) {
  final slug = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'conversation' : slug;
}
