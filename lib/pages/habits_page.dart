import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digital_detox_master/models/detox_models.dart';
import 'package:digital_detox_master/providers/detox_provider.dart';
import 'package:animate_do/animate_do.dart';

class HabitsPage extends StatelessWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<DetoxProvider>().habits;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Builder'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUrgeDialog(context),
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
        icon: const Icon(Icons.sos),
        label: const Text('I have an urge!'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: habits.length,
        separatorBuilder: (c, i) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final habit = habits[index];
          return FadeInLeft(
            delay: Duration(milliseconds: index * 100),
            child: _buildHabitCard(context, habit),
          );
        },
      ),
    );
  }

  Widget _buildHabitCard(BuildContext context, Habit habit) {
    final theme = Theme.of(context);
    final isDone = habit.isCompletedToday;

    return Card(
      elevation: 0,
      color: isDone 
          ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5) 
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isDone ? Colors.green.withOpacity(0.2) : theme.colorScheme.primaryContainer,
          child: Icon(
            isDone ? Icons.check : Icons.local_florist,
            color: isDone ? Colors.green : theme.colorScheme.primary,
          ),
        ),
        title: Text(
          habit.title,
          style: theme.textTheme.titleMedium?.copyWith(
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? theme.textTheme.bodyMedium?.color?.withOpacity(0.5) : null,
          ),
        ),
        subtitle: Text(
          '${habit.durationMinutes} min • ${habit.category}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: isDone
            ? null
            : ElevatedButton(
                onPressed: () {
                  context.read<DetoxProvider>().completeHabit(habit.id);
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                ),
                child: const Text('Do it'),
              ),
      ),
    );
  }

  void _showUrgeDialog(BuildContext context) {
    final habits = context.read<DetoxProvider>().habits;
    if (habits.isEmpty) return;
    
    final randomHabit = habits[Random().nextInt(habits.length)];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause. Breathe.'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Before you scroll, try this instead:'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                randomHabit.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Text('Only ${randomHabit.durationMinutes} minutes.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ignore'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<DetoxProvider>().completeHabit(randomHabit.id);
            },
            child: const Text('I did it!'),
          ),
        ],
      ),
    );
  }
}
