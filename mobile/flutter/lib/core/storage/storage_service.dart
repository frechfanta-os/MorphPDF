import 'dart:convert';
import 'dart:io';
import 'app_paths.dart';

abstract class StorageService {
  Future<File> saveTemp(String fileName, List<int> bytes);
  Future<File?> getTemp(String fileName);
  Future<void> deleteTemp(String fileName);
  Future<File> saveExport(String fileName, List<int> bytes);
  Future<List<File>> listExports();
  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted(bool completed);
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

  @override
  Future<bool> isOnboardingCompleted() async {
    try {
      final docDir = await AppPaths.getDocumentsDirectory();
      final file = File('${docDir.path}/app_state.json');
      if (!await file.exists()) return false;
      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      return map['onboardingCompleted'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    try {
      final docDir = await AppPaths.getDocumentsDirectory();
      final file = File('${docDir.path}/app_state.json');
      Map<String, dynamic> map = {};
      if (await file.exists()) {
        try {
          map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        } catch (_) {}
      }
      map['onboardingCompleted'] = completed;
      await file.writeAsString(jsonEncode(map));
    } catch (_) {}
  }
}
