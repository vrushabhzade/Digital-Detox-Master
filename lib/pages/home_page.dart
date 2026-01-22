import 'package:flutter/material.dart';
import 'package:digital_detox_master/theme.dart';

/// The app's landing page.
/// Uses Material 3 theming and minimal layout to start.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Home', style: context.textStyles.titleLarge?.semiBold),
      ),
      body: Center(
        child: Card(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_top, size: 48, color: colors.primary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Digital Detox Master',
                  style: context.textStyles.headlineSmall?.semiBold,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your compassionate guide to reclaiming focus and joy.',
                  style: context.textStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
