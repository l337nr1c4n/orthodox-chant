import 'package:flutter/material.dart';

const Color _gold = Color(0xFFCFB53B);

/// A tappable card used for both tone chapters (in the library) and hymns
/// (in the tone overview).
///
/// [leading] and [trailing] override the default gold stripe and chevron.
/// A null [onTap] renders the card disabled/locked (dimmed, non-interactive) —
/// used for "Coming soon" tones.
class HymnCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;

  const HymnCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              leading ??
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _gold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing ?? const Icon(Icons.chevron_right, color: _gold),
            ],
          ),
        ),
      ),
    );

    // A locked card (no onTap) is dimmed and ignores touches.
    if (onTap == null) {
      return Opacity(
        opacity: 0.45,
        child: IgnorePointer(child: card),
      );
    }
    return card;
  }
}
