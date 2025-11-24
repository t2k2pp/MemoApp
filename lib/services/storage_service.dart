import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/memo.dart';
import '../models/ai_config.dart';

/// Service for persisting memos and settings
class StorageService {
  static const String _memosKey = 'memos_data';
  static const String _aiConfigKey = 'ai_config';

  /// Save a memo
  Future<void> saveMemo(Memo memo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load existing memos
      final memosMap = await _loadMemosMap();
      
      // Add or update memo
      memosMap[memo.id] = memo.toJson();
      
      // Save back to SharedPreferences
      await prefs.setString(_memosKey, jsonEncode(memosMap));
    } catch (e) {
      throw StorageException('Failed to save memo: $e');
    }
  }

  /// Load a memo by ID
  Future<Memo?> loadMemo(String id) async {
    try {
      final memosMap = await _loadMemosMap();
      final memoJson = memosMap[id];
      if (memoJson == null) return null;
      
      return Memo.fromJson(memoJson as Map<String, dynamic>);
    } catch (e) {
      print('Error loading memo $id: $e');
      return null;
    }
  }

  /// Load all memos
  Future<List<Memo>> loadAllMemos() async {
    try {
      final memosMap = await _loadMemosMap();
      final memos = <Memo>[];
      
      for (final memoJson in memosMap.values) {
        try {
          final memo = Memo.fromJson(memoJson as Map<String, dynamic>);
          memos.add(memo);
        } catch (e) {
          print('Error parsing memo: $e');
        }
      }
      
      // Sort by updated date (newest first)
      memos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return memos;
    } catch (e) {
      print('Error loading all memos: $e');
      return [];
    }
  }

  /// Delete a memo
  Future<void> deleteMemo(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memosMap = await _loadMemosMap();
      
      memosMap.remove(id);
      
      await prefs.setString(_memosKey, jsonEncode(memosMap));
    } catch (e) {
      throw StorageException('Failed to delete memo: $e');
    }
  }

  /// Load memos map from SharedPreferences
  Future<Map<String, dynamic>> _loadMemosMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_memosKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return {};
      }
      
      final decoded = jsonDecode(jsonString);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return {};
    } catch (e) {
      print('Error loading memos map: $e');
      return {};
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
