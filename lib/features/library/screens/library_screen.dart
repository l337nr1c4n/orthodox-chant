import 'package:flutter/material.dart';
import '../widgets/hymn_card.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  static const _hymns = [
    (
      id: 'tone1_kyrie',
      title: 'Κύριε ἐλέησον',
      subtitle: 'Kyrie Eleison • Tone 1 • 7 phrases',
    ),
    (
      id: 'tone1_trisagion',
      title: 'Ἅγιος ὁ Θεός',
      subtitle: 'Trisagion • Tone 1 • 25 phrases',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orthodox Chant'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: _hymns
            .map(
              (h) => HymnCard(
                title: h.title,
                subtitle: h.subtitle,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/lesson',
                  arguments: h.id,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
