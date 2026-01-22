import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_detox_master/supabase/supabase_config.dart';

class FocusService {
  static const String _table = 'focus_sessions';
  static GoTrueClient get _auth => SupabaseConfig.auth;
  static SupabaseClient get _client => SupabaseConfig.client;

  static String? get _uid => _auth.currentUser?.id;

  /// Creates a new focus session row and returns its id. Returns null if not logged in or failed.
  static Future<String?> startSession({
    String sessionType = 'pomodoro',
    required int plannedDurationMinutes,
    String? taskDescription,
    String? taskCategory,
    DateTime? startTime,
  }) async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final data = await _client
          .from(_table)
          .insert({
            'user_id': uid,
            'session_type': sessionType,
            'planned_duration_minutes': plannedDurationMinutes,
            'task_description': taskDescription,
            'task_category': taskCategory,
            'start_time': (startTime ?? DateTime.now()).toIso8601String(),
            'completed': false,
          })
          .select('id')
          .single();
      return data['id'] as String?;
    } catch (e) {
      debugPrint('startSession error: $e');
      return null;
    }
  }

  /// Marks a session complete and sets end/actual duration.
  static Future<void> completeSession({
    required String sessionId,
    required DateTime startTime,
    DateTime? endTime,
    int? qualityRating,
  }) async {
    try {
      final end = endTime ?? DateTime.now();
      final minutes = end.difference(startTime).inMinutes;
      await _client.from(_table).update({
        'end_time': end.toIso8601String(),
        'actual_duration_minutes': minutes,
        'completed': true,
        if (qualityRating != null) 'quality_rating': qualityRating,
      }).eq('id', sessionId);
    } catch (e) {
      debugPrint('completeSession error: $e');
    }
  }
}
