import 'dart:typed_data';

/// Abstract interface for AI service providers
abstract class AIService {
  /// Perform OCR on an image and extract text
  /// Returns the extracted text or empty string if failed
  Future<String> performOCR(Uint8List imageBytes);

  /// Rewrite text based on user instruction
  /// Returns the rewritten text
  Future<String> rewriteText(String text, String instruction);

  /// Test the connection to the AI service
  /// Returns true if connection is successful
  Future<bool> testConnection();

  /// Get the name of this AI service
  String get serviceName;
}

/// Exception thrown when AI service operations fail
class AIServiceException implements Exception {
  final String message;
  final String? details;

  AIServiceException(this.message, [this.details]);

  @override
  String toString() {
    if (details != null) {
      return 'AIServiceException: $message\nDetails: $details';
    }
    return 'AIServiceException: $message';
  }
}
