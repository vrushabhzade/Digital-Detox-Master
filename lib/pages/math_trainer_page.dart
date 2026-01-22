import 'package:flutter/material.dart';

class MathTrainerPage extends StatefulWidget {
  const MathTrainerPage({super.key});

  @override
  State<MathTrainerPage> createState() => _MathTrainerPageState();
}

class _MathTrainerPageState extends State<MathTrainerPage> {
  String _difficulty = 'Beginner';
  int _current = 0; int _score = 0; bool _done = false;

  List<_MathQ> get _questions {
    switch (_difficulty) {
      case 'Intermediate':
        return [
          _MathQ('47 + 68 = ?', ['105', '107', '115', '125'], 2, '47 + 68 = 115'),
          _MathQ('A \$120 item is 25% off. Final price?', ['\$80', '\$85', '\$90', '\$95'], 1, '25% of 120 is 30. 120 - 30 = 90'),
          _MathQ('If 3x + 7 = 22, x = ?', ['3', '4', '5', '6'], 1, '3x = 15, x = 5'),
        ];
      case 'Advanced':
        return [
          _MathQ('Next prime after 17?', ['18', '19', '21', '23'], 1, '19 is the next prime'),
          _MathQ('Roll two dice. P(sum=7)?', ['1/12', '1/6', '5/36', '1/36'], 2, 'Combinations: 6 (1-6, 2-5...). 6/36 = 1/6'),
          _MathQ('\$1000 at 5% simple interest for 3 years?', ['\$1050', '\$1150', '\$1500', '\$1005'], 1, 'I = PRT = 1000*0.05*3 = 150; 1000+150=1150'),
        ];
      default:
        return [
          _MathQ('17 × 4 = ?', ['48', '64', '68', '72'], 2, '17*4 = 68'),
          _MathQ('A rectangular room 15ft × 12ft. Area?', ['180', '160', '200', '225'], 0, 'Area = 15*12 = 180'),
          _MathQ('47 + 68 = ?', ['105', '107', '115', '125'], 2, '47 + 68 = 115'),
        ];
    }
  }

  void _selectDifficulty(String d) {
    setState(() { _difficulty = d; _current = 0; _score = 0; _done = false; });
  }

  void _answer(int i) {
    if (_done) return;
    final q = _questions[_current];
    final correct = i == q.answer;
    if (correct) _score++;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(correct ? Icons.check_circle : Icons.cancel, color: correct ? Colors.green : Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Text(correct ? 'Correct' : 'Incorrect', style: Theme.of(context).textTheme.titleLarge),
            ]),
            const SizedBox(height: 8),
            Text(q.explain, style: Theme.of(context).textTheme.bodyMedium),
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
                      _done = true;
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Math Trainer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text('Difficulty:', style: theme.textTheme.titleMedium),
              const SizedBox(width: 8),
              Wrap(spacing: 8, children: [
                ChoiceChip(label: const Text('Beginner'), selected: _difficulty=='Beginner', onSelected: (_) => _selectDifficulty('Beginner')),
                ChoiceChip(label: const Text('Intermediate'), selected: _difficulty=='Intermediate', onSelected: (_) => _selectDifficulty('Intermediate')),
                ChoiceChip(label: const Text('Advanced'), selected: _difficulty=='Advanced', onSelected: (_) => _selectDifficulty('Advanced')),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          if (_done)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Icon(Icons.emoji_events, color: theme.colorScheme.primary), const SizedBox(width: 8), Text('Set Complete', style: theme.textTheme.titleLarge)]),
                  const SizedBox(height: 8),
                  Text('Score: $_score / ${_questions.length}', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: () => _selectDifficulty(_difficulty), icon: const Icon(Icons.refresh), label: const Text('Retry')), 
                ]),
              ),
            ),
          if (!_done) _MathCard(q: _questions[_current], index: _current, total: _questions.length, onSelect: _answer),
          const SizedBox(height: 16),
          Text('Categories', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: const [
            _Cat(label: 'Mental Arithmetic', icon: Icons.calculate),
            _Cat(label: 'Percentages & Ratios', icon: Icons.percent),
            _Cat(label: 'Algebra', icon: Icons.functions),
            _Cat(label: 'Geometry', icon: Icons.square_foot),
            _Cat(label: 'Patterns', icon: Icons.show_chart),
            _Cat(label: 'Probability', icon: Icons.casino),
            _Cat(label: 'Finance', icon: Icons.attach_money),
          ]),
        ],
      ),
    );
  }
}

class _MathCard extends StatelessWidget {
  final _MathQ q; final int index; final int total; final void Function(int) onSelect;
  const _MathCard({required this.q, required this.index, required this.total, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: theme.colorScheme.tertiaryContainer, child: Text((index+1).toString(), style: TextStyle(color: theme.colorScheme.onTertiaryContainer))),
            const SizedBox(width: 8),
            Text('Question', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const Spacer(),
            Text('${index+1} / $total', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),
          const SizedBox(height: 12),
          Text(q.prompt, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          ...List.generate(q.choices.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              onPressed: () => onSelect(i),
              icon: const Icon(Icons.help_outline),
              label: Align(alignment: Alignment.centerLeft, child: Text(q.choices[i])),
            ),
          )),
        ]),
      ),
    );
  }
}

class _Cat extends StatelessWidget { final String label; final IconData icon; const _Cat({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 18, color: theme.colorScheme.onSecondaryContainer),
      label: Text(label),
      backgroundColor: theme.colorScheme.secondaryContainer,
      labelStyle: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSecondaryContainer),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _MathQ {
  final String prompt; final List<String> choices; final int answer; final String explain;
  const _MathQ(this.prompt, this.choices, this.answer, this.explain);
}
