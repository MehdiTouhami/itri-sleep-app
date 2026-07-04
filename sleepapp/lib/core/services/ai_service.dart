import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';

class AIService {
  static const String _baseUrl = AppConfig.kBaseUrl;

  /// Single-shot request — waits for the full reply then returns it.
  Future<String> sendMessage(
    String message, {
    List<List<String>> history = const [],
  }) async {
    final url = Uri.parse('$_baseUrl/chat');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message, 'history': history}),
    );
    if (response.statusCode != 200) {
      return 'Error ${response.statusCode}: ${response.body}';
    }
    return jsonDecode(response.body)['reply'] as String;
  }

  /// Streaming request — yields tokens as they arrive via SSE.
  ///
  /// The backend retrieves context first (~0.5s), then the LLM tokens
  /// stream word by word until the response is complete.
  /// The stream completes when the server sends `data: [DONE]`.
  Stream<String> streamMessage(
    String message, {
    List<List<String>> history = const [],
  }) async* {
    final url = Uri.parse('$_baseUrl/chat-stream');
    final request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({'message': message, 'history': history});

    final client = http.Client();
    try {
      final streamedResponse = await client.send(request);
      if (streamedResponse.statusCode != 200) {
        yield 'Error ${streamedResponse.statusCode}';
        return;
      }

      // SSE events are separated by \n\n
      // Keep a buffer for incomplete events that span multiple TCP packets
      String buffer = '';

      await for (final bytes in streamedResponse.stream) {
        buffer += utf8.decode(bytes);

        // Split on double-newline SSE separator
        final parts = buffer.split('\n\n');
        // The last element may be incomplete — keep it in the buffer
        buffer = parts.last;

        for (final part in parts.sublist(0, parts.length - 1)) {
          for (final line in part.split('\n')) {
            if (!line.startsWith('data: ')) continue;
            final data = line.substring(6).trim();
            if (data == '[DONE]') return;
            try {
              final decoded = jsonDecode(data) as Map<String, dynamic>;
              if (decoded.containsKey('token')) {
                final token = decoded['token'] as String;
                if (token.isNotEmpty) yield token;
              }
            } catch (_) {
              // Malformed event — skip silently
            }
          }
        }
      }
    } finally {
      client.close();
    }
  }
}
