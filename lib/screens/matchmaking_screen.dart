import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../state/session_state.dart';
import '../state/match_provider.dart';
import '../widgets/cartoon_background.dart';
import '../widgets/cartoon_button.dart';
import '../widgets/mascot_widget.dart';
import 'multiplayer_gameplay_screen.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _elapsedTimer;
  int _secondsSearching = 0;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _secondsSearching++);
    });

    final matchProvider = context.read<MatchProvider>();
    matchProvider.addListener(_onMatchStateChanged);
    matchProvider.joinMatchmaking();
  }

  void _onMatchStateChanged() {
    final matchProvider = context.read<MatchProvider>();
    if (!_navigated && matchProvider.status == MatchmakingStatus.active) {
      _navigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MultiplayerGameplayScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _elapsedTimer?.cancel();
    context.read<MatchProvider>().removeListener(_onMatchStateChanged);
    super.dispose();
  }

  void _cancel() {
    context.read<MatchProvider>().cancelMatchmaking();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final rating = context.watch<SessionState>().profile?.rating ?? 1200;

    return Scaffold(
      body: CartoonBackground(
        mode: CartoonBackgroundMode.matchmaking,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 24, color: AppColors.textPrimaryLight),
                    onPressed: _cancel,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Radar Ring around Searching Explorer Mascot
                    RotationTransition(
                      turns: _controller,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryYellow.withAlpha(120), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryYellow.withAlpha(50),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: MascotWidget(
                            pose: MascotPose.searching,
                            size: 100,
                            autoAnimate: false,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'SEARCHING FOR OPPONENT',
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Matching skill rating ($rating MMR) • ${_secondsSearching}s',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: CartoonButton(
                  text: 'CANCEL MATCHMAKING',
                  onPressed: _cancel,
                  variant: CartoonButtonVariant.outline,
                  width: double.infinity,
                  height: 52,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
