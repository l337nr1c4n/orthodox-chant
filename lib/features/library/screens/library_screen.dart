import 'package:flutter/material.dart';

import '../../tones/data/tone_data.dart';
import '../widgets/hymn_card.dart';

/// The home screen: a selector over the eight tones of the Octoechos. Tone 1
/// is available; the rest are locked "Coming soon" placeholders.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orthodox Chant'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            tooltip: 'Pitch test',
            onPressed: () => Navigator.pushNamed(context, '/pitch-test'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          for (final tone in toneData)
            HymnCard(
              title: tone.greekName,
              subtitle: tone.isAvailable
                  ? '${tone.name} • ${tone.hymns.length} hymns'
                  : tone.name,
              onTap: tone.isAvailable
                  ? () => Navigator.pushNamed(
                        context,
                        '/tone',
                        arguments: tone.id,
                      )
                  : null,
              trailing: tone.isAvailable
                  ? null
                  : const Text(
                      'Coming soon',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
            ),
        ],
      ),
    );
  }
}
