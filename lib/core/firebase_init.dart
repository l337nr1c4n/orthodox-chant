import 'package:firebase_core/firebase_core.dart';

Future<void> initFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}
