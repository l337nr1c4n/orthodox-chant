import 'package:flutter/material.dart';
import '../models/chant_phrase.dart';

class PhraseDisplayWidget extends StatelessWidget {
  final List<ChantPhrase> phrases;
  final int currentIndex;

  const PhraseDisplayWidget({
    super.key,
    required this.phrases,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFCFB53B);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(phrases.length, (i) {
          final isActive = i == currentIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isActive ? 40 : 28,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? gold : Colors.white54,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(phrases[i].greek),
                  Text(
                    phrases[i].transliteration,
                    style: TextStyle(
                      fontSize: isActive ? 14 : 10,
                      color: isActive ? gold.withAlpha(200) : Colors.white30,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
