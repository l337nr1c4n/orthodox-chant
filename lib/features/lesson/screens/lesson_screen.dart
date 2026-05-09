import 'package:flutter/material.dart';

// Phase 3 — stub
class LessonScreen extends StatelessWidget {
  final String hymnId;

  const LessonScreen({super.key, required this.hymnId});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(hymnId)),
        body: const Center(child: Text('Lesson — coming in Phase 3')),
      );
}
