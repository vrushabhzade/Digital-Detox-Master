import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digital_detox_master/widgets/focus_timer.dart';
import 'package:digital_detox_master/providers/voice_coach_provider.dart';

class FocusTimerPage extends StatelessWidget {
  const FocusTimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Focus Session')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _VoiceCoachControls(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Time-Bound Tracker', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Pomodoro cycles with gentle nudges and session protection', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  const FocusTimer(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatCard(icon: Icons.timelapse, title: 'Today Focus', value: '0.0 hr')),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(icon: Icons.local_fire_department, title: 'Streak', value: '0 days')),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tips', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('• Protect the session: silence notifications\n• Keep a clear goal for the block\n• Take a short walk during breaks', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon; final String title; final String value;
  const _StatCard({required this.icon, required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceCoachControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vc = context.watch<VoiceCoachProvider>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.record_voice_over, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Voice Coach', style: theme.textTheme.titleMedium),
                  Text(vc.enabled ? vc.personaKey : 'Disabled', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Switch(
              value: vc.enabled,
              onChanged: (v) => context.read<VoiceCoachProvider>().enabled = v,
            ),
            IconButton(
              tooltip: 'Voice settings',
              icon: const Icon(Icons.tune),
              onPressed: () => _openVoiceSettings(context),
            ),
          ],
        ),
      ),
    );
  }

  void _openVoiceSettings(BuildContext context) {
    final vc = context.read<VoiceCoachProvider>();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        var coachName = vc.coachName;
        var voiceId = vc.voiceId;
        var selected = vc.personaKey;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Voice Settings', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Coach will call you…'),
                controller: TextEditingController(text: coachName),
                onChanged: (v) => coachName = v,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Voice ID (ElevenLabs)'),
                controller: TextEditingController(text: voiceId),
                onChanged: (v) => voiceId = v,
              ),
              const SizedBox(height: 12),
              Text('Persona', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...vc.personas.keys.map((k) => RadioListTile<String>(
                    title: Text(k),
                    value: k,
                    groupValue: selected,
                    onChanged: (v) => selected = v ?? selected,
                  )),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                  onPressed: () {
                    vc.coachName = coachName;
                    vc.setVoiceId(voiceId);
                    vc.setPersona(selected);
                    Navigator.of(context).pop();
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
