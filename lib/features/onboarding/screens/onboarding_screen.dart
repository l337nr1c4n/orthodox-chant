import 'package:flutter/material.dart';
import '../../../core/preferences_service.dart';
import '../widgets/onboarding_page.dart';

const Color _gold = Color(0xFFCFB53B);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _slides = [
    (
      icon: Icons.music_note,
      title: 'The Sound of Sacred Worship',
      body:
          'Byzantine chant has been sung in Orthodox churches for over a thousand years. This app will teach you to sing it.',
    ),
    (
      icon: Icons.queue_music,
      title: 'Follow the Melody',
      body:
          'Each lesson plays a reference recording. A scrolling track shows the notes — match them with your voice.',
    ),
    (
      icon: Icons.mic,
      title: 'Real-Time Feedback',
      body:
          'As you sing, the track shows a colored bar at your pitch. Green means you\'re right on.',
    ),
    (
      icon: Icons.tune,
      title: "Let's Set Up Your Voice",
      body:
          'First, let\'s find your comfortable singing range so lessons can be adjusted to match.',
    ),
  ];

  void _skip() async {
    await PreferencesService().setOnboardingComplete();
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/calibration');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return OnboardingPage(
                    iconData: slide.icon,
                    title: slide.title,
                    body: slide.body,
                    isLast: i == _slides.length - 1,
                    onNext: _next,
                    onSkip: _skip,
                  );
                },
              ),
            ),
            _PageDots(count: _slides.length, current: _currentPage),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == current ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: i == current ? _gold : Colors.white24,
          ),
        );
      }),
    );
  }
}
