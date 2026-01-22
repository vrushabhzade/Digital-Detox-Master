import 'package:flutter/foundation.dart';
import 'package:digital_detox_master/voice/elevenlabs_service.dart';
import 'package:digital_detox_master/openai/openai_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages Voice Coach settings and provides convenience prompts.
class VoiceCoachProvider extends ChangeNotifier {
  bool _enabled = false;
  String _coachName = 'Champion';
  String _personaKey = 'Motivational Coach';
  String _voiceId = ElevenLabsTts.defaultVoiceId;

  VoiceCoachProvider() {
    _loadTtsConfig();
  }

  bool get enabled => _enabled;
  String get coachName => _coachName;
  String get personaKey => _personaKey;
  String get voiceId => _voiceId;

  set enabled(bool v) { _enabled = v; notifyListeners(); }
  set coachName(String v) { _coachName = v; notifyListeners(); }
  void setPersona(String key) { if (_personas.containsKey(key)) { _personaKey = key; notifyListeners(); } }
  void setVoiceId(String id) { if (id.trim().isNotEmpty) { _voiceId = id.trim(); notifyListeners(); } }

  /// Preconfigured personas with tuning settings.
  /// You can point multiple personas to the same underlying voice and vary style.
  Map<String, _PersonaSettings> get personas => _personas;

  static final Map<String, _PersonaSettings> _personas = {
    'Motivational Coach': _PersonaSettings(stability: 0.35, similarityBoost: 0.8),
    'Calm Mentor': _PersonaSettings(stability: 0.8, similarityBoost: 0.6),
    'Friendly Buddy': _PersonaSettings(stability: 0.55, similarityBoost: 0.8),
    'Professional Guide': _PersonaSettings(stability: 0.65, similarityBoost: 0.85),
    'Zen Master': _PersonaSettings(stability: 0.9, similarityBoost: 0.5),
  };

  _PersonaSettings get _current => _personas[_personaKey] ?? _personas.values.first;

  Future<void> speak(String text) async {
    if (!_enabled) return;
    await ElevenLabsTts.instance.speak(
      text,
      voiceId: _voiceId,
      stability: _current.stability,
      similarityBoost: _current.similarityBoost,
    );
  }

  /// Load any locally saved TTS config (API key, voiceId) safely.
  Future<void> _loadTtsConfig() async {
    try {
      await ElevenLabsTts.instance.loadPersistedApiKey();
      final prefs = await SharedPreferences.getInstance();
      final savedVoiceId = prefs.getString('elevenlabs_voice_id');
      if (savedVoiceId != null && savedVoiceId.trim().isNotEmpty) {
        _voiceId = savedVoiceId.trim();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('VoiceCoachProvider: failed to load TTS config: $e');
    }
  }

  /// Generate and speak a short, high-signal daily insight.
  /// Falls back to a static script when OpenAI is not configured or on error.
  Future<void> playDailyInsight() async {
    final fallback = "Here's your daily insight: Your attention is your most scarce asset. Protect it like a pro. Today, choose one task that truly matters and commit to 25 focused minutes. I'm right here with you.";
    String script = fallback;

    try {
      // Attempt AI-generated content if OpenAI is configured; OpenAIClient will throw if not configured.
      final ai = OpenAIClient();
      script = await ai.chatText(
        system: 'You are a concise, motivational digital coach helping people reduce mindless phone use and reclaim deep focus. Speak in one short paragraph (2-3 sentences), warm and practical. Avoid emojis and fluff. End with a concrete micro-action for today.',
        user: 'Generate today\'s daily insight for a focus & digital detox app. Keep it under 55 words.',
        model: 'gpt-4o-mini',
        temperature: 0.8,
        maxTokens: 120,
      );
      if (script.trim().isEmpty) script = fallback;
    } catch (e) {
      debugPrint('Daily insight AI generation failed, using fallback. Error: $e');
      script = fallback;
    }

    await speak(script);
  }

  // Convenience prompts for Focus Timer lifecycle
  Future<void> onFocusStart() => speak('Alright, $_coachName, focus session starting now. I am with you.');
  Future<void> onBreakStart() => speak('Great job, $_coachName. Take a short break. Breathe and reset.');
  Future<void> onLongBreakStart() => speak('Deep work complete. Enjoy a longer break—hydrate and stretch.');
  Future<void> onMidpointCheckIn() => speak('Halfway there. How are you feeling? Two deep breaths, then continue.');
  Future<void> onSessionComplete() => speak('Session complete! Proud of you, $_coachName. Log a quick win and take a breather.');
}

class _PersonaSettings {
  final double stability;
  final double similarityBoost;
  const _PersonaSettings({required this.stability, required this.similarityBoost});
}
