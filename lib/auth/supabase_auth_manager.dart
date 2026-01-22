import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_detox_master/supabase/supabase_config.dart';
import 'package:digital_detox_master/auth/auth_manager.dart';

/// Supabase implementation of AuthManager with email/password flows.
class SupabaseAuthManager extends AuthManager with EmailSignInManager {
  GoTrueClient get _auth => SupabaseConfig.auth;

  @override
  Future<dynamic> signInWithEmail(
      BuildContext context, String email, String password) async {
    try {
      final AuthResponse res = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res.user;
    } catch (e) {
      debugPrint('Supabase signInWithEmail error: $e');
      rethrow;
    }
  }

  @override
  Future<dynamic> createAccountWithEmail(
      BuildContext context, String email, String password) async {
    try {
      final AuthResponse res = await _auth.signUp(
        email: email,
        password: password,
      );
      return res.user;
    } catch (e) {
      debugPrint('Supabase createAccountWithEmail error: $e');
      rethrow;
    }
  }

  @override
  Future resetPassword(
      {required String email, required BuildContext context}) async {
    try {
      await _auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Supabase resetPassword error: $e');
      rethrow;
    }
  }

  @override
  Future updateEmail(
      {required String email, required BuildContext context}) async {
    try {
      await _auth.updateUser(UserAttributes(email: email));
    } catch (e) {
      debugPrint('Supabase updateEmail error: $e');
      rethrow;
    }
  }

  @override
  Future signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Supabase signOut error: $e');
      rethrow;
    }
  }

  @override
  Future deleteUser(BuildContext context) async {
    // Deleting a user requires service role; skip on client.
    debugPrint('deleteUser is not supported on client without service role.');
    return Future.value();
  }

  @override
  Future<void> sendEmailVerification({required String email}) async {
    // Supabase handles verification emails on sign up by default.
    // You can trigger a resend via auth.admin with service role (not available on client).
    debugPrint('sendEmailVerification is handled server-side in Supabase.');
  }

  @override
  Future<void> refreshUser() async {
    try {
      await _auth.refreshSession();
    } catch (e) {
      debugPrint('Supabase refreshUser error: $e');
    }
  }
}
