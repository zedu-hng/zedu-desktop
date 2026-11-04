import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/utils/diagnostics.dart';
import 'package:zedu/core/utils/logger.dart';

void main() {
  group('buildDiagnosticsArchive', () {
    test('bundles app info and the recent log lines', () {
      final bytes = buildDiagnosticsArchive(
        appInfo: {
          'App version': '9.9.9',
          'Operating system': 'macos',
          'OS version': 'Version 27.0',
        },
        logs: [
          '2026-11-04T10:00:00.000Z [INFO] AppLogger: started',
          '2026-11-04T10:00:01.000Z [ERROR] Auth: boom',
        ],
      );

      final archive = ZipDecoder().decodeBytes(bytes);
      expect(archive.findFile('app-info.txt'), isNotNull);
      expect(archive.findFile('logs.txt'), isNotNull);

      final info = utf8.decode(
        archive.findFile('app-info.txt')!.content as List<int>,
      );
      expect(info, contains('App version: 9.9.9'));
      expect(info, contains('Operating system: macos'));
      expect(info, contains('OS version: Version 27.0'));

      final logs = utf8.decode(
        archive.findFile('logs.txt')!.content as List<int>,
      );
      expect(logs, contains('[ERROR] Auth: boom'));
      expect(
        logs.indexOf('started'),
        lessThan(logs.indexOf('boom')),
        reason: 'lines keep the order they were logged in',
      );
    });

    test('writes a placeholder when nothing has been logged yet', () {
      final bytes = buildDiagnosticsArchive(appInfo: const {}, logs: const []);
      final archive = ZipDecoder().decodeBytes(bytes);
      final logs = utf8.decode(
        archive.findFile('logs.txt')!.content as List<int>,
      );
      expect(logs, contains('No log lines captured yet.'));
    });
  });

  test('diagnosticsFileName stamps the local date and time', () {
    expect(
      diagnosticsFileName(DateTime(2026, 11, 4, 7, 5)),
      'zedu-diagnostics-20261104-0705.zip',
    );
  });

  test('AppLogger keeps recent lines for the export', () {
    AppLogger.i('diagnostics test line', tag: 'DiagnosticsTest');
    expect(
      AppLogger.recentLogs.any(
        (line) =>
            line.contains('[INFO] DiagnosticsTest: diagnostics test line'),
      ),
      isTrue,
    );
  });
}
