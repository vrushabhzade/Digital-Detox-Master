import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_detox_master/supabase/supabase_config.dart';
import 'package:digital_detox_master/supabase/models.dart';

class ProfileService {
  static const String _profiles = 'profiles';
  static const String _userSettings = 'user_settings';
  static const String _userGamification = 'user_gamification';

  static GoTrueClient get _auth => SupabaseConfig.auth;
  static SupabaseClient get _client => SupabaseConfig.client;

  static String? get currentUserId => _auth.currentUser?.id;

  /// Ensures a profile and default settings rows exist for the current user.
  /// Safe to call multiple times.
  static Future<void> ensureBootstrapForCurrentUser() async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      // Upsert profile (id must match auth.users.id)
      await _client.from(_profiles).upsert({
        'id': uid,
        'language': 'en',
        'timezone': 'UTC',
        'dark_mode': true,
      }, onConflict: 'id');

      // Ensure settings row exists
      final existingSettings = await _client
          .from(_userSettings)
          .select('id')
          .eq('user_id', uid)
          .maybeSingle();
      if (existingSettings == null) {
        await _client.from(_userSettings).insert({'user_id': uid});
      }

      // Ensure gamification row exists
      final existingGam = await _client
          .from(_userGamification)
          .select('id')
          .eq('user_id', uid)
          .maybeSingle();
      if (existingGam == null) {
        await _client.from(_userGamification).insert({'user_id': uid});
      }
    } catch (e) {
      debugPrint('ensureBootstrapForCurrentUser error: $e');
    }
  }

  static Future<ProfileModel?> fetchCurrentProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    try {
      final data = await _client.from(_profiles).select('*').eq('id', uid).maybeSingle();
      if (data == null) return null;
      return ProfileModel.fromJson(data);
    } catch (e) {
      debugPrint('fetchCurrentProfile error: $e');
      return null;
    }
  }

  static Future<UserSettingsModel?> fetchCurrentSettings() async {
    final uid = currentUserId;
    if (uid == null) return null;
    try {
      final data = await _client
          .from(_userSettings)
          .select('*')
          .eq('user_id', uid)
          .maybeSingle();
      if (data == null) return null;
      return UserSettingsModel.fromJson(data);
    } catch (e) {
      debugPrint('fetchCurrentSettings error: $e');
      return null;
    }
  }

  static Future<void> updateVoicePreferences({String? preferredVoiceId, String? voicePersonality}) async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      final update = <String, dynamic>{};
      if (preferredVoiceId != null) update['preferred_voice_id'] = preferredVoiceId;
      if (voicePersonality != null) update['voice_personality'] = voicePersonality;
      if (update.isEmpty) return;
      await _client.from(_profiles).update(update).eq('id', uid);
    } catch (e) {
      debugPrint('updateVoicePreferences error: $e');
    }
  }
}
