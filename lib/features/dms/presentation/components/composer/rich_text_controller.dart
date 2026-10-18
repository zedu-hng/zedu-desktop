import 'package:zedu/core/core.dart';

import 'composer.dart';

class RichTextController extends TextEditingController {
  RichTextController({super.text});

  /// Both the editable preview and message bubbles use the same delimiter rules.
  static TextSpan formattedText(
    String text,
    TextStyle defaultStyle, {
    bool keepMarkers = false,
  }) {
    final spans = <TextSpan>[];
    for (final run in parseInlineFormatting(text)) {
      if (run.isMarker) {
        if (keepMarkers) {
          spans.add(
            TextSpan(
              text: text.substring(run.start, run.end),
              style: defaultStyle.copyWith(
                color: Colors.transparent,
                fontSize: 0.01,
              ),
            ),
          );
        }
        continue;
      }
      var style = defaultStyle;
      if (run.formats.contains(InlineFormat.bold)) {
        style = style.copyWith(fontWeight: FontWeight.bold);
      }
      if (run.formats.contains(InlineFormat.italic)) {
        style = style.copyWith(fontStyle: FontStyle.italic);
      }
      if (run.formats.contains(InlineFormat.strikethrough)) {
        style = style.copyWith(decoration: TextDecoration.lineThrough);
      }
      if (run.formats.contains(InlineFormat.code)) {
        style = style.copyWith(
          fontFamily: 'monospace',
          backgroundColor: const Color(0x1A6458F5),
          color: const Color(0xFF6458F5),
        );
      }
      spans.add(
        TextSpan(text: text.substring(run.start, run.end), style: style),
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
