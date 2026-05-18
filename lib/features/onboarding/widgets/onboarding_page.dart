import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _gold = Color(0xFFCFB53B);

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.iconData,
    required this.title,
    required this.body,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
  });

  final IconData iconData;
  final String title;
  final String body;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _GlowIcon(iconData: iconData),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              color: _gold,
              fontSize: 26,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            body,
            textAlign: TextAlign.center,
            style: GoogleFonts.robotoSerif(
              color: Colors.white70,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const Spacer(flex: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onSkip,
                child: Text(
                  'Skip',
                  style: GoogleFonts.robotoSerif(color: Colors.white38),
                ),
              ),
              ElevatedButton(
                onPressed: onNext,
                child: Text(isLast ? 'Set Up My Voice' : 'Next'),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _GlowIcon extends StatelessWidget {
  const _GlowIcon({required this.iconData});

  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gold.withAlpha(20),
            ),
          ),
          Icon(iconData, size: 72, color: _gold),
        ],
      ),
    );
  }
}
