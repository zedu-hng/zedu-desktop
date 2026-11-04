import 'dart:convert';
import 'dart:io';

import 'package:zedu/core/core.dart';

/// Version shown to support. It matches `pubspec.yaml`; a build can override
/// it with `--dart-define=APP_VERSION=...`.
const String kAppVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '0.1.0+1',
);

/// Facts about the running build that help support reproduce a problem.
Map<String, String> currentDiagnosticsInfo({DateTime? generatedAt}) {
  final now = generatedAt ?? DateTime.now();
  return {
    'App': 'Zedu desktop',
    'App version': kAppVersion,
    'Generated (UTC)': now.toUtc().toIso8601String(),
    'Operating system': Platform.operatingSystem,
    'OS version': Platform.operatingSystemVersion,
    'Dart version': Platform.version,
    'Locale': Platform.localeName,
  };
}

String diagnosticsFileName(DateTime now) {
  String two(int value) => value.toString().padLeft(2, '0');
  return 'zedu-diagnostics-${now.year}${two(now.month)}${two(now.day)}'
      '-${two(now.hour)}${two(now.minute)}.zip';
}

/// One zip with `app-info.txt` and `logs.txt`, the file support asks for.
Uint8List buildDiagnosticsArchive({
  required Map<String, String> appInfo,
  required List<String> logs,
}) {
  final info = StringBuffer();
  for (final entry in appInfo.entries) {
    info.writeln('${entry.key}: ${entry.value}');
  }

  final logText = StringBuffer();
  if (logs.isEmpty) {
    logText.writeln('No log lines captured yet.');
  } else {
    for (final line in logs) {
      logText.writeln(line);
    }
  }

  final archive = Archive();
  for (final entry in {
    'app-info.txt': utf8.encode(info.toString()),
    'logs.txt': utf8.encode(logText.toString()),
  }.entries) {
    archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
  }

  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

class DiagnosticsService {
  const DiagnosticsService();

  /// Lets the user save the diagnostics zip. Returns the saved path, or null
  /// when the save dialog was cancelled.
  Future<String?> export() async {
    final bytes = buildDiagnosticsArchive(
      appInfo: currentDiagnosticsInfo(),
      logs: AppLogger.recentLogs,
    );

    final path = await FilePicker.saveFile(
      dialogTitle: 'Save diagnostics',
      fileName: diagnosticsFileName(DateTime.now()),
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      bytes: bytes,
    );
    if (path == null) return null;

    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }
}
