import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digital_detox_master/providers/voice_coach_provider.dart';

class BrainTrainingPage extends StatefulWidget {
  const BrainTrainingPage({super.key});

  @override
  State<BrainTrainingPage> createState() => _BrainTrainingPageState();
}

class _BrainTrainingPageState extends State<BrainTrainingPage> {
  int _current = 0;
  int _score = 0;
  bool _completed = false;

  final List<_Question> _questions = [
    _Question(
      category: 'Logical Reasoning',
      prompt: 'All birds can fly. Penguins are birds. Can penguins fly?',
      choices: ['Yes', 'No', 'Only young penguins', 'Sometimes'],
      answerIndex: 1,
      explanation: 'This is a syllogism with an exception; the premise is flawed. Penguins are flightless birds.',
    ),
    _Question(
      category: 'Pattern Recognition',
      prompt: '2, 4, 8, 16, ?, 64',
      choices: ['20', '24', '30', '32'],
      answerIndex: 3,
      explanation: 'Powers of two. The missing number is 32.',
    ),
    _Question(
      category: 'Memory',
      prompt: 'Sequence: 7-3-9-1-5. What was the third number?',
      choices: ['3', '5', '7', '9'],
      answerIndex: 3,
      explanation: 'The third number is 9.',
    ),
  ];

  void _answer(int index) {
    if (_completed) return;
    final q = _questions[_current];
    final correct = index == q.answerIndex;
    if (correct) _score++;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(correct ? Icons.check_circle : Icons.cancel, color: correct ? Colors.green : Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Text(correct ? 'Correct!' : 'Not quite', style: Theme.of(context).textTheme.titleLarge),
            ]),
            const SizedBox(height: 8),
            Text(q.explanation, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    if (_current < _questions.length - 1) {
                      _current++;
                    } else {
                      _completed = true;
                    }
                  });
                },
                child: Text(_current < _questions.length - 1 ? 'Next' : 'Finish'),
              ),
            ),
          ],
        ),
      ),
    );
    // Speak feedback softly
    final vc = context.read<VoiceCoachProvider>();
    final feedback = correct
        ? 'Nice! That\'s correct. ${q.explanation}'
        : 'Close. ${q.explanation}';
    vc.speak(feedback);
  }

  void _resetQuiz() {
    setState(() { _current = 0; _score = 0; _completed = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Brain Training')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_completed)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.emoji_events, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Daily Challenge Complete', style: theme.textTheme.titleLarge),
                    ]),
                    const SizedBox(height: 8),
                    Text('Score: $_score / ${_questions.length}', style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 12),
                    FilledButton.icon(onPressed: _resetQuiz, icon: const Icon(Icons.refresh), label: const Text('Try Again')),
                  ],
                ),
              ),
            ),
          if (!_completed) _QuestionCard(question: _questions[_current], index: _current, total: _questions.length, onSelect: _answer),
          const SizedBox(height: 16),
          Text('Categories', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _CategoryChip(label: 'Logical Reasoning', icon: Icons.timeline),
              _CategoryChip(label: 'Pattern Recognition', icon: Icons.grid_on),
              _CategoryChip(label: 'Memory', icon: Icons.memory),
              _CategoryChip(label: 'Critical Thinking', icon: Icons.psychology),
              _CategoryChip(label: 'Creative Thinking', icon: Icons.lightbulb),
              _CategoryChip(label: 'Speed Processing', icon: Icons.bolt),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final _Question question; final int index; final int total; final void Function(int) onSelect;
  const _QuestionCard({required this.question, required this.index, required this.total, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(backgroundColor: theme.colorScheme.primaryContainer, child: Text((index + 1).toString(), style: TextStyle(color: theme.colorScheme.onPrimaryContainer))),
              const SizedBox(width: 8),
              Text(question.category, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              Text('${index + 1} / $total', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              IconButton(
                tooltip: 'Play via AI voice',
                icon: const Icon(Icons.volume_up),
                onPressed: () {
                  final vc = context.read<VoiceCoachProvider>();
                  vc.speak('Let\'s activate your brain. ${question.prompt}');
                },
              ),
            ]),
            const SizedBox(height: 12),
            Text(question.prompt, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ...List.generate(question.choices.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                onPressed: () => onSelect(i),
                icon: const Icon(Icons.help_outline),
                label: Align(alignment: Alignment.centerLeft, child: Text(question.choices[i])),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label; final IconData icon; const _CategoryChip({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 18, color: theme.colorScheme.onPrimaryContainer),
      label: Text(label),
      backgroundColor: theme.colorScheme.primaryContainer,
      labelStyle: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _Question {
  final String category; final String prompt; final List<String> choices; final int answerIndex; final String explanation;
  const _Question({required this.category, required this.prompt, required this.choices, required this.answerIndex, required this.explanation});
}
