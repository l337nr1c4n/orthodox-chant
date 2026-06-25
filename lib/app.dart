import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'features/diagnostics/pitch_test_screen.dart';
import 'features/library/screens/library_screen.dart';
import 'features/lesson/screens/lesson_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/onboarding/screens/calibration_screen.dart';
import 'features/tones/screens/tone_overview_screen.dart';

class App extends ConsumerWidget {
  const App({super.key, required this.skipOnboarding});

  final bool skipOnboarding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Orthodox Chant',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: skipOnboarding ? '/' : '/onboarding',
      routes: {
        '/': (_) => const LibraryScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/calibration': (_) => const CalibrationScreen(),
        '/tone': (ctx) => ToneOverviewScreen(
              toneId: ModalRoute.of(ctx)!.settings.arguments as String,
            ),
        '/lesson': (ctx) => LessonScreen(
              hymnId: ModalRoute.of(ctx)!.settings.arguments as String,
            ),
        '/pitch-test': (_) => const PitchTestScreen(),
      },
    );
  }
}
