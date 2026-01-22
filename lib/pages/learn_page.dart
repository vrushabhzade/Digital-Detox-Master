import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:digital_detox_master/nav.dart';
import 'package:provider/provider.dart';
import 'package:digital_detox_master/providers/voice_coach_provider.dart';
import 'package:digital_detox_master/voice/elevenlabs_service.dart';

class LearnPage extends StatelessWidget {
  const LearnPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Algorithm Awareness'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AudioInsightCard(),
          const SizedBox(height: 12),
          _ctaCard(context, 'Brain Training Quizzes', 'Turn scrolling urges into 2-minute challenges', Icons.psychology, onTap: () => context.push(AppRoutes.learnBrain)),
          const SizedBox(height: 12),
          _ctaCard(context, 'Math Trainer', 'Speed, accuracy, and confidence with numbers', Icons.calculate, onTap: () => context.push(AppRoutes.learnMath)),
          const SizedBox(height: 16),
          _buildArticleCard(
            context,
            'The Infinite Scroll Trap',
            'How UI designers remove "stopping cues" to keep you scrolling forever.',
            Icons.loop,
            0,
          ),
          _buildArticleCard(
            context,
            'Dopamine Loops',
            'Variable rewards (like a slot machine) make notifications addictive.',
            Icons.notifications_active,
            1,
          ),
          _buildArticleCard(
            context,
            'The Attention Economy',
            'You are not the customer. You are the product being sold to advertisers.',
            Icons.monetization_on,
            2,
          ),
          _buildArticleCard(
            context,
            'Social Comparison',
            'Why everyone else\'s life looks perfect online (and why it makes you sad).',
            Icons.people_outline,
            3,
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, String title, String summary, IconData icon, int index) {
    return FadeInUp(
      delay: Duration(milliseconds: index * 100),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ExpansionTile(
          leading: Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '$summary\n\n(Full article content would go here. This is a reminder to reclaim your attention.)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ctaCard(BuildContext context, String title, String subtitle, IconData icon, {required VoidCallback onTap}) {
    return FadeInUp(
      child: Card(
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

class _AudioInsightCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.graphic_eq, color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text('Daily Insight (Audio)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: const Text('One powerful idea, narrated by your AI coach'),
        trailing: FilledButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('Play'),
          onPressed: () {
            final vc = context.read<VoiceCoachProvider>();
            // Guard: surface clear guidance if ElevenLabs isn't configured
            if (!ElevenLabsTts.instance.isConfigured) {
              _promptConfigureTts(context).then((saved) {
                if (saved == true) {
                  if (!vc.enabled) {
                    _promptEnableCoach(context).then((enabled) {
                      if (enabled == true) {
                        vc.playDailyInsight();
                      }
                    });
                  } else {
                    vc.playDailyInsight();
                  }
                }
              });
              return;
            }
            // If Voice Coach is disabled, allow enabling inline before playing
            if (!vc.enabled) {
              _promptEnableCoach(context).then((enabled) {
                if (enabled == true) {
                  vc.playDailyInsight();
                }
              });
              return;
            }
            vc.playDailyInsight();
          },
        ),
      ),
    );
  }

  Future<bool?> _promptEnableCoach(BuildContext context) async {
    bool tempEnabled = false;
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final vc = ctx.read<VoiceCoachProvider>();
        tempEnabled = vc.enabled;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enable AI Voice Coach to play insights', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              SwitchListTile(
                value: tempEnabled,
                onChanged: (v) {
                  tempEnabled = v;
                  ctx.read<VoiceCoachProvider>().enabled = v;
                },
                title: const Text('AI Voice Coach'),
                secondary: const Icon(Icons.record_voice_over),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => ctx.pop(tempEnabled),
                  icon: const Icon(Icons.check),
                  label: const Text('Continue'),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _promptConfigureTts(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final apiController = TextEditingController();
    final urlController = TextEditingController(text: 'https://api.elevenlabs.io');

    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final insets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: insets.bottom + 16),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Configure Text-to-Speech', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('Paste your ElevenLabs API key. This is stored locally on your device for playback. For production apps, avoid embedding secrets in the client.'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: apiController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'ElevenLabs API Key',
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'API key is required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'Base URL (optional)',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      try {
                        await ElevenLabsTts.instance.persistApiConfig(apiKey: apiController.text, baseUrl: urlController.text);
                        if (ctx.mounted) ctx.pop(true);
                      } catch (e) {
                        debugPrint('Persist TTS config error: $e');
                        if (ctx.mounted) ctx.pop(false);
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save & Continue'),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
