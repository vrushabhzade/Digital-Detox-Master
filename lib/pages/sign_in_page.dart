import 'package:flutter/material.dart';
import 'package:digital_detox_master/auth/supabase_auth_manager.dart';
import 'package:digital_detox_master/supabase/profile_service.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_detox_master/auth/demo_credentials.dart';
import 'package:digital_detox_master/supabase/demo_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = SupabaseAuthManager();

  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscure = true;
  bool _tryingDemo = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    try {
      if (_isSignUp) {
        await _auth.createAccountWithEmail(context, email, password);
      } else {
        await _auth.signInWithEmail(context, email, password);
      }
      // Ensure user bootstrap and go home
      await ProfileService.ensureBootstrapForCurrentUser();
      if (mounted) context.go('/');
    } catch (e) {
      debugPrint('Auth submit error: $e');
      if (!mounted) return;
      String message;
      if (e is AuthException) {
        // Friendlier, domain-specific messages
        final lower = e.message.toLowerCase();
        if (lower.contains('invalid login credentials') || e.code == 'invalid_credentials') {
          message = 'Incorrect email or password. Please try again.';
        } else if (e.code == 'user_not_found') {
          message = 'No account found for that email.';
        } else if (_isSignUp && lower.contains('password')) {
          message = 'Password does not meet requirements. Use at least 6 characters.';
        } else {
          message = e.message;
        }
      } else {
        message = _isSignUp ? 'Sign up failed. Please try again.' : 'Sign in failed. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: 'Use demo',
            onPressed: () {
              if (_isLoading) return;
              // Fire and forget; errors are handled inside _tryDemoLogin
              _tryDemoLogin();
            },
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email first.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _auth.resetPassword(email: email, context: context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent.')));
    } catch (e) {
      debugPrint('Password reset error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reset failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _tryDemoLogin() async {
    setState(() {
      _tryingDemo = true;
      _isLoading = true;
    });
    try {
      String email;
      String password;

      if (DemoCredentialsConfig.isConfigured) {
        email = DemoCredentialsConfig.email;
        password = DemoCredentialsConfig.password;
      } else {
        final creds = await DemoService.generateDemoCredentials();
        email = creds.email;
        password = creds.password;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Demo user created: $email')),
          );
        }
      }

      await _auth.signInWithEmail(context, email, password);
      await ProfileService.ensureBootstrapForCurrentUser();
      if (mounted) context.go('/');
    } catch (e) {
      debugPrint('Demo login error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Demo login failed: $e')));
    } finally {
      if (mounted) setState(() {
        _tryingDemo = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.primaryContainer, cs.surface, cs.secondary.withValues(alpha: 0.1)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: cs.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_isSignUp ? 'Create account' : 'Welcome back', style: tt.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        _isSignUp ? 'Sign up to get started' : 'Sign in to continue',
                        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail, color: cs.primary),
                        ),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock, color: cs.primary),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: cs.onSurfaceVariant),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: Icon(_isSignUp ? Icons.person_add : Icons.login, color: cs.onPrimary),
                        label: Text(_isSignUp ? 'Sign up' : 'Sign in', style: tt.labelLarge?.copyWith(color: cs.onPrimary)),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.5), height: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('or', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                        ),
                        Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.5), height: 1)),
                      ]),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _tryDemoLogin,
                        icon: Icon(Icons.play_circle_outline, color: cs.primary),
                        label: Text(_tryingDemo ? 'Signing in...' : 'Try demo account'),
                      ),
                      // Use Wrap to avoid horizontal overflow on smaller screens
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed: _isLoading ? null : _resetPassword,
                            icon: Icon(Icons.refresh, color: cs.primary),
                            label: const Text('Forgot password?'),
                          ),
                          TextButton(
                            onPressed: _isLoading ? null : () => setState(() => _isSignUp = !_isSignUp),
                            child: Text(_isSignUp ? 'Have an account? Sign in' : 'New here? Create account'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
