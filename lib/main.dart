import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/firebase_init.dart';
import 'core/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();
  final skipOnboarding = await PreferencesService().isOnboardingComplete();
  runApp(ProviderScope(child: App(skipOnboarding: skipOnboarding)));
}
