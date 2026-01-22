import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// OpenAI configuration and client utilities.
///
/// This client reads its configuration from environment variables at runtime:
/// - OPENAI_PROXY_API_KEY
/// - OPENAI_PROXY_ENDPOINT (do NOT append v1/chat/completions; use the endpoint directly)
///
/// Example usage:
///
/// final client = OpenAIClient();
/// final text = await client.chatText(
///   system: 'You are a helpful assistant.',
///   user: 'Write a haiku about Flutter.',
/// );
/// debugPrint(text);
class OpenAIClient {
  /// These are resolved at runtime; do not hardcode secrets in source.
  static const String apiKey = String.fromEnvironment('OPENAI_PROXY_API_KEY');
  static const String endpoint = String.fromEnvironment('OPENAI_PROXY_ENDPOINT');

  /// Default model to use for general chat tasks.
  final String defaultModel;

  /// Maximum number of automatic retries on transient errors like 429/5xx.
  final int maxRetries;

  /// Base delay for exponential backoff when retrying requests.
  final Duration baseBackoff;

  OpenAIClient({this.defaultModel = 'gpt-4o', this.maxRetries = 3, this.baseBackoff = const Duration(milliseconds: 600)});

  /// Convenience method for simple text-in, text-out chats.
  Future<String> chatText({required String system, required String user, String? model, double? temperature, int? maxTokens, bool jsonResponse = false, Map<String, dynamic>? extraParams}) async {
    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': system,
      },
      {
        'role': 'user',
        'content': user,
      },
    ];

    final response = await chat(messages: messages, model: model ?? defaultModel, temperature: temperature, maxTokens: maxTokens, jsonResponse: jsonResponse, extraParams: extraParams);
    // Try to read the assistant message content if present.
    try {
      final choices = response['choices'] as List<dynamic>?;
      if (choices != null && choices.isNotEmpty) {
        final msg = choices.first['message'] as Map<String, dynamic>?;
        final content = msg?['content'];
        if (content is String) return content;
      }
    } catch (e) {
      debugPrint('OpenAI chatText parse error: $e');
    }
    // Fallback: return the raw JSON in a compact form to aid debugging.
    return jsonEncode(response);
  }

  /// General chat method. Pass in messages formatted per OpenAI Chat Completions API.
  ///
  /// When [jsonResponse] is true, the request includes response_format: { type: 'json_object' }.
  /// Remember to instruct the model in your system prompt to output a JSON object.
  Future<Map<String, dynamic>> chat({required List<Map<String, dynamic>> messages, String? model, double? temperature, int? maxTokens, bool jsonResponse = false, Map<String, dynamic>? extraParams}) async {
    _assertConfigured();

    final uri = Uri.parse(endpoint);
    final headers = _headers();

    final body = <String, dynamic>{
      'model': model ?? defaultModel,
      'messages': messages,
      if (jsonResponse) 'response_format': {'type': 'json_object'},
      if (temperature != null) 'temperature': temperature,
      if (maxTokens != null) 'max_tokens': maxTokens,
      if (extraParams != null) ...extraParams,
    };

    final json = await _postJsonWithRetry(uri: uri, headers: headers, body: body);
    return json;
  }

  /// Chat with one or more images. Provide [imageBase64List] where each entry is a base64-encoded image string
  /// (without the data: prefix). The correct content shape is constructed automatically.
  ///
  /// Example:
  ///   await chatWithImages(prompt: 'What is in these pictures?', imageBase64List: [b64_1, b64_2]);
  Future<Map<String, dynamic>> chatWithImages({required String prompt, required List<String> imageBase64List, String? model, double? temperature, int? maxTokens, bool jsonResponse = false, Map<String, dynamic>? extraParams}) async {
    _assertConfigured();

    final content = <Map<String, dynamic>>[
      {
        'type': 'text',
        'text': prompt,
      },
      ...imageBase64List.map((b64) => {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,' + b64},
          }),
    ];

    final messages = <Map<String, dynamic>>[
      {
        'role': 'user',
        'content': content,
      },
    ];

    return chat(messages: messages, model: model, temperature: temperature, maxTokens: maxTokens, jsonResponse: jsonResponse, extraParams: extraParams);
  }

  Map<String, String> _headers() => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json; charset=utf-8',
      };

  void _assertConfigured() {
    if ((apiKey).isEmpty || (endpoint).isEmpty) {
      const msg = 'OpenAI endpoint or API key not configured. Ensure OPENAI_PROXY_API_KEY and OPENAI_PROXY_ENDPOINT are provided at runtime.';
      debugPrint(msg);
      throw StateError(msg);
    }
  }

  Future<Map<String, dynamic>> _postJsonWithRetry({required Uri uri, required Map<String, String> headers, required Map<String, dynamic> body}) async {
    int attempt = 0;
    Object? lastError;

    while (attempt <= maxRetries) {
      try {
        final reqBody = jsonEncode(body);
        final resp = await http.post(uri, headers: headers, body: reqBody).timeout(const Duration(seconds: 60));
        final text = utf8.decode(resp.bodyBytes);

        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          try {
            return json.decode(text) as Map<String, dynamic>;
          } catch (e) {
            debugPrint('OpenAI JSON decode error: $e');
            throw const FormatException('Malformed JSON from OpenAI');
          }
        }

        // Handle rate limiting and transient errors
        if (resp.statusCode == 429 || (resp.statusCode >= 500 && resp.statusCode < 600)) {
          attempt++;
          if (attempt > maxRetries) {
            throw HttpExceptionWithBody('OpenAI request failed after retries (${resp.statusCode}).', statusCode: resp.statusCode, body: text);
          }
          final retryAfter = _parseRetryAfter(resp.headers['retry-after']);
          final backoff = _expBackoff(attempt, retryAfter: retryAfter);
          debugPrint('OpenAI transient error ${resp.statusCode}. Retrying in ${backoff.inMilliseconds} ms (attempt $attempt/$maxRetries)...');
          await Future.delayed(backoff);
          continue;
        }

        // Non-retryable error
        final message = _extractOpenAIErrorMessage(text) ?? 'HTTP ${resp.statusCode}';
        throw HttpExceptionWithBody('OpenAI error: $message', statusCode: resp.statusCode, body: text);
      } on TimeoutException catch (e) {
        lastError = e;
        attempt++;
        if (attempt > maxRetries) rethrow;
        final backoff = _expBackoff(attempt);
        debugPrint('OpenAI timeout. Retrying in ${backoff.inMilliseconds} ms (attempt $attempt/$maxRetries)...');
        await Future.delayed(backoff);
      } catch (e) {
        lastError = e;
        rethrow;
      }
    }

    throw StateError('OpenAI request failed: $lastError');
  }

  Duration _expBackoff(int attempt, {Duration? retryAfter}) {
    if (retryAfter != null) return retryAfter;
    final factorMs = baseBackoff.inMilliseconds;
    final ms = (factorMs * (1 << (attempt - 1))).clamp(factorMs, 8000);
    return Duration(milliseconds: ms);
  }

  Duration? _parseRetryAfter(String? header) {
    if (header == null) return null;
    // Retry-After can be seconds or a HTTP date. We support seconds.
    final seconds = int.tryParse(header);
    if (seconds != null) return Duration(seconds: seconds);
    return null;
  }

  String? _extractOpenAIErrorMessage(String body) {
    try {
      final map = json.decode(body) as Map<String, dynamic>;
      final error = map['error'];
      if (error is Map<String, dynamic>) {
        final msg = error['message'];
        if (msg is String) return msg;
      }
    } catch (_) {
      // ignore parse errors
    }
    return null;
  }
}

/// Exception that carries HTTP status code and response body for easier debugging.
class HttpExceptionWithBody implements Exception {
  final String message;
  final int? statusCode;
  final String? body;
  const HttpExceptionWithBody(this.message, {this.statusCode, this.body});
  @override
  String toString() => 'HttpExceptionWithBody(statusCode: ' + (statusCode?.toString() ?? 'null') + ', message: ' + message + ')';
}
