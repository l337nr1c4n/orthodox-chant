import 'package:flutter/material.dart';
import '../models/chant_phrase.dart';

class PhraseDisplayWidget extends StatefulWidget {
  final List<ChantPhrase> phrases;
  final int currentIndex;

  const PhraseDisplayWidget({
    super.key,
    required this.phrases,
    required this.currentIndex,
  });

  @override
  State<PhraseDisplayWidget> createState() => _PhraseDisplayWidgetState();
}

class _PhraseDisplayWidgetState extends State<PhraseDisplayWidget> {
  late final List<GlobalKey> _keys;

  @override
  void initState() {
    super.initState();
    _keys = List.generate(widget.phrases.length, (_) => GlobalKey());
  }

  @override
  void didUpdateWidget(PhraseDisplayWidget old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final idx = widget.currentIndex;
        if (idx < _keys.length) {
          final ctx = _keys[idx].currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: 0.5,
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFCFB53B);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.phrases.length, (i) {
          final isActive = i == widget.currentIndex;
          return Padding(
            key: _keys[i],
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isActive ? 40 : 28,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? gold : Colors.white54,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.phrases[i].greek),
                  Text(
                    widget.phrases[i].transliteration,
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
