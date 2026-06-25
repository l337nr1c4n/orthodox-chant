import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/preferences_service.dart';
import '../models/phrase_result.dart';

const Color _gold = Color(0xFFCFB53B);

/// What the user chose on the result screen, returned via [Navigator.pop].
enum ResultAction { tryAgain, backToHymns }

/// End-of-lesson summary: a star rating, a per-phrase breakdown, and actions
/// to retry or return to the hymn list.
class LessonResultScreen extends StatefulWidget {
  final String hymnId;
  final List<PhraseResult> results;

  const LessonResultScreen({
    super.key,
    required this.hymnId,
    required this.results,
  });

  /// Star rating: 3 = every phrase passed, 2 = at least 60% passed,
  /// 1 = attempted but below 60%, 0 = nothing attempted.
  static int starsFor(List<PhraseResult> results) {
    if (results.isEmpty) return 0;
    final passed = results.where((r) => r.passed).length;
    if (passed == results.length) return 3;
    if (passed / results.length >= 0.6) return 2;
    return 1;
  }

  @override
  State<LessonResultScreen> createState() => _LessonResultScreenState();
}

class _LessonResultScreenState extends State<LessonResultScreen> {
  @override
  void initState() {
    super.initState();
    // A 2- or 3-star run counts as completing the hymn.
    if (LessonResultScreen.starsFor(widget.results) >= 2) {
      PreferencesService().markHymnComplete(widget.hymnId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.results;
    final stars = LessonResultScreen.starsFor(results);
    final passed = results.where((r) => r.passed).length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    Icon(
                      i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: i < stars ? _gold : Colors.white24,
                      size: 48,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '$passed of ${results.length} phrases matched',
                style: GoogleFonts.cinzel(
                  color: _gold,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (_, i) => _PhraseRow(result: results[i]),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(ResultAction.tryAgain),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _gold,
                      side: const BorderSide(color: _gold),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Try Again'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(ResultAction.backToHymns),
                    child: const Text(
                      'Back to Hymns',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhraseRow extends StatelessWidget {
  final PhraseResult result;

  const _PhraseRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final pct = (result.accuracy * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            result.passed ? Icons.check_circle : Icons.cancel,
            color: result.passed ? Colors.greenAccent : Colors.redAccent,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              result.phrase.transliteration,
              style: GoogleFonts.robotoSerif(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            '$pct%',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
