import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/note_utils.dart';
import '../../../core/preferences_service.dart';
import '../../../shared/pitch_service.dart';

const Color _gold = Color(0xFFCFB53B);

enum _CalibState { idle, recording, done }

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen>
    with TickerProviderStateMixin {
  _CalibState _state = _CalibState.idle;
  String? _liveNote;
  String? _resultNote;
  String? _errorMessage;

  final _pitchService = PitchService();
  final List<String> _collectedNotes = [];
  StreamSubscription<String?>? _noteSub;

  late final AnimationController _pulseController;
  late final AnimationController _countdownController;
  late final Animation<double> _pulseAnim;

  static const _recordDuration = Duration(seconds: 5);
  // Baseline MIDI: D4 = 62 (most common Tone 1 target note)
  static const _baselineMidi = 62;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _countdownController = AnimationController(
      vsync: this,
      duration: _recordDuration,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownController.dispose();
    _noteSub?.cancel();
    _pitchService.stop();
    super.dispose();
  }

  Future<void> _startCalibration() async {
    final status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() => _errorMessage = 'Microphone permission is required.');
      return;
    }

    setState(() {
      _state = _CalibState.recording;
      _liveNote = null;
      _collectedNotes.clear();
      _errorMessage = null;
    });

    await _pitchService.start();
    _countdownController.forward(from: 0);

    _noteSub = _pitchService.noteStream.listen((note) {
      if (note != null) {
        setState(() => _liveNote = note);
        _collectedNotes.add(note);
      }
    });

    await Future.delayed(_recordDuration);
    await _finishCalibration();
  }

  Future<void> _finishCalibration() async {
    await _noteSub?.cancel();
    await _pitchService.stop();

    if (_collectedNotes.isEmpty) {
      setState(() {
        _state = _CalibState.idle;
        _errorMessage = 'No voice detected. Make sure your mic is on and try again.';
      });
      return;
    }

    final midis = _collectedNotes.map(noteToMidi).whereType<int>().toList()..sort();
    final median = midis[midis.length ~/ 2];
    final offset = (median - _baselineMidi).clamp(-24, 24);

    final prefs = PreferencesService();
    await prefs.setVoiceOffset(offset);
    await prefs.setOnboardingComplete();

    final resultNote = midiToNoteName(median);
    setState(() {
      _state = _CalibState.done;
      _resultNote = resultNote;
    });
  }

  void _startLearning() {
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: switch (_state) {
            _CalibState.idle => _buildIdle(),
            _CalibState.recording => _buildRecording(),
            _CalibState.done => _buildDone(),
          },
        ),
      ),
    );
  }

  Widget _buildIdle() {
    return Column(
      children: [
        const Spacer(flex: 2),
        Text(
          'Find Your Voice',
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(
            color: _gold,
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Hum any comfortable note and hold it steady for a few seconds. The app will detect your natural singing range.',
          textAlign: TextAlign.center,
          style: GoogleFonts.robotoSerif(
            color: Colors.white70,
            fontSize: 15,
            height: 1.6,
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 20),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.robotoSerif(color: Colors.redAccent, fontSize: 13),
          ),
        ],
        const Spacer(flex: 2),
        ScaleTransition(
          scale: _pulseAnim,
          child: _MicButton(onTap: _startCalibration),
        ),
        const SizedBox(height: 16),
        Text(
          'Tap to begin',
          style: GoogleFonts.robotoSerif(color: Colors.white38, fontSize: 13),
        ),
        const Spacer(flex: 3),
        TextButton(
          onPressed: () async {
            await PreferencesService().setOnboardingComplete();
            if (mounted) Navigator.pushReplacementNamed(context, '/');
          },
          child: Text(
            'Skip for now',
            style: GoogleFonts.robotoSerif(color: Colors.white38),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildRecording() {
    return Column(
      children: [
        const Spacer(flex: 2),
        Text(
          'Keep humming...',
          style: GoogleFonts.cinzel(
            color: _gold,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(flex: 2),
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _countdownController,
                builder: (context, _) => CircularProgressIndicator(
                  value: 1 - _countdownController.value,
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  color: _gold,
                  backgroundColor: Colors.white12,
                ),
              ),
              Text(
                _liveNote ?? '—',
                style: GoogleFonts.cinzel(
                  color: _gold,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Spacer(flex: 3),
      ],
    );
  }

  Widget _buildDone() {
    return Column(
      children: [
        const Spacer(flex: 2),
        const Icon(Icons.check_circle_outline, size: 64, color: _gold),
        const SizedBox(height: 32),
        Text(
          'Your voice center:',
          style: GoogleFonts.robotoSerif(color: Colors.white54, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Text(
          _resultNote ?? '—',
          style: GoogleFonts.cinzel(
            color: _gold,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Lessons have been adjusted to match your voice.',
          textAlign: TextAlign.center,
          style: GoogleFonts.robotoSerif(
            color: Colors.white70,
            fontSize: 15,
            height: 1.6,
          ),
        ),
        const Spacer(flex: 3),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _startLearning,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Start Learning'),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _gold,
          boxShadow: [
            BoxShadow(
              color: _gold.withAlpha(60),
              blurRadius: 24,
              spreadRadius: 8,
            ),
          ],
        ),
        child: const Icon(Icons.mic, size: 48, color: Colors.black),
      ),
    );
  }
}
