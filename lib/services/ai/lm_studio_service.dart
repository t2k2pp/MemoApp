import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

/// LM Studio local AI implementation (OpenAI-compatible API)
class LMStudioService implements AIService {
  final String endpoint;
  final String modelName;

  LMStudioService({
    required this.endpoint,
    this.modelName = 'local-model',
  });

  @override
  String get serviceName => 'LM Studio ($modelName)';

  @override
  Future<String> performOCR(Uint8List imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('$endpoint/v1/chat/completions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': modelName,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text':
                      '画像に含まれるすべての手書きテキストを抽出してください。テキストのみを返してください。'
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/png;base64,$base64Image',
                  }
                }
              ]
            }
          ],
          'temperature': 0.1,
          'max_tokens': 2048,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'];
        return text?.toString().trim() ?? '';
      } else {
        throw AIServiceException(
          'LM Studio API error: ${response.statusCode}',
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
        Uri.parse('$endpoint/v1/chat/completions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': modelName,
          'messages': [
            {
              'role': 'user',
              'content':
                  '以下のテキストを指示に従って書き直してください。\n\n指示: $instruction\n\nテキスト:\n$text\n\n書き直したテキストのみを返してください。'
            }
          ],
          'temperature': 0.7,
          'max_tokens': 2048,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rewritten = data['choices']?[0]?['message']?['content'];
        return rewritten?.toString().trim() ?? text;
      } else {
        throw AIServiceException(
          'LM Studio API error: ${response.statusCode}',
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
      final response = await http.get(
        Uri.parse('$endpoint/v1/models'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
