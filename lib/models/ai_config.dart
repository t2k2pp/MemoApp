/// AI provider types supported by the app
enum AIProvider {
  gemini,
  ollama,
  lmStudio;

  String get displayName {
    switch (this) {
      case AIProvider.gemini:
        return 'Gemini API';
      case AIProvider.ollama:
        return 'Ollama';
      case AIProvider.lmStudio:
        return 'LM Studio';
    }
  }
}

/// AI provider configuration settings
class AIConfig {
  AIProvider provider;
  String? geminiApiKey;
  String? ollamaEndpoint;
  String? lmStudioEndpoint;
  String? modelName;
  bool enabled;

  AIConfig({
    this.provider = AIProvider.gemini,
    this.geminiApiKey,
    this.ollamaEndpoint,
    this.lmStudioEndpoint,
    this.modelName,
    this.enabled = false,
  });

  /// Convert config to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'geminiApiKey': geminiApiKey,
      'ollamaEndpoint': ollamaEndpoint,
      'lmStudioEndpoint': lmStudioEndpoint,
      'modelName': modelName,
      'enabled': enabled,
    };
  }

  /// Create config from JSON
  factory AIConfig.fromJson(Map<String, dynamic> json) {
    return AIConfig(
      provider: AIProvider.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => AIProvider.gemini,
      ),
      geminiApiKey: json['geminiApiKey'],
      ollamaEndpoint: json['ollamaEndpoint'],
      lmStudioEndpoint: json['lmStudioEndpoint'],
      modelName: json['modelName'],
      enabled: json['enabled'] ?? false,
    );
  }

  /// Check if current provider is properly configured
  bool get isConfigured {
    if (!enabled) return false;
    
    switch (provider) {
      case AIProvider.gemini:
        return geminiApiKey != null && geminiApiKey!.isNotEmpty;
      case AIProvider.ollama:
        return ollamaEndpoint != null && ollamaEndpoint!.isNotEmpty;
      case AIProvider.lmStudio:
        return lmStudioEndpoint != null && lmStudioEndpoint!.isNotEmpty;
    }
  }

  /// Get the active endpoint URL for API calls
  String? get activeEndpoint {
    switch (provider) {
      case AIProvider.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta';
      case AIProvider.ollama:
        return ollamaEndpoint ?? 'http://localhost:11434';
      case AIProvider.lmStudio:
        return lmStudioEndpoint ?? 'http://localhost:1234';
    }
  }

  AIConfig copyWith({
    AIProvider? provider,
    String? geminiApiKey,
    String? ollamaEndpoint,
    String? lmStudioEndpoint,
    String? modelName,
    bool? enabled,
  }) {
    return AIConfig(
      provider: provider ?? this.provider,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      ollamaEndpoint: ollamaEndpoint ?? this.ollamaEndpoint,
      lmStudioEndpoint: lmStudioEndpoint ?? this.lmStudioEndpoint,
      modelName: modelName ?? this.modelName,
      enabled: enabled ?? this.enabled,
    );
  }
}
