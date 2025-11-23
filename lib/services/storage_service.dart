import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/memo.dart';
import '../models/ai_config.dart';

/// Service for persisting memos and settings
class StorageService {
  static const String _memosListKey = 'memos_list';
  static const String _aiConfigKey = 'ai_config';
  static const String _memosDirName = 'memos';

  /// Get memos directory
  Future<Directory> get _memosDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final memosDir = Directory('${appDir.path}/$_memosDirName');
    if (!await memosDir.exists()) {
      await memosDir.create(recursive: true);
    }
    return memosDir;
  }

  /// Save a memo to disk
  Future<void> saveMemo(Memo memo) async {
    try {
      final dir = await _memosDir;
      final file = File('${dir.path}/${memo.id}.json');
      await file.writeAsString(jsonEncode(memo.toJson()));

      // Update memos list
      final prefs = await SharedPreferences.getInstance();
      final memosList = prefs.getStringList(_memosListKey) ?? [];
      if (!memosList.contains(memo.id)) {
        memosList.add(memo.id);
        await prefs.setStringList(_memosListKey, memosList);
      }
    } catch (e) {
      throw StorageException('Failed to save memo: $e');
    }
  }

  /// Load a memo by ID
  Future<Memo?> loadMemo(String id) async {
    try {
      final dir = await _memosDir;
      final file = File('${dir.path}/$id.json');
      if (!await file.exists()) return null;

      final jsonString = await file.readAsString();
      return Memo.fromJson(jsonDecode(jsonString));
    } catch (e) {
      print('Error loading memo $id: $e');
      return null;
    }
  }

  /// Load all memos
  Future<List<Memo>> loadAllMemos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memosList = prefs.getStringList(_memosListKey) ?? [];

      final memos = <Memo>[];
      for (final id in memosList) {
        final memo = await loadMemo(id);
        if (memo != null) {
          memos.add(memo);
        }
      }

      // Sort by updated date (newest first)
      memos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return memos;
    } catch (e) {
      throw StorageException('Failed to load memos: $e');
    }
  }

  /// Delete a memo
  Future<void> deleteMemo(String id) async {
    try {
      final dir = await _memosDir;
      final file = File('${dir.path}/$id.json');
      if (await file.exists()) {
        await file.delete();
      }

      // Update memos list
      final prefs = await SharedPreferences.getInstance();
      final memosList = prefs.getStringList(_memosListKey) ?? [];
      memosList.remove(id);
      await prefs.setStringList(_memosListKey, memosList);
    } catch (e) {
      throw StorageException('Failed to delete memo: $e');
    }
  }

  /// Save AI configuration
  Future<void> saveAIConfig(AIConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_aiConfigKey, jsonEncode(config.toJson()));
    } catch (e) {
      throw StorageException('Failed to save AI config: $e');
    }
  }

  /// Load AI configuration
  Future<AIConfig> loadAIConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_aiConfigKey);
      if (jsonString == null) {
        return AIConfig(); // Return default config
      }
      return AIConfig.fromJson(jsonDecode(jsonString));
    } catch (e) {
      print('Error loading AI config: $e');
      return AIConfig(); // Return default config on error
    }
  }

  /// Get all unique tags from all memos
  Future<List<String>> getAllTags() async {
    try {
      final memos = await loadAllMemos();
      final tags = <String>{};
      for (final memo in memos) {
        tags.addAll(memo.tags);
      }
      final tagList = tags.toList();
      tagList.sort();
      return tagList;
    } catch (e) {
      return [];
    }
  }
}

/// Exception thrown when storage operations fail
class StorageException implements Exception {
  final String message;

  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
