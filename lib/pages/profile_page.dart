import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_detox_master/providers/detox_provider.dart';
import 'package:digital_detox_master/auth/supabase_auth_manager.dart';
import 'package:digital_detox_master/supabase/profile_service.dart';
import 'package:digital_detox_master/providers/voice_coach_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _authLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<DetoxProvider>().stats;
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user == null) _buildAuthCard(theme) else _buildHeader(theme, stats.level, user.email ?? 'You'),
          if (user != null) ...[
            const SizedBox(height: 16),
            _buildStatsGrid(context, stats.minutesSaved, stats.currentStreak, stats.points),
            const SizedBox(height: 16),
            _VoicePreferencesCard(),
            const SizedBox(height: 16),
            Card(
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.notifications_off_outlined),
                  title: const Text('Focus Modes'),
                  subtitle: const Text('Manage blocked times'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: () async {
                    await SupabaseAuthManager().signOut();
                    if (!mounted) return;
                    setState(() {});
                  },
                ),
              ]),
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Long press to reset all progress')));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Progress'),
            style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sign in to sync progress', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 8),
          TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Tip: You can use a demo account. I can auto-fill it for you.',
                style: theme.textTheme.bodySmall,
                softWrap: true,
              ),
            ),
            TextButton(
              onPressed: _authLoading ? null : _prefillDemoCredentials,
              child: const Text('Auto-fill'),
            )
          ]),
          const SizedBox(height: 12),
          // Wrap avoids RenderFlex overflow on small screens
          Wrap(spacing: 8, runSpacing: 8, children: [
            SizedBox(
              width: 180,
              child: FilledButton(
                onPressed: _authLoading ? null : () => _handleAuth(signIn: true),
                child: _authLoading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Sign In'),
              ),
            ),
            SizedBox(
              width: 180,
              child: OutlinedButton(
                onPressed: _authLoading ? null : () => _handleAuth(signIn: false),
                child: const Text('Create Account'),
              ),
            ),
          ])
        ]),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, int level, String title) {
    return Center(
      child: Column(children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer),
        ),
        const SizedBox(height: 16),
        Text(title, style: theme.textTheme.headlineSmall),
        Text('Level $level', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
      ]),
    );
  }

  Widget _buildStatsGrid(BuildContext context, int minutesSaved, int streak, int points) {
    final theme = Theme.of(context);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(context, 'Total Saved', '$minutesSaved min', Icons.timer),
        _buildStatCard(context, 'Current Streak', '$streak days', Icons.local_fire_department),
        _buildStatCard(context, 'Points', '$points', Icons.star),
        _buildStatCard(context, 'Badges', '3', Icons.emoji_events),
      ],
    );
  }

  Future<void> _handleAuth({required bool signIn}) async {
    // Basic credential validation before hitting Supabase
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    String? validationError;
    if (email.isEmpty || !email.contains('@')) {
      validationError = 'Please enter a valid email address.';
    } else if (password.isEmpty || password.length < 6) {
      validationError = 'Password must be at least 6 characters.';
    }
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    setState(() => _authLoading = true);
    try {
      final auth = SupabaseAuthManager();
      if (signIn) {
        await auth.signInWithEmail(context, email, password);
      } else {
        await auth.createAccountWithEmail(context, email, password);
        // If email confirmation is required, Supabase won't start a session yet.
        final current = Supabase.instance.client.auth.currentUser;
        if (current == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Check your inbox. Confirm $email, then return here to sign in.')),
          );
          return; // Skip bootstrap until user confirms email and signs in
        }
      }
      await ProfileService.ensureBootstrapForCurrentUser();
      // Sync voice settings if any
      final profile = await ProfileService.fetchCurrentProfile();
      if (profile != null) {
        final vc = context.read<VoiceCoachProvider>();
        if (profile.preferredVoiceId != null) vc.setVoiceId(profile.preferredVoiceId!);
        if (profile.voicePersonality != null) vc.setPersona(_mapPersonalityToPersona(profile.voicePersonality!));
      }
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Auth error: $e');
      if (!mounted) return;
      String message = 'Authentication failed. Please try again.';
      if (e is AuthApiException) {
        // Improve common error explanations for users
        final m = e.message.toLowerCase();
        if (e.statusCode == 429 || m.contains('over_email_send_rate_limit') || m.contains('for security purposes')) {
          message = 'Too many requests. Please wait about a minute before trying again.';
        } else if (m.contains('anonymous') || m.contains('anonymous sign-ins are disabled')) {
          message = 'Email and password are required. Please fill both fields and try again.';
        } else if (m.contains('invalid login credentials')) {
          message = 'Invalid email or password. Please double-check and try again.';
        } else if (m.contains('email not confirmed')) {
          message = 'Email not confirmed. Please open the confirmation email we sent and try again.';
        } else {
          message = e.message;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _authLoading = false);
    }
  }

  void _prefillDemoCredentials() {
    // Fills in the demo credentials for quick testing.
    _emailController.text = 'demo@focus.app';
    _passwordController.text = 'DemoPass#2026';
    setState(() {});
  }

  String _mapPersonalityToPersona(String p) {
    switch (p) {
      case 'motivational':
        return 'Motivational Coach';
      case 'calm':
        return 'Calm Mentor';
      case 'friendly':
        return 'Friendly Buddy';
      case 'professional':
        return 'Professional Guide';
      case 'zen':
        return 'Zen Master';
      default:
        return 'Motivational Coach';
    }
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _VoicePreferencesCard extends StatefulWidget {
  @override
  State<_VoicePreferencesCard> createState() => _VoicePreferencesCardState();
}

class _VoicePreferencesCardState extends State<_VoicePreferencesCard> {
  String? _voiceId;
  String _personality = 'motivational';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await ProfileService.fetchCurrentProfile();
      if (!mounted) return;
      setState(() {
        _voiceId = p?.preferredVoiceId;
        _personality = p?.voicePersonality ?? 'motivational';
      });
    } catch (e) {
      debugPrint('Load voice prefs error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.watch<VoiceCoachProvider>();
    final theme = Theme.of(context);
    final controller = TextEditingController(text: _voiceId ?? vc.voiceId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Voice Preferences', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'ElevenLabs Voice ID'),
            onChanged: (v) => _voiceId = v,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _personality,
            decoration: const InputDecoration(labelText: 'Personality'),
            items: const [
              DropdownMenuItem(value: 'motivational', child: Text('Motivational')),
              DropdownMenuItem(value: 'calm', child: Text('Calm')),
              DropdownMenuItem(value: 'friendly', child: Text('Friendly')),
              DropdownMenuItem(value: 'professional', child: Text('Professional')),
              DropdownMenuItem(value: 'zen', child: Text('Zen')),
            ],
            onChanged: (v) => _personality = v ?? _personality,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      try {
                        await ProfileService.updateVoicePreferences(
                          preferredVoiceId: _voiceId ?? controller.text.trim(),
                          voicePersonality: _personality,
                        );
                        // Update local provider too
                        if ((_voiceId ?? controller.text.trim()).isNotEmpty) {
                          context.read<VoiceCoachProvider>().setVoiceId((_voiceId ?? controller.text.trim()));
                        }
                        context.read<VoiceCoachProvider>().setPersona(_mapToPersona(_personality));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice preferences saved')));
                      } catch (e) {
                        debugPrint('Save voice prefs error: $e');
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
              icon: const Icon(Icons.save),
              label: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          )
        ]),
      ),
    );
  }

  String _mapToPersona(String p) {
    switch (p) {
      case 'motivational':
        return 'Motivational Coach';
      case 'calm':
        return 'Calm Mentor';
      case 'friendly':
        return 'Friendly Buddy';
      case 'professional':
        return 'Professional Guide';
      case 'zen':
        return 'Zen Master';
      default:
        return 'Motivational Coach';
    }
  }
}
