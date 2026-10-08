import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// Extension to restore the convenient [size] property on [PlatformFile]
/// which was replaced by [PlatformFile.lengthSync] in file_picker 12+.
extension PlatformFileSizeExtension on PlatformFile {
  /// File size in bytes. Returns the length reported by the native picker,
  /// or falls back to querying the file on disk if available.
  int get size {
    final len = lengthSync();
    if (len != null) return len;
    final filePath = path;
    if (filePath != null) {
      final f = File(filePath);
      if (f.existsSync()) {
        return f.lengthSync();
      }
    }
    return 0;
  }
}

/// Centralized wrapper around [FilePicker] so file-picking config
/// (type, allowed extensions) stays consistent across the app.
class AppFilePicker {
  const AppFilePicker._();

  /// [FilePicker] throws an [ArgumentError] when [allowedExtensions] is passed
  /// with any type other than [FileType.custom], and when [FileType.custom] is
  /// used without extensions. Normalize both here so callers can't break the
  /// picker by passing a filter that the platform type already implies.
  static List<String>? _sanitizeExtensions(
    FileType type,
    List<String>? allowedExtensions,
  ) {
    if (type != FileType.custom) return null;
    if (allowedExtensions == null || allowedExtensions.isEmpty) return null;
    return allowedExtensions
        .map((e) => e.replaceAll('.', '').trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Pick a single file. Returns null if the user cancels the picker.
  static Future<PlatformFile?> pickFile({
    FileType type = FileType.custom,
    List<String>? allowedExtensions,
  }) async {
    final extensions = _sanitizeExtensions(type, allowedExtensions);
    final effectiveType = (type == FileType.custom && extensions == null)
        ? FileType.any
        : type;
    try {
      return await FilePicker.pickFile(
        type: effectiveType,
        allowedExtensions: extensions,
      );
    } on Exception catch (e) {
      log('AppFilePicker.pickFile failed: $e');
      return null;
    }
  }

  /// Pick multiple files. Returns null if the user cancels the picker.
  static Future<List<PlatformFile>?> pickFiles({
    FileType type = FileType.custom,
    List<String>? allowedExtensions,
  }) async {
    final extensions = _sanitizeExtensions(type, allowedExtensions);
    final effectiveType = (type == FileType.custom && extensions == null)
        ? FileType.any
        : type;
    try {
      final result = await FilePicker.pickFiles(
        type: effectiveType,
        allowedExtensions: extensions,
      );
      return result;
    } on Exception catch (e) {
      log('AppFilePicker.pickFiles failed: $e');
      return null;
    }
  }
}
