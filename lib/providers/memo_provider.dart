import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/memo.dart';
import '../models/stroke.dart';
import '../services/storage_service.dart';
import '../services/ai/ai_service.dart';
import '../utils/image_converter.dart';

/// Provider for managing memos
class MemoProvider extends ChangeNotifier {
  final StorageService _storageService;
  List<Memo> _memos = [];
  bool _isLoading = false;
  String? _errorMessage;
  final _uuid = const Uuid();

  // Filter state
  String _searchQuery = '';
  List<String> _selectedTags = [];

  MemoProvider(this._storageService) {
    loadMemos();
  }

  List<Memo> get memos => _getFilteredMemos();
  List<Memo> get allMemos => _memos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  List<String> get selectedTags => _selectedTags;

  /// Get all unique tags from all memos
  List<String> get allTags {
    final tags = <String>{};
    for (final memo in _memos) {
      tags.addAll(memo.tags);
    }
    final tagList = tags.toList();
    tagList.sort();
    return tagList;
  }

  /// Get filtered memos based on search query and tags
  List<Memo> _getFilteredMemos() {
    var filtered = _memos;

    // Filter by tags
    if (_selectedTags.isNotEmpty) {
      filtered = filtered.where((memo) => memo.hasAnyTag(_selectedTags)).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((memo) => memo.matchesSearch(_searchQuery)).toList();
    }

    return filtered;
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Set selected tags filter
  void setSelectedTags(List<String> tags) {
    _selectedTags = tags;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedTags = [];
    notifyListeners();
  }

  /// Load all memos from storage
  Future<void> loadMemos() async {
    _isLoading = true;
    notifyListeners();

    try {
      _memos = await _storageService.loadAllMemos();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load memos: $e';
      _memos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new memo
  Future<Memo> createMemo() async {
    final memo = Memo(id: _uuid.v4());
    _memos.insert(0, memo);
    notifyListeners();

    try {
      await _storageService.saveMemo(memo);
    } catch (e) {
      _errorMessage = 'Failed to create memo: $e';
    }

    return memo;
    if (index != -1) {
      _memos.removeAt(index);
      notifyListeners();

      try {
        await _storageService.deleteMemo(id);
        _errorMessage = null;
      } catch (e) {
        _errorMessage = 'Failed to delete memo: $e';
      }
    }
  }

  /// Perform OCR on memo's handwriting
  Future<String?> performOCR(Memo memo, AIService aiService) async {
    if (memo.strokes.isEmpty) {
      _errorMessage = 'No handwriting to analyze';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Convert strokes to image
      final imageBytes = await ImageConverter.strokesToImage(memo.strokes);
      if (imageBytes == null) {
        throw Exception('Failed to convert strokes to image');
      }

      // Perform OCR
      final ocrText = await aiService.performOCR(imageBytes);
      
      // Update memo with OCR result
      memo.ocrText = ocrText;
      await updateMemo(memo);

      _errorMessage = null;
      return ocrText;
    } catch (e) {
      _errorMessage = 'OCR failed: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Perform OCR on pasted image
  Future<String?> performImageOCR(Memo memo, AIService aiService) async {
    if (memo.pastedImage == null) {
      _errorMessage = 'No pasted image to analyze';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Decode base64 image
      final imageBytes = base64.decode(memo.pastedImage!);

      // Perform OCR
      final ocrText = await aiService.performOCR(imageBytes);
      
      // Append to existing OCR text or replace
      if (memo.ocrText != null && memo.ocrText!.isNotEmpty) {
        memo.ocrText = '${memo.ocrText}\n\n[画像からのOCR]\n$ocrText';
      } else {
        memo.ocrText = ocrText;
      }
      await updateMemo(memo);

      _errorMessage = null;
      return ocrText;
    } catch (e) {
      _errorMessage = 'Image OCR failed: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Rewrite text using AI
  Future<String?> rewriteText(
    String text,
    String instruction,
    AIService aiService,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final rewritten = await aiService.rewriteText(text, instruction);
      _errorMessage = null;
      return rewritten;
    } catch (e) {
      _errorMessage = 'Text rewrite failed: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
