import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';

class AIService {
  static const String _baseUrl = AppConfig.kBaseUrl;

  /// Send a message to the RAG backend.
  /// [history] is a list of [userMsg, aiMsg] pairs from previous turns.
  Future<String> sendMessage(
    String message, {
    List<List<String>> history = const [],
  }) async {
    final url = Uri.parse('$_baseUrl/chat');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'history': history,
      }),
    );

    if (response.statusCode != 200) {
      return 'Error ${response.statusCode}: ${response.body}';
    }

    return jsonDecode(response.body)['reply'] as String;
  }
}
