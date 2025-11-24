import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

/// Gemini API implementation
class GeminiService implements AIService {
  final String apiKey;
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1';
  static const String modelName = 'gemini-2.5-flash';

  GeminiService({required this.apiKey});

  @override
  String get serviceName => 'Gemini API';

  @override
  Future<String> performOCR(Uint8List imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('$baseUrl/models/$modelName:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      '画像に含まれるすべての手書きテキストを抽出してください。テキストのみを返してください。'
                },
                {
                  'inline_data': {
                    'mime_type': 'image/png',
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 2048,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return text?.toString().trim() ?? '';
      } else {
        throw AIServiceException(
          'Gemini API error: ${response.statusCode}',
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
        Uri.parse('$baseUrl/models/$modelName:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      '以下のテキストを指示に従って書き直してください。\n\n指示: $instruction\n\nテキスト:\n$text\n\n書き直したテキストのみを返してください。'
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 2048,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rewritten =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return rewritten?.toString().trim() ?? text;
      } else {
        throw AIServiceException(
          'Gemini API error: ${response.statusCode}',
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
        Uri.parse('$baseUrl/models/$modelName?key=$apiKey'),
      );
      
      print('Gemini API test response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Gemini API error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Gemini API connection error: $e');
      return false;
    }
  }
}
