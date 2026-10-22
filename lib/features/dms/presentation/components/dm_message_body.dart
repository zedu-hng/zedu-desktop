import 'package:zedu/core/core.dart';

class DmMessageBody extends StatelessWidget {
  const DmMessageBody({
    super.key,
    required this.content,
    required this.textStyle,
    required this.accentColor,
  });

  final String content;
  final TextStyle textStyle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(style: textStyle, children: _inlineSpans(content, textStyle)),
    );
  }

  // Chat messages use inline composer delimiters. Block Markdown would reinterpret
  // ordinary hashtags, numbered text and line breaks.
  static final _inline = RegExp(
    r'`([^`]+)`|\*\*(.+?)\*\*|~~(.+?)~~|(?<!\*)\*([^*]+)\*(?!\*)',
    dotAll: true,
  );

  List<TextSpan> _inlineSpans(String value, TextStyle style) {
    final spans = <TextSpan>[];
    var offset = 0;
    for (final match in _inline.allMatches(value)) {
      if (match.start > offset) {
        spans.add(
          TextSpan(text: value.substring(offset, match.start), style: style),
        );
      }
      if (match.group(1) case final String code) {
        spans.add(
          TextSpan(
            text: code,
            style: style.copyWith(
              fontSize: 13,
              fontFamily: 'monospace',
              backgroundColor: accentColor.withValues(alpha: 0.1),
              color: accentColor,
            ),
          ),
        );
      } else {
        final bold = match.group(2);
        final strike = match.group(3);
        final inner = bold ?? strike ?? match.group(4)!;
        final inlineStyle = bold != null
            ? style.copyWith(fontWeight: FontWeight.bold)
            : strike != null
            ? style.copyWith(decoration: TextDecoration.lineThrough)
            : style.copyWith(fontStyle: FontStyle.italic);
        spans.add(
          TextSpan(
            style: inlineStyle,
            children: _inlineSpans(inner, inlineStyle),
          ),
        );
      }
      offset = match.end;
    }
    if (offset < value.length) {
      spans.add(TextSpan(text: value.substring(offset), style: style));
    }
    return spans;
  }
}
