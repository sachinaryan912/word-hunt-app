import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/cartoon_background.dart';
import '../widgets/cartoon_button.dart';
import '../widgets/cartoon_card.dart';
import '../widgets/state_indicators.dart';
import '../services/api_client.dart';
import '../services/ads_service.dart';
import '../widgets/ad_banner_widget.dart';
import 'solo_level_screen.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  DailyChallengeDto? _challenge;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final challenge = await context.read<ApiClient>().getDailyChallenge();
      if (!mounted) return;
      setState(() {
        _challenge = challenge;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'DAILY PUZZLE'),
      body: CartoonBackground(
        mode: CartoonBackgroundMode.dashboard,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
              : _hasError || _challenge == null
                  ? EmptyStateView(
                      icon: LucideIcons.wifiOff,
                      title: "Couldn't load today's challenge",
                      description: 'Check your connection and try again.',
                      actionLabel: 'RETRY',
                      onAction: _load,
                    )
                  : Column(
                      children: [
                        Expanded(child: _buildContent(_challenge!)),
                        const AdBannerWidget(adUnitId: AdsService.dailyChallengeBannerAdUnitId),
                      ],
                    ),
        ),
      ),
    );
  }

  static const _monthNames = [
    'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
    'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
  ];

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildContent(DailyChallengeDto challenge) {
    final dateStr = _formatDate(challenge.date);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr,
            style: GoogleFonts.fredoka(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Editorial Puzzle #${challenge.puzzleNumber}',
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),

          // Editorial Puzzle Hero Card with Cartoon Illustration
          CartoonCard(
            color: AppColors.surfaceCardDark,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Image.asset(
                    'assets/images/daily_challenge_hero_cartoon.png',
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(height: 150, color: AppColors.primaryOrange),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PUZZLE SPECIFICATIONS',
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.skyBlue,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildRow('Grid Dimension', '${challenge.board.rows} x ${challenge.board.cols} 2.5D Letters'),
                      const SizedBox(height: 10),
                      _buildRow('Target Words', '${challenge.board.targetWords.length} Hidden Words'),
                      const SizedBox(height: 10),
                      _buildRow('Time Limit', '${challenge.timeLimitSeconds} Seconds'),
                      const SizedBox(height: 10),
                      _buildRow('Personal Best', challenge.personalBest != null ? '${challenge.personalBest} PTS' : 'Not attempted yet'),
                      const SizedBox(height: 10),
                      _buildRow(
                        'Global Rank Today',
                        challenge.globalRankToday != null ? '#${challenge.globalRankToday} of ${challenge.totalParticipantsToday}' : 'Unranked',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.97, 0.97), end: const Offset(1.0, 1.0)),

          const SizedBox(height: 16),

          // Info Box
          CartoonCard(
            color: AppColors.surfaceElevated,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(LucideIcons.info, size: 18, color: AppColors.primaryYellow),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Daily challenges refresh every 24 hours at midnight UTC. Complete today’s grid to preserve your daily streak.',
                    style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondaryLight, height: 1.4),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

          const Spacer(),

          // CTA Action Button
          CartoonButton(
            text: 'START CHALLENGE',
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(builder: (_) => SoloLevelScreen(dailyChallenge: challenge)),
                  )
                  .then((_) => _load());
            },
            variant: CartoonButtonVariant.primary,
            width: double.infinity,
            height: 54,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600)),
        Text(value, style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
      ],
    );
  }
}
