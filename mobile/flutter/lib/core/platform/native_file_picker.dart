import 'dart:io';
import 'package:flutter/services.dart';

/// Service interfacing with native Android Storage Access Framework (SAF)
/// to select documents and images, copying them to local cache for native FFI engines.
class NativeFilePicker {
  static const MethodChannel _channel =
      MethodChannel('com.ghdinteractivestudio.morphpdf/file_picker');

  final MethodChannel channel;

  NativeFilePicker({MethodChannel? channel}) : channel = channel ?? _channel;

  /// Picks a single file with the given MIME type (e.g. 'application/pdf', 'image/*').
  Future<String?> pickSingleFile({String mimeType = '*/*'}) async {
    try {
      final List<dynamic>? paths = await channel.invokeMethod<List<dynamic>>(
        'pickFiles',
        {
          'mimeType': mimeType,
          'allowMultiple': false,
        },
      );
      if (paths == null || paths.isEmpty) return null;
      final path = paths.first.toString();
      return File(path).existsSync() ? path : null;
    } on MissingPluginException {
      // In non-Android or unit test environments where the host engine is absent
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Picks multiple files with the given MIME type.
  Future<List<String>> pickMultipleFiles({String mimeType = '*/*'}) async {
    try {
      final List<dynamic>? paths = await channel.invokeMethod<List<dynamic>>(
        'pickFiles',
        {
          'mimeType': mimeType,
          'allowMultiple': true,
        },
      );
      if (paths == null) return const [];
      return paths
          .map((e) => e.toString())
          .where((p) => File(p).existsSync())
          .toList();
    } on MissingPluginException {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// Convenience helper to pick a single PDF file.
  Future<String?> pickPdfFile() => pickSingleFile(mimeType: 'application/pdf');

  /// Convenience helper to pick multiple PDF files.
  Future<List<String>> pickPdfFiles() => pickMultipleFiles(mimeType: 'application/pdf');

  /// Convenience helper to pick an image file (JPEG, PNG, WEBP, BMP).
  Future<String?> pickImageFile() => pickSingleFile(mimeType: 'image/*');

  /// Cleans up cached picker files.
  Future<void> clearCache() async {
    try {
      await channel.invokeMethod('clearCache');
    } catch (_) {}
  }
}
