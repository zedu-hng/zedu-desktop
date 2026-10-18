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
    return MarkdownBody(
      data: content,
      styleSheet: MarkdownStyleSheet(
        p: textStyle,
        strong: textStyle.copyWith(fontWeight: FontWeight.bold),
        em: textStyle.copyWith(fontStyle: FontStyle.italic),
        del: textStyle.copyWith(decoration: TextDecoration.lineThrough),
        code: textStyle.copyWith(
          fontSize: 13,
          fontFamily: 'monospace',
          backgroundColor: accentColor.withValues(alpha: 0.1),
          color: accentColor,
        ),
      ),
    );
  }
}
