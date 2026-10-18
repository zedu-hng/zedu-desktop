enum InlineFormat { bold, italic, strikethrough, code }

typedef InlineFormattingRun = ({
  int start,
  int end,
  bool isMarker,
  Set<InlineFormat> formats,
});

/// Pairs nested delimiters before producing runs, so unmatched markers stay text.
List<InlineFormattingRun> parseInlineFormatting(String text) {
  final openings = <({int start, int length, String marker})>[];
  final pairs = <({int start, int end, int length, String marker})>[];
  final whitespace = RegExp(r'\s');

  for (final token in RegExp(
    r'`[^`]*`|\*+|~~',
    dotAll: true,
  ).allMatches(text)) {
    final marker = text[token.start];
    if (marker == '`') {
      pairs.add((
        start: token.start,
        end: token.end - 1,
        length: 1,
        marker: marker,
      ));
      continue;
    }

    final canOpen =
        token.end < text.length && !whitespace.hasMatch(text[token.end]);
    final canClose =
        token.start > 0 && !whitespace.hasMatch(text[token.start - 1]);
    var position = token.start;
    var remaining = token.end - token.start;

    // A closing run may finish several styles, or only the inner part of ***.
    while (canClose && remaining > 0 && openings.isNotEmpty) {
      final opening = openings.last;
      if (opening.marker != marker) break;
      final length = opening.length < remaining ? opening.length : remaining;
      openings.removeLast();
      pairs.add((
        start: opening.start + opening.length - length,
        end: position,
        length: length,
        marker: marker,
      ));
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
    } else if (remaining >= 4 && remaining.isEven) {
      // Empty pairs inserted by a toolbar click at the end of a draft.
      pairs.add((
        start: position,
        end: position + remaining ~/ 2,
        length: remaining ~/ 2,
        marker: marker,
      ));
    }
  }

  final boundaries = <int>{0, text.length};
  for (final pair in pairs) {
    boundaries.addAll([
      pair.start,
      pair.start + pair.length,
      pair.end,
      pair.end + pair.length,
    ]);
  }
  final offsets = boundaries.toList()..sort();
  final runs = <InlineFormattingRun>[];
  for (var i = 0; i + 1 < offsets.length; i++) {
    final start = offsets[i];
    final end = offsets[i + 1];
    var isMarker = false;
    final formats = <InlineFormat>{};
    for (final pair in pairs) {
      if ((start >= pair.start && end <= pair.start + pair.length) ||
          (start >= pair.end && end <= pair.end + pair.length)) {
        isMarker = true;
      }
      if (start >= pair.start + pair.length && end <= pair.end) {
        if (pair.marker == '`') {
          formats.add(InlineFormat.code);
        } else if (pair.marker == '~') {
          formats.add(InlineFormat.strikethrough);
        } else {
          if (pair.length >= 2) formats.add(InlineFormat.bold);
          if (pair.length.isOdd) formats.add(InlineFormat.italic);
        }
      }
    }
    if (isMarker) formats.clear();
    if (runs.isNotEmpty &&
        runs.last.isMarker == isMarker &&
        runs.last.formats.length == formats.length &&
        runs.last.formats.containsAll(formats)) {
      final previous = runs.removeLast();
      runs.add((
        start: previous.start,
        end: end,
        isMarker: isMarker,
        formats: formats,
      ));
    } else {
      runs.add((start: start, end: end, isMarker: isMarker, formats: formats));
    }
  }
  return runs;
}
