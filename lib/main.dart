import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digital_detox_master/theme.dart';
import 'package:digital_detox_master/nav.dart';
import 'package:digital_detox_master/providers/detox_provider.dart';
import 'package:digital_detox_master/providers/voice_coach_provider.dart';
import 'package:digital_detox_master/supabase/supabase_config.dart';

/// Main entry point for the application
///
/// This sets up:
/// - Provider state management (ThemeProvider, CounterProvider)
/// - go_router navigation
/// - Material 3 theming with light/dark modes
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Supabase client before running the app
  await SupabaseConfig.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider wraps the app to provide state to all widgets
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DetoxProvider()),
        ChangeNotifierProvider(create: (_) => VoiceCoachProvider()),
      ],
      child: MaterialApp.router(
        title: 'Digital Detox Master',
        debugShowCheckedModeBanner: false,

        // Theme configuration
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,

        // Use context.go() or context.push() to navigate to the routes.
        routerConfig: AppRouter.router,
      ),
    );
  }
}
