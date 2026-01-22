import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_detox_master/supabase/supabase_config.dart';

/// Model for demo credentials returned by the edge function
class DemoCredentials {
  final String email;
  final String password;
  final String? userId;
  DemoCredentials({required this.email, required this.password, this.userId});

  factory DemoCredentials.fromJson(Map<String, dynamic> json) => DemoCredentials(
        email: json['email'] as String,
        password: json['password'] as String,
        userId: json['user_id'] as String?,
      );
}

/// Service to generate demo credentials via Supabase Edge Function
class DemoService {
  static const _functionName = 'generate_demo_user';

  /// Invokes the edge function to create a demo user and return credentials.
  /// Throws with a user-friendly message when it fails.
  static Future<DemoCredentials> generateDemoCredentials() async {
    try {
      final SupabaseClient client = SupabaseConfig.client;
      final result = await client.functions.invoke(_functionName, body: const {});

      // supabase-flutter returns either data (decoded) or throws; guard just in case
      final data = result.data;
      if (data == null) {
        throw 'No data returned from edge function';
      }
      // Ensure map
      final Map<String, dynamic> map = data is Map<String, dynamic>
          ? data
          : json.decode(json.encode(data)) as Map<String, dynamic>;
      if (!map.containsKey('email') || !map.containsKey('password')) {
        throw 'Malformed response from edge function';
      }
      return DemoCredentials.fromJson(map);
    } catch (e) {
      debugPrint('generateDemoCredentials error: $e');
      throw 'Failed to generate demo credentials. Please deploy the edge function and try again.';
    }
  }
}
