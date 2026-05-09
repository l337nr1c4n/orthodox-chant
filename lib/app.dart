import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'features/library/screens/library_screen.dart';
import 'features/lesson/screens/lesson_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Orthodox Chant',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: '/',
      routes: {
        '/': (_) => const LibraryScreen(),
        '/lesson': (ctx) => LessonScreen(
              hymnId: ModalRoute.of(ctx)!.settings.arguments as String,
            ),
      },
    );
  }
}
