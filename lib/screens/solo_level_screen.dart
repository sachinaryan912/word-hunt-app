import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_search_grid.dart';
import '../theme/app_colors.dart';
import '../services/ads_service.dart';
import '../services/api_client.dart';
import '../services/solo_board_generator.dart';
import '../services/sound_service.dart';
import '../state/session_state.dart';
import '../widgets/cartoon_background.dart';
import '../widgets/cartoon_button.dart';
import '../widgets/cartoon_dialog.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/letter_grid_widget.dart';
import '../widgets/mascot_widget.dart';
import '../widgets/word_list_view.dart';
import 'match_result_screen.dart';

class SoloLevelScreen extends StatefulWidget {
  final DailyChallengeDto? dailyChallenge;

  const SoloLevelScreen({super.key, this.dailyChallenge});

  @override
  State<SoloLevelScreen> createState() => _SoloLevelScreenState();
}

class _SoloLevelScreenState extends State<SoloLevelScreen> {
  late WordSearchGrid _grid;
  int _currentLevel = 1;
  bool _isReady = false;
  int _secondsElapsed = 0;
  Timer? _timer;
  int _hintsRemaining = 3;
  late ConfettiController _confettiController;
  bool _showScorePopup = false;
  String _foundToastWord = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _initLevel();
  }

  Future<void> _initLevel() async {
    if (widget.dailyChallenge != null) {
      _grid = widget.dailyChallenge!.board;
    } else {
      final prefs = await SharedPreferences.getInstance();
      _currentLevel = prefs.getInt('currentLevel') ?? 1;
      _grid = SoloBoardGenerator.generate(_currentLevel);
    }
    if (!mounted) return;
    setState(() => _isReady = true);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final limit = widget.dailyChallenge?.timeLimitSeconds;
      if (limit != null && _secondsElapsed + 1 >= limit) {
        setState(() => _secondsElapsed = limit);
        _timer?.cancel();
        _completeLevel();
        return;
      }
      setState(() => _secondsElapsed++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _onWordSelect(String word, List<GridPos> path) {
    final upperWord = word.toUpperCase();
    final reversedWord = upperWord.split('').reversed.join();

    String? matchedTarget;
    if (_grid.targetWords.contains(upperWord)) {
      matchedTarget = upperWord;
    } else if (_grid.targetWords.contains(reversedWord)) {
      matchedTarget = reversedWord;
    }

    if (matchedTarget != null) {
      final alreadyFound = _grid.foundWords.any((f) => f.word == matchedTarget);
      if (!alreadyFound) {
        setState(() {
          final updatedFound = List<FoundWordPath>.from(_grid.foundWords)
            ..add(FoundWordPath(word: matchedTarget!, path: path, claimedBy: 'player'));
          _grid = _grid.copyWith(foundWords: updatedFound);
          _foundToastWord = matchedTarget;
          _showScorePopup = true;
        });

        context.read<SoundService>().playWordFoundSound();
        _confettiController.play();

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _showScorePopup = false);
        });

        if (_grid.foundWords.length == _grid.targetWords.length) {
          _timer?.cancel();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _completeLevel();
          });
        }
      }
    }
  }

  void _useHint() {
    if (_hintsRemaining > 0) {
      setState(() => _hintsRemaining--);
      final unfound = _grid.targetWords
          .where((t) => !_grid.foundWords.any((f) => f.word == t))
          .toList();
      if (unfound.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const MascotWidget(pose: MascotPose.thinking, size: 28, autoAnimate: false),
                const SizedBox(width: 10),
                Text('Wordy Hint: Look for "${unfound.first.substring(0, 2)}..."', style: GoogleFonts.fredoka(color: Colors.black)),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.primaryYellow,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    }
  }

  void _showPauseDialog() {
    _timer?.cancel();
    context.read<SoundService>().pauseBackgroundMusic();
    CartoonDialog.show(
      context: context,
      mascotPose: MascotPose.idle,
      title: 'MATCH PAUSED',
      subtitle: 'Elapsed Time: ${_formatTime(_secondsElapsed)}',
      primaryButtonText: 'RESUME',
      onPrimaryPressed: () {
        Navigator.of(context).pop();
        _startTimer();
        context.read<SoundService>().resumeBackgroundMusic();
      },
      secondaryButtonText: 'QUIT LEVEL',
      onSecondaryPressed: () {
        Navigator.of(context).pop();
        context.read<SoundService>().resumeBackgroundMusic();
        Navigator.of(context).pop();
      },
    );
  }

  Future<void> _completeLevel() async {
    if (_isSubmitting) return;
    _isSubmitting = true;

    final wordsFound = _grid.foundWords.length;
    final targetWordCount = _grid.targetWords.length;
    final hintsUsed = 3 - _hintsRemaining;

    int score = wordsFound * 60;
    int accuracy = 100;

    final apiClient = context.read<ApiClient>();
    final isDaily = widget.dailyChallenge != null;

    try {
      if (isDaily) {
        final result = await apiClient.completeDailyChallenge(
          wordsFound: wordsFound,
          timeSeconds: _secondsElapsed,
          hintsUsed: hintsUsed,
        );
        score = result.score;
        accuracy = result.accuracy;
        if (mounted) context.read<SessionState>().applyProfile(result.profile);
      } else {
        final result = await apiClient.soloComplete(
          level: _currentLevel,
          wordsFound: wordsFound,
          targetWordCount: targetWordCount,
          timeSeconds: _secondsElapsed,
          hintsUsed: hintsUsed,
        );
        score = result.score;
        accuracy = result.accuracy;
        if (mounted) context.read<SessionState>().applyProfile(result.profile);
      }
    } catch (_) {
      // Offline fallback
    }

    if (!isDaily) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('currentLevel', _currentLevel + 1);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MatchResultScreen(
          isWin: true,
          score: score,
          wordsFoundCount: wordsFound,
          accuracyPercent: accuracy,
          durationSeconds: _secondsElapsed,
          opponentName: null,
          isDailyChallenge: isDaily,
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Scaffold(
        body: CartoonBackground(
          mode: CartoonBackgroundMode.loading,
          child: const Center(child: MascotWidget(pose: MascotPose.searching, size: 90)),
        ),
      );
    }

    return Scaffold(
      body: CartoonBackground(
        mode: CartoonBackgroundMode.gameplay,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Top Bar Game HUD Panel
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceCardDark,
                      border: Border(bottom: BorderSide(color: AppColors.surfaceBorderDark, width: 2.0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.arrowLeft, size: 20, color: AppColors.textPrimaryLight),
                          onPressed: _showPauseDialog,
                        ),

                        Column(
                          children: [
                            Text(
                              widget.dailyChallenge != null ? 'DAILY CHALLENGE' : 'LEVEL $_currentLevel',
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: AppColors.primaryYellow,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(LucideIcons.clock, size: 14, color: AppColors.skyBlue),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTime(_secondsElapsed),
                                  style: GoogleFonts.fredoka(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        IconButton(
                          icon: const Icon(LucideIcons.pause, size: 20, color: AppColors.textPrimaryLight),
                          onPressed: _showPauseDialog,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Letter Grid Hero
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LetterGridWidget(
                      grid: _grid,
                      onWordSelect: _onWordSelect,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Words to Find
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Text(
                            'WORDS TO FIND (${_grid.foundWords.length}/${_grid.targetWords.length})',
                            style: GoogleFonts.fredoka(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                          const SizedBox(height: 12),
                          WordListView(
                            targetWords: _grid.targetWords,
                            foundWords: _grid.foundWords,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Hints & Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CartoonButton(
                          text: 'HINT ($_hintsRemaining)',
                          icon: LucideIcons.lightbulb,
                          onPressed: _hintsRemaining > 0 ? _useHint : null,
                          variant: CartoonButtonVariant.primary,
                          height: 44,
                          fontSize: 13,
                        ),
                        Text(
                          '${_grid.rows}x${_grid.cols} 2.5D GRID',
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const AdBannerWidget(adUnitId: AdsService.soloBannerAdUnitId),
                ],
              ),
            ),

            // Confetti Cannon Overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  AppColors.primaryYellow,
                  AppColors.freshGreen,
                  AppColors.skyBlue,
                  AppColors.coral,
                ],
              ),
            ),

            // Found Word Score Pop-up Overlay
            if (_showScorePopup)
              Positioned(
                top: 140,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.freshGreen,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: AppColors.shadowHard, blurRadius: 16, offset: Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.sparkles, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'FOUND $_foundToastWord (+100 PTS)',
                          style: GoogleFonts.fredoka(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(1.1, 1.1), duration: 250.ms).fadeIn(),
              ),
          ],
        ),
      ),
    );
  }
}
