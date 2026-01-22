import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digital_detox_master/providers/detox_provider.dart';
import 'package:digital_detox_master/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:digital_detox_master/nav.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final detox = context.watch<DetoxProvider>();
    final stats = detox.stats;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reality Check'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, 
                  size: 16, 
                  color: theme.colorScheme.onPrimaryContainer
                ),
                const SizedBox(width: 8),
                Text(
                  'Lvl ${stats.level}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: _buildMainStatsCard(context, stats.minutesSaved),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: _buildLifeCalculator(context, stats.minutesSaved),
            ),
            const SizedBox(height: 24),
            Text(
              'Weekly Progress',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: SizedBox(
                height: 200,
                child: _buildChart(context),
              ),
            ),
            const SizedBox(height: 24),
             _buildQuickAction(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStatsCard(BuildContext context, int minutes) {
    final theme = Theme.of(context);
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    return Card(
      elevation: 2,
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Time Reclaimed',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$hours',
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 4),
                  child: Text(
                    'hrs',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$mins',
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 4),
                  child: Text(
                    'min',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLifeCalculator(BuildContext context, int totalMinutes) {
    // 1 book chapter ~= 15 mins
    // 1 workout ~= 30 mins
    // 1 skill lesson ~= 20 mins
    final books = totalMinutes ~/ 15;
    final workouts = totalMinutes ~/ 30;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'What you could have done',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildEquivalenceRow(context, Icons.menu_book, '$books chapters read'),
            const SizedBox(height: 8),
            _buildEquivalenceRow(context, Icons.fitness_center, '$workouts quick workouts'),
          ],
        ),
      ),
    );
  }

  Widget _buildEquivalenceRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 12),
        Text(text, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }

  Widget _buildChart(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 10,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                );
                String text;
                switch (value.toInt()) {
                  case 0: text = 'M'; break;
                  case 1: text = 'T'; break;
                  case 2: text = 'W'; break;
                  case 3: text = 'T'; break;
                  case 4: text = 'F'; break;
                  case 5: text = 'S'; break;
                  case 6: text = 'S'; break;
                  default: text = '';
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(text, style: style),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          _makeGroupData(0, 5, color),
          _makeGroupData(1, 6.5, color),
          _makeGroupData(2, 5, color),
          _makeGroupData(3, 7.5, color),
          _makeGroupData(4, 9, color),
          _makeGroupData(5, 11.5, color), // High usage warning?
          _makeGroupData(6, 6.5, color),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildQuickAction(BuildContext context) {
    return Card(
       color: Theme.of(context).colorScheme.tertiaryContainer,
       child: InkWell(
         onTap: () {
           context.push(AppRoutes.focus);
         },
         child: Padding(
           padding: const EdgeInsets.all(16),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(Icons.timelapse, 
                 color: Theme.of(context).colorScheme.onTertiaryContainer
               ),
               const SizedBox(width: 8),
               Text(
                 'Start Focus Session',
                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
                   color: Theme.of(context).colorScheme.onTertiaryContainer,
                   fontWeight: FontWeight.bold,
                 ),
               ),
             ],
           ),
         ),
       ),
    );
  }
}
