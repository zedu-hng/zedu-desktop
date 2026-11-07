import 'package:zedu/features/features.dart';

import '../../../../helpers/helpers.dart';

void main() {
  FilePreviewKind kind(String name, {String type = '', String mime = ''}) =>
      FilePreviewKind.of(
        WorkspaceFile(id: 'f', name: name, fileType: type, mimeType: mime),
      );

  test('tells which files can be previewed', () {
    expect(kind('a.png', type: 'png'), FilePreviewKind.image);
    expect(kind('a', mime: 'image/heic'), FilePreviewKind.image);
    expect(kind('a.svg', type: 'svg'), FilePreviewKind.svg);
    expect(kind('a', mime: 'image/svg+xml'), FilePreviewKind.svg);
    expect(kind('a.csv', type: 'csv'), FilePreviewKind.text);
    expect(kind('a', mime: 'text/plain'), FilePreviewKind.text);
    expect(kind('a', mime: 'application/json'), FilePreviewKind.text);
    expect(kind('a.pdf', type: 'pdf'), FilePreviewKind.none);
    expect(kind('a.docx', type: 'docx'), FilePreviewKind.none);
    expect(kind('a.mp4', type: 'mp4'), FilePreviewKind.none);
  });
}
