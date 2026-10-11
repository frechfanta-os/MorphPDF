import 'dart:convert';
import 'dart:io';
import 'app_paths.dart';
import 'recent_document.dart';

abstract class StorageService {
  Future<File> saveTemp(String fileName, List<int> bytes);
  Future<File?> getTemp(String fileName);
  Future<void> deleteTemp(String fileName);
  Future<File> saveExport(String fileName, List<int> bytes);
  Future<List<File>> listExports();
  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted(bool completed);
  Future<List<RecentDocument>> getRecentDocuments();
  Future<void> addRecentDocument(String path, {String? name, int? sizeBytes, int? pageCount});
  Future<void> removeRecentDocument(String path);
  Future<void> clearRecentDocuments();
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

  @override
  Future<List<RecentDocument>> getRecentDocuments() async {
    try {
      final docDir = await AppPaths.getDocumentsDirectory();
      final file = File('${docDir.path}/recent_documents.json');
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      final recents = <RecentDocument>[];

      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final doc = RecentDocument.fromJson(item);
          // Only return documents that still exist on disk
          if (File(doc.path).existsSync()) {
            recents.add(doc);
          }
        }
      }

      recents.sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
      return recents;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> addRecentDocument(
    String path, {
    String? name,
    int? sizeBytes,
    int? pageCount,
  }) async {
    try {
      final file = File(path);
      if (!await file.exists()) return;

      final docDir = await AppPaths.getDocumentsDirectory();
      final historyFile = File('${docDir.path}/recent_documents.json');

      List<RecentDocument> current = await getRecentDocuments();
      // Remove previous entry for same path
      current = current.where((d) => d.path != path).toList();

      final resolvedName = name ?? file.uri.pathSegments.last;
      final resolvedSize = sizeBytes ?? await file.length();
      final resolvedPages = pageCount ?? 1;

      current.insert(
        0,
        RecentDocument(
          path: path,
          fileName: resolvedName,
          fileSize: resolvedSize,
          pageCount: resolvedPages,
          lastOpened: DateTime.now(),
        ),
      );

      // Keep at most 50 recent documents
      if (current.length > 50) {
        current = current.sublist(0, 50);
      }

      final encoded = jsonEncode(current.map((d) => d.toJson()).toList());
      await historyFile.writeAsString(encoded);
    } catch (_) {}
  }

  @override
  Future<void> removeRecentDocument(String path) async {
    try {
      final docDir = await AppPaths.getDocumentsDirectory();
      final historyFile = File('${docDir.path}/recent_documents.json');
      if (!await historyFile.exists()) return;

      List<RecentDocument> current = await getRecentDocuments();
      current = current.where((d) => d.path != path).toList();

      final encoded = jsonEncode(current.map((d) => d.toJson()).toList());
      await historyFile.writeAsString(encoded);
    } catch (_) {}
  }

  @override
  Future<void> clearRecentDocuments() async {
    try {
      final docDir = await AppPaths.getDocumentsDirectory();
      final historyFile = File('${docDir.path}/recent_documents.json');
      if (await historyFile.exists()) {
        await historyFile.writeAsString('[]');
      }
    } catch (_) {}
  }
}
