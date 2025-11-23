import 'package:flutter/foundation.dart';
import '../models/ai_config.dart';
import '../services/storage_service.dart';
import '../services/ai/ai_service.dart';
import '../services/ai/gemini_service.dart';
import '../services/ai/ollama_service.dart';
import '../services/ai/lm_studio_service.dart';

/// Provider for managing AI settings and service
class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;
  AIConfig _config = AIConfig();
  AIService? _activeService;
  bool _isLoading = false;
  String? _errorMessage;

  SettingsProvider(this._storageService) {
    _loadConfig();
  }

  AIConfig get config => _config;
  AIService? get activeService => _activeService;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isConfigured => _config.isConfigured;

  /// Load configuration from storage
  Future<void> _loadConfig() async {
    _isLoading = true;
    notifyListeners();

    try {
      _config = await _storageService.loadAIConfig();
      _initializeService();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load settings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initialize the active AI service based on config
  void _initializeService() {
    if (!_config.enabled || !_config.isConfigured) {
      _activeService = null;
      return;
    }

    switch (_config.provider) {
      case AIProvider.gemini:
        if (_config.geminiApiKey != null) {
          _activeService = GeminiService(apiKey: _config.geminiApiKey!);
        }
        break;
      case AIProvider.ollama:
        if (_config.ollamaEndpoint != null) {
          _activeService = OllamaService(
            endpoint: _config.ollamaEndpoint!,
            modelName: _config.modelName ?? 'llava',
          );
        }
        break;
      case AIProvider.lmStudio:
        if (_config.lmStudioEndpoint != null) {
          _activeService = LMStudioService(
            endpoint: _config.lmStudioEndpoint!,
            modelName: _config.modelName ?? 'local-model',
          );
        }
        break;
    }
  }

  /// Update configuration
  Future<void> updateConfig(AIConfig newConfig) async {
    _isLoading = true;
    notifyListeners();

    try {
      _config = newConfig;
      await _storageService.saveAIConfig(_config);
      _initializeService();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to save settings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Test connection to the AI service
  Future<bool> testConnection() async {
    if (_activeService == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _activeService!.testConnection();
      if (!result) {
        _errorMessage = 'Connection test failed';
      }
      return result;
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      return false;
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
