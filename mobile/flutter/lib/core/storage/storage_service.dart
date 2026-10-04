import 'dart:io';
import 'app_paths.dart';

abstract class StorageService {
  Future<File> saveTemp(String fileName, List<int> bytes);
  Future<File?> getTemp(String fileName);
  Future<void> deleteTemp(String fileName);
  Future<File> saveExport(String fileName, List<int> bytes);
  Future<List<File>> listExports();
}

class LocalStorageService implements StorageService {
  @override
  Future<File> saveTemp(String fileName, List<int> bytes) async {
    final tempDir = await AppPaths.getCacheDirectory();
    final file = File('${tempDir.path}/$fileName');
    return file.writeAsBytes(bytes);
  }

  @override
  Future<File?> getTemp(String fileName) async {
    final tempDir = await AppPaths.getCacheDirectory();
    final file = File('${tempDir.path}/$fileName');
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  @override
  Future<void> deleteTemp(String fileName) async {
    final tempDir = await AppPaths.getCacheDirectory();
    final file = File('${tempDir.path}/$fileName');
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<File> saveExport(String fileName, List<int> bytes) async {
    final exportDir = await AppPaths.getExportDirectory();
    final file = File('${exportDir.path}/$fileName');
    return file.writeAsBytes(bytes);
  }

  @override
  Future<List<File>> listExports() async {
    final exportDir = await AppPaths.getExportDirectory();
    final entities = exportDir.listSync();
    return entities.whereType<File>().toList();
  }
}
