import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/api_client.dart';
import '../services/ads_service.dart';
import '../state/session_state.dart';
import '../widgets/cartoon_background.dart';
import '../widgets/cartoon_button.dart';
import '../widgets/cartoon_card.dart';
import '../widgets/cartoon_dialog.dart';
import '../widgets/mascot_widget.dart';
import 'main_shell.dart';
import 'matchmaking_screen.dart';
import 'solo_level_screen.dart';

class MatchResultScreen extends StatefulWidget {
  final bool isWin;
  final int score;
  final int wordsFoundCount;
  final int accuracyPercent;
  final int durationSeconds;
  final String? opponentName;
  final String? opponentUid;
  final String? matchId;
  final int? ratingDelta;
  final int? newRating;
  final bool isDailyChallenge;

  const MatchResultScreen({
    super.key,
    required this.isWin,
    required this.score,
    required this.wordsFoundCount,
    required this.accuracyPercent,
    required this.durationSeconds,
    this.opponentName,
    this.opponentUid,
    this.matchId,
    this.ratingDelta,
    this.newRating,
    this.isDailyChallenge = false,
  });

  @override
  State<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends State<MatchResultScreen> {
  late ConfettiController _confettiController;
  late AdsService _adsService;
  bool _isSolo = false;
  bool _rewardClaimed = false;
  bool _isClaimingReward = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    if (widget.isWin) {
      _confettiController.play();
    }
    _isSolo = widget.opponentName == null;
    _adsService = context.read<AdsService>();
    if (_isSolo) {
      _adsService.preloadInterstitial();
      if (widget.isWin) _adsService.preloadRewarded(RewardedPlacement.matchBonus);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  void _goHome() {
    if (_isSolo) {
      _adsService.showInterstitialIfReady(
        onDismissed: () {
          if (mounted) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
          }
        },
      );
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
    }
  }

  Future<void> _claimAdReward() async {
    if (_isClaimingReward || _rewardClaimed) return;
    if (!_adsService.isRewardedReady(RewardedPlacement.matchBonus)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bonus ad is still loading — try again in a moment.')),
      );
      _adsService.preloadRewarded(RewardedPlacement.matchBonus);
      return;
    }
    setState(() => _isClaimingReward = true);
    _adsService.showRewarded(
      RewardedPlacement.matchBonus,
      onEarnedReward: () async {
        try {
          await context.read<ApiClient>().claimAdReward();
          if (mounted) {
            await context.read<SessionState>().refreshProfile();
            setState(() => _rewardClaimed = true);
          }
        } catch (_) {
          // Offline fallback
        }
      },
      onDismissed: () {
        if (mounted) setState(() => _isClaimingReward = false);
      },
    );
  }

  Future<void> _reportOpponent() async {
    final reasons = ['Cheating', 'Offensive language', 'Harassment', 'Other'];
    final reason = await CartoonDialog.show<String>(
      context: context,
      title: 'REPORT PLAYER',
      subtitle: 'Select a reason for reporting this player',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: reasons
            .map((r) => ListTile(
                  title: Text(r, style: GoogleFonts.fredoka(fontSize: 14, color: AppColors.textPrimaryLight)),
                  trailing: const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted),
                  onTap: () => Navigator.of(context).pop(r),
                ))
            .toList(),
      ),
      secondaryButtonText: 'CANCEL',
      onSecondaryPressed: () => Navigator.of(context).pop(),
    );
    if (reason == null || !mounted) return;
    try {
      await context.read<ApiClient>().reportPlayer(
            targetUid: widget.opponentUid!,
            reason: reason,
            matchId: widget.matchId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit report')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CartoonBackground(
        mode: CartoonBackgroundMode.dashboard,
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Explorer Mascot Celebration Poses
                    Animate(
                      child: MascotWidget(
                        pose: widget.isWin ? MascotPose.celebrating : MascotPose.losing,
                        size: 110,
                      ),
                    ).scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), duration: 400.ms),

                    const SizedBox(height: 16),
                    Text(
                      widget.isWin ? 'VICTORY!' : 'MATCH COMPLETE',
                      style: GoogleFonts.fredoka(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: widget.isWin ? AppColors.primaryYellow : AppColors.textPrimaryLight,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                    if (widget.ratingDelta != null && widget.newRating != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${widget.ratingDelta! >= 0 ? '+' : ''}${widget.ratingDelta} Rating Points (${widget.newRating} MMR)',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.freshGreen,
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Score Breakdown 2.5D Card
                    CartoonCard(
                      color: AppColors.surfaceCardDark,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'FINAL SCORE',
                                style: GoogleFonts.fredoka(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                              Text(
                                '${widget.score} PTS',
                                style: GoogleFonts.fredoka(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryYellow,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.surfaceBorderDark),
                          const SizedBox(height: 16),

                          _buildStatRow('Words Found', '${widget.wordsFoundCount} Target Words'),
                          const SizedBox(height: 12),
                          _buildStatRow('Accuracy Rate', '${widget.accuracyPercent}%'),
                          const SizedBox(height: 12),
                          _buildStatRow('Match Duration', _formatDuration(widget.durationSeconds)),
                          if (widget.opponentName != null) ...[
                            const SizedBox(height: 12),
                            _buildStatRow(
                              'Opponent',
                              widget.opponentName!,
                              trailing: widget.opponentUid == null
                                  ? null
                                  : InkWell(
                                      onTap: _reportOpponent,
                                      child: const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(LucideIcons.flag, size: 16, color: AppColors.coral),
                                      ),
                                    ),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.05, end: 0),

                    if (_isSolo && widget.isWin) ...[
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _rewardClaimed || _isClaimingReward ? null : _claimAdReward,
                        icon: Icon(LucideIcons.play, size: 16, color: _rewardClaimed ? AppColors.textMuted : AppColors.primaryYellow),
                        label: Text(
                          _rewardClaimed ? 'BONUS XP CLAIMED' : 'WATCH AD FOR BONUS XP',
                          style: GoogleFonts.fredoka(fontSize: 13, color: _rewardClaimed ? AppColors.textMuted : AppColors.primaryYellow),
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Primary Action & Return Home Buttons
                    if (!_isSolo) ...[
                      CartoonButton(
                        text: 'REMATCH',
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const MatchmakingScreen()),
                          );
                        },
                        variant: CartoonButtonVariant.primary,
                        width: double.infinity,
                        height: 52,
                      ),
                      const SizedBox(height: 12),
                    ] else if (!widget.isDailyChallenge) ...[
                      CartoonButton(
                        text: 'NEXT LEVEL',
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const SoloLevelScreen()),
                          );
                        },
                        variant: CartoonButtonVariant.primary,
                        width: double.infinity,
                        height: 52,
                      ),
                      const SizedBox(height: 12),
                    ],
                    CartoonButton(
                      text: 'RETURN HOME',
                      onPressed: _goHome,
                      variant: CartoonButtonVariant.outline,
                      width: double.infinity,
                      height: 48,
                    ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ],
    );
  }
}
