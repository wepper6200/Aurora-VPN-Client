import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Where an exported log file goes.
abstract interface class LogFileTarget {
  /// Saves [content] as [fileName]. Returns the saved path when the file
  /// stays somewhere the user can open it, or `null` when it was handed to
  /// the system share sheet instead.
  Future<String?> save(String fileName, String content);
}

/// Windows: the user's Downloads folder (Documents as a fallback).
class DownloadsLogFileTarget implements LogFileTarget {
  const DownloadsLogFileTarget();

  @override
  Future<String?> save(String fileName, String content) async {
    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(content, flush: true);
    return file.path;
  }
}

/// Android: written to `cache/logs` and offered through the share sheet
/// (save to Files, send to a chat…). See `res/xml/file_paths.xml`.
class ShareSheetLogFileTarget implements LogFileTarget {
  const ShareSheetLogFileTarget();

  static const _channel = MethodChannel('aurora/vpn');

  @override
  Future<String?> save(String fileName, String content) async {
    final dir = Directory('${(await getTemporaryDirectory()).path}/logs');
    // Only the latest export is kept around.
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content, flush: true);
    final shared = await _channel.invokeMethod<bool>('shareFile', {
      'path': file.path,
      'mime': 'text/plain',
    });
    if (shared != true) throw const FileSystemException('share sheet unavailable');
    return null;
  }
}
