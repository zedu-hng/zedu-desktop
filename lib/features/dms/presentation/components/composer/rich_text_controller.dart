import 'package:zedu/core/core.dart';

class RichTextController extends TextEditingController {
  RichTextController({super.text});

  // Pair before rendering: a closing star run can finish several nested styles.
  static Iterable<({int start, int end, int length, String marker})> _pairs(
    String text,
    bool pairEmptyMarkers,
  ) sync* {
    final openings = <({int start, int length, String marker})>[];
    final pairs = <({int start, int end, int length, String marker})>[];
    void pair(int start, int end, int length, String marker) => pairs.add((
      start: start,
      end: end + length,
      length: length,
      marker: marker,
    ));
    final whitespace = RegExp(r'\s');
    for (final token in RegExp(r'`[^`]*`|\*+|~~').allMatches(text)) {
      final marker = text[token.start];
      if (marker == '`') {
        pair(token.start, token.end - 1, 1, marker);
        continue;
      }
      final canOpen =
          token.end < text.length && !whitespace.hasMatch(text[token.end]);
      final canClose =
          token.start > 0 && !whitespace.hasMatch(text[token.start - 1]);
      var position = token.start;
      var remaining = token.end - token.start;
      while (canClose && remaining > 0 && openings.isNotEmpty) {
        final opening = openings.last;
        if (opening.marker != marker) break;
        final length = opening.length < remaining ? opening.length : remaining;
        openings.removeLast();
        pair(opening.start + opening.length - length, position, length, marker);
        if (length < opening.length) {
          openings.add((
            start: opening.start,
            length: opening.length - length,
            marker: marker,
          ));
        }
        position += length;
        remaining -= length;
      }
      if (canOpen && remaining > 0) {
        openings.add((start: position, length: remaining, marker: marker));
      } else if (pairEmptyMarkers && remaining >= 4 && remaining.isEven) {
        pair(position, position + remaining ~/ 2, remaining ~/ 2, marker);
      }
    }
    pairs.sort((a, b) => a.start.compareTo(b.start));
    var end = 0;
    for (final pair in pairs) {
      if (pair.start < end) continue;
      yield pair;
      end = pair.end;
    }
  }

  /// Shared rendering keeps raw marker offsets only in the editable composer.
  static TextSpan formattedText(
    String textStr,
    TextStyle defaultStyle, {
    bool keepMarkers = false,
  }) {
    if (textStr.isEmpty) return TextSpan(style: defaultStyle, text: '');

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in _pairs(textStr, keepMarkers)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: textStr.substring(lastEnd, match.start),
            style: defaultStyle,
          ),
        );
      }

      final marker = match.marker * match.length;

      final inner = textStr.substring(
        match.start + match.length,
        match.end - match.length,
      );
      final nested = match.marker == '`'
          ? null
          : formattedText(
              inner,
              const TextStyle(),
              keepMarkers: keepMarkers,
            ).children;
      if (match.marker == '*' && match.length >= 2) {
        spans.add(
          TextSpan(
            children: [
              TextSpan(
                text: keepMarkers ? marker : '',
                style: defaultStyle.copyWith(
                  color: Colors.transparent,
                  fontSize: 0.01,
                ),
              ),
              TextSpan(
                children: nested,
                style: defaultStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontStyle: match.length.isOdd ? FontStyle.italic : null,
                ),
              ),
              TextSpan(
                text: keepMarkers ? marker : '',
                style: defaultStyle.copyWith(
                  color: Colors.transparent,
                  fontSize: 0.01,
                ),
              ),
            ],
          ),
        );
      } else if (match.marker == '~') {
        spans.add(
          TextSpan(
            children: [
              TextSpan(
                text: keepMarkers ? marker : '',
                style: defaultStyle.copyWith(
                  color: Colors.transparent,
                  fontSize: 0.01,
                ),
              ),
              TextSpan(
                children: nested,
                style: defaultStyle.copyWith(
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              TextSpan(
                text: keepMarkers ? marker : '',
                style: defaultStyle.copyWith(
                  color: Colors.transparent,
                  fontSize: 0.01,
                ),
              ),
            ],
          ),
        );
      } else if (match.marker == '`') {
        spans.add(
          TextSpan(
            children: [
              TextSpan(
                text: keepMarkers ? marker : '',
                style: defaultStyle.copyWith(
                  color: Colors.transparent,
                  fontSize: 0.01,
                ),
              ),
              TextSpan(
                text: inner,
                style: defaultStyle.copyWith(
                  fontFamily: 'monospace',
                  backgroundColor: const Color(0x1A6458F5),
                  color: const Color(0xFF6458F5),
                ),
              ),
              TextSpan(
                text: keepMarkers ? marker : '',
                style: defaultStyle.copyWith(
                  color: Colors.transparent,
                  fontSize: 0.01,
                ),
              ),
            ],
          ),
        );
      } else {
        spans.add(
          TextSpan(
            children: [
              TextSpan(
                text: keepMarkers ? marker : '',
                style: defaultStyle.copyWith(
                  color: Colors.transparent,
                  fontSize: 0.01,
                ),
              ),
              TextSpan(
                children: nested,
                style: defaultStyle.copyWith(fontStyle: FontStyle.italic),
              ),
              TextSpan(
                text: keepMarkers ? marker : '',
                style: defaultStyle.copyWith(
                  color: Colors.transparent,
                  fontSize: 0.01,
                ),
              ),
            ],
          ),
        );
      }

      lastEnd = match.end;
    }

    if (lastEnd < textStr.length) {
      spans.add(
        TextSpan(text: textStr.substring(lastEnd), style: defaultStyle),
      );
    }

    return TextSpan(style: defaultStyle, children: spans);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) => formattedText(text, style ?? const TextStyle(), keepMarkers: true);
}
