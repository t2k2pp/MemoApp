import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

/// Ollama local AI implementation
class OllamaService implements AIService {
  final String endpoint;
  final String modelName;

  OllamaService({
    required this.endpoint,
    this.modelName = 'llava',
  });

  @override
  String get serviceName => 'Ollama ($modelName)';

  @override
  Future<String> performOCR(Uint8List imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('$endpoint/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': modelName,
          'prompt':
              '画像に含まれるすべての手書きテキストを抽出してください。テキストのみを返してください。',
          'images': [base64Image],
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response']?.toString().trim() ?? '';
      } else {
        throw AIServiceException(
          'Ollama API error: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      throw AIServiceException('OCR failed', e.toString());
    }
  }

  @override
  Future<String> rewriteText(String text, String instruction) async {
    try {
      final response = await http.post(
        Uri.parse('$endpoint/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': modelName,
          'prompt':
              '以下のテキストを指示に従って書き直してください。\n\n指示: $instruction\n\nテキスト:\n$text\n\n書き直したテキストのみを返してください。',
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response']?.toString().trim() ?? text;
      } else {
        throw AIServiceException(
          'Ollama API error: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      throw AIServiceException('Text rewrite failed', e.toString());
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$endpoint/api/tags'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
