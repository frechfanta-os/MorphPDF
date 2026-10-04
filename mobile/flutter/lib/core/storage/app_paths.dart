import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AppPaths {
  static Future<Directory> getDocumentsDirectory() async {
    return getApplicationDocumentsDirectory();
  }

  static Future<Directory> getCacheDirectory() async {
    return getTemporaryDirectory();
  }

  static Future<Directory> getExportDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${docs.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  static Future<Directory> getOcrTempDirectory() async {
    final temp = await getTemporaryDirectory();
    final ocrDir = Directory('${temp.path}/ocr_temp');
    if (!await ocrDir.exists()) {
      await ocrDir.create(recursive: true);
    }
    return ocrDir;
  }
}
