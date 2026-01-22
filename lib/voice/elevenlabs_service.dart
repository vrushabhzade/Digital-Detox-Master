import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ElevenLabs text-to-speech client with simple audio playback.
///
/// Configuration:
/// - Provide API key at compile time via --dart-define=ELEVENLABS_API_KEY=...
/// - Optionally override base URL via --dart-define=ELEVENLABS_BASE_URL=...
///
/// No secrets are stored in source. Calls will no-op if not configured.
class ElevenLabsTts {
  ElevenLabsTts._();
  static final ElevenLabsTts instance = ElevenLabsTts._();

  // Env configuration
  static const String _apiKey = String.fromEnvironment('ELEVENLABS_API_KEY');
  static const String _baseUrl = String.fromEnvironment(
    'ELEVENLABS_BASE_URL',
    defaultValue: 'https://api.elevenlabs.io',
  );

  // Optional runtime overrides for local/dev usage. Avoid using in production builds.
  String? _apiKeyOverride; // not persisted automatically; use persistApiKey for storage
  String? _baseUrlOverride;

  // Default sample voice (Rachel)
  // Public sample voice id from ElevenLabs documentation
  static const String defaultVoiceId = '21m00Tcm4TlvDq8ikWAM';

  // Lazily initialized audio player to avoid plugin registration issues on web.
  AudioPlayer? _player;

  Future<AudioPlayer?> _ensurePlayer() async {
    if (_player != null) return _player;
    try {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      _player = p;
      return _player;
    } catch (e) {
      // If a platform is missing the audioplayers plugin (e.g., early web init), don't crash.
      debugPrint('Audio player init failed (continuing without playback): $e');
      return null;
    }
  }

  bool get isConfigured => (_apiKeyOverride?.isNotEmpty == true) || _apiKey.isNotEmpty;

  /// Load a previously saved API key from local storage.
  /// This is best-effort and safe to call multiple times.
  Future<void> loadPersistedApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('elevenlabs_api_key');
      if (saved != null && saved.trim().isNotEmpty) {
        _apiKeyOverride = saved.trim();
      }
      final savedBase = prefs.getString('elevenlabs_base_url');
      if (savedBase != null && savedBase.trim().isNotEmpty) {
        _baseUrlOverride = savedBase.trim();
      }
    } catch (e) {
      debugPrint('Failed to load ElevenLabs config: $e');
    }
  }

  /// Persist API key and optional base URL to local storage for subsequent launches.
  Future<void> persistApiConfig({required String apiKey, String? baseUrl}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('elevenlabs_api_key', apiKey.trim());
      _apiKeyOverride = apiKey.trim();
      if (baseUrl != null && baseUrl.trim().isNotEmpty) {
        await prefs.setString('elevenlabs_base_url', baseUrl.trim());
        _baseUrlOverride = baseUrl.trim();
      }
    } catch (e) {
      debugPrint('Failed to persist ElevenLabs config: $e');
    }
  }

  /// Temporary in-memory override without persisting.
  void setApiKeyOverride(String apiKey) => _apiKeyOverride = apiKey.trim();
  void setBaseUrlOverride(String baseUrl) => _baseUrlOverride = baseUrl.trim();

  /// Speaks the provided [text] using ElevenLabs TTS.
  ///
  /// [voiceId] falls back to [defaultVoiceId].
  /// [stability] and [similarityBoost] tune voice behavior.
  Future<void> speak(
    String text, {
    String? voiceId,
    double stability = 0.5,
    double similarityBoost = 0.75,
    String modelId = 'eleven_monolingual_v1',
  }) async {
    if (text.trim().isEmpty) return;
    if (!isConfigured) {
      debugPrint('ElevenLabs API key not provided. Skipping TTS.');
      return;
    }
    final vid = voiceId ?? defaultVoiceId;
    final base = (_baseUrlOverride?.isNotEmpty == true) ? _baseUrlOverride! : _baseUrl;
    final uri = Uri.parse('$base/v1/text-to-speech/$vid');

    try {
      final resp = await http.post(
        uri,
        headers: {
          'accept': 'audio/mpeg',
          'content-type': 'application/json',
          // Prefer override key when present; fall back to compile-time env
          'xi-api-key': (_apiKeyOverride?.isNotEmpty == true) ? _apiKeyOverride! : _apiKey,
        },
        body: jsonEncode({
          'text': text,
          'model_id': modelId,
          'voice_settings': {
            'stability': stability,
            'similarity_boost': similarityBoost,
          }
        }),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final Uint8List bytes = resp.bodyBytes;
        final player = await _ensurePlayer();
        if (player == null) {
          debugPrint('Audio player unavailable; TTS audio generated but cannot play on this platform.');
          return;
        }
        await player.stop();
        await player.play(BytesSource(bytes));
      } else {
        debugPrint('ElevenLabs TTS failed: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('ElevenLabs TTS error: $e');
    }
  }

  Future<void> stop() async {
    try {
      final player = await _ensurePlayer();
      await player?.stop();
    } catch (e) {
      debugPrint('Audio stop error: $e');
    }
  }
}
