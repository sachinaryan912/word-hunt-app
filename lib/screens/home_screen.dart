import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../state/session_state.dart';
import '../services/api_client.dart';
import '../services/ads_service.dart';
import '../services/solo_board_generator.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/avatar_display.dart';
import '../widgets/cartoon_background.dart';
import '../widgets/cartoon_card.dart';
import '../widgets/cartoon_dialog.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/mascot_widget.dart';
import 'matchmaking_screen.dart';
import 'solo_level_screen.dart';
import 'private_room_screen.dart';
import 'daily_challenge_screen.dart';
import 'friend_invite_sheet.dart';
import 'friend_match_connecting_screen.dart';
import '../state/friend_match_provider.dart';

class HomeScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentLevel = 1;
  late AdsService _adsService;
  bool _isClaimingGift = false;

  @override
  void initState() {
    super.initState();
    _loadLevel();
    _adsService = context.read<AdsService>();
    _adsService.preloadRewarded(RewardedPlacement.dailyGift);
  }

  Future<void> _loadLevel() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _currentLevel = prefs.getInt('currentLevel') ?? 1);
  }

  Future<void> _onGiftTap() async {
    if (_isClaimingGift) return;
    DailyGiftStatus status;
    try {
      status = await context.read<ApiClient>().getDailyGiftStatus();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load your daily gift — try again later.')),
      );
      return;
    }
    if (!mounted) return;

    if (!status.freeClaimed) {
      CartoonDialog.show(
        context: context,
        mascotPose: MascotPose.idle,
        title: 'DAILY GIFT!',
        subtitle: 'Claim your free +10 XP for today.',
        primaryButtonText: 'CLAIM 10 XP',
        onPrimaryPressed: () {
          Navigator.of(context).pop();
          _claimFreeGift();
        },
        secondaryButtonText: 'CLOSE',
        onSecondaryPressed: () => Navigator.of(context).pop(),
      );
    } else {
      // Free gift is claimed — ad-bonus XP has no daily cap, so always offer
      // another one.
      CartoonDialog.show(
        context: context,
        mascotPose: MascotPose.idle,
        title: 'WANT MORE XP?',
        subtitle: 'Watch an ad for +10 more XP — as many times as you like!',
        primaryButtonText: 'WATCH AD FOR 10 XP',
        onPrimaryPressed: () {
          Navigator.of(context).pop();
          _claimAdGift();
        },
        secondaryButtonText: 'CLOSE',
        onSecondaryPressed: () => Navigator.of(context).pop(),
      );
    }
  }

  Future<void> _claimFreeGift() async {
    setState(() => _isClaimingGift = true);
    LoadingOverlay.show(context);
    try {
      final xp = await context.read<ApiClient>().claimDailyGiftFree();
      if (!mounted) return;
      await context.read<SessionState>().refreshProfile();
      if (!mounted) return;
      LoadingOverlay.hide(context);
      CartoonDialog.show(
        context: context,
        mascotPose: MascotPose.celebrating,
        title: '+$xp XP CLAIMED!',
        subtitle: 'Come back and watch an ad for even more XP.',
        primaryButtonText: 'NICE!',
        onPrimaryPressed: () => Navigator.of(context).pop(),
      );
    } catch (_) {
      if (!mounted) return;
      LoadingOverlay.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not claim your gift — try again later.')),
      );
    } finally {
      if (mounted) {
        LoadingOverlay.hide(context);
        setState(() => _isClaimingGift = false);
      }
    }
  }

  Future<void> _claimAdGift() async {
    if (!_adsService.isRewardedReady(RewardedPlacement.dailyGift)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bonus ad is still loading — try again in a moment.')),
      );
      _adsService.preloadRewarded(RewardedPlacement.dailyGift);
      return;
    }
    setState(() => _isClaimingGift = true);
    _adsService.showRewarded(
      RewardedPlacement.dailyGift,
      onEarnedReward: () async {
        if (!mounted) return;
        LoadingOverlay.show(context);
        try {
          final xp = await context.read<ApiClient>().claimDailyGiftAd();
          if (!mounted) return;
          await context.read<SessionState>().refreshProfile();
          if (!mounted) return;
          LoadingOverlay.hide(context);
          CartoonDialog.show(
            context: context,
            mascotPose: MascotPose.celebrating,
            title: '+$xp XP CLAIMED!',
            subtitle: 'Watch another ad anytime for more XP.',
            primaryButtonText: 'NICE!',
            onPrimaryPressed: () => Navigator.of(context).pop(),
          );
        } catch (_) {
          if (!mounted) return;
          LoadingOverlay.hide(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not claim your reward — try again later.')),
          );
        } finally {
          if (mounted) LoadingOverlay.hide(context);
        }
      },
      onDismissed: () {
        if (mounted) setState(() => _isClaimingGift = false);
        _adsService.preloadRewarded(RewardedPlacement.dailyGift);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SessionState>().profile;
    final gridSize = SoloBoardGenerator.gridSizeForLevel(_currentLevel);

    return Scaffold(
      body: CartoonBackground(
        mode: CartoonBackgroundMode.dashboard,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row with App Logo Image
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (profile?.avatarId != null)
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: AvatarDisplay(
                              avatarId: profile!.avatarId,
                              fallbackInitial: profile.name.isNotEmpty ? profile.name[0] : '?',
                              size: 40,
                            ),
                          )
                        else
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                'assets/images/app_logo_cartoon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WELCOME BACK',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile?.name ?? 'Guest',
                              style: GoogleFonts.fredoka(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCardDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primaryYellow, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.sparkles, size: 16, color: AppColors.primaryYellow),
                              const SizedBox(width: 6),
                              Text(
                                '${profile?.xp ?? 0} XP',
                                style: GoogleFonts.fredoka(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryYellow,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(LucideIcons.gift, size: 20, color: AppColors.primaryOrange),
                          onPressed: _onGiftTap,
                        ),
                      ],
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),

                const SizedBox(height: 20),

                // Primary Action Card: QUICK MATCH with Custom Cartoon Illustration Banner
                CartoonCard(
                  color: AppColors.royalBlue,
                  bevelColor: AppColors.royalBlueBevel,
                  padding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MatchmakingScreen()),
                    );
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: 145,
                    child: Stack(
                      children: [
                        // Banner Background
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              'assets/images/multiplayer_match_banner_cartoon.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(color: AppColors.royalBlue),
                            ),
                          ),
                        ),
                        // Dark overlay so the banner text stays readable over the artwork
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Container(color: Colors.black.withAlpha(180)),
                          ),
                        ),
                        // Mascot Explorer Floating Badge
                        Positioned(
                          right: 16,
                          bottom: 12,
                          child: const MascotWidget(
                            pose: MascotPose.searching,
                            size: 70,
                          ),
                        ),
                        // Card Contents
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.zap, size: 20, color: AppColors.primaryYellow),
                                  const SizedBox(width: 8),
                                  Text(
                                    'QUICK MATCH',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                      color: AppColors.primaryYellow,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Find a real-time online opponent',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms).scale(begin: const Offset(0.97, 0.97), end: const Offset(1.0, 1.0)),

                const SizedBox(height: 24),

                Text(
                  'GAME MODES',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(height: 12),

                // Secondary Options Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildModeCard(
                        context,
                        title: 'Solo Play',
                        subtitle: 'Level $_currentLevel • ${gridSize.$1}x${gridSize.$2} Grid',
                        icon: LucideIcons.grid,
                        cardColor: AppColors.surfaceCardDark,
                        iconColor: AppColors.primaryYellow,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SoloLevelScreen()),
                          ).then((_) => _loadLevel());
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModeCard(
                        context,
                        title: 'Private Room',
                        subtitle: 'Custom Code Lobby',
                        icon: LucideIcons.keyRound,
                        cardColor: AppColors.surfaceCardDark,
                        iconColor: AppColors.skyBlue,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PrivateRoomScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildModeCard(
                        context,
                        title: 'Quick Match',
                        subtitle: 'Real-Time Random Opponent',
                        icon: LucideIcons.zap,
                        cardColor: AppColors.surfaceCardDark,
                        iconColor: AppColors.royalBlue,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MatchmakingScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModeCard(
                        context,
                        title: 'Play with Friends',
                        subtitle: 'Invite & Battle Live',
                        icon: LucideIcons.userPlus,
                        cardColor: AppColors.surfaceCardDark,
                        iconColor: AppColors.freshGreen,
                        onTap: () {
                          FriendInviteSheet.show(
                            context,
                            context.read<SessionState>().apiClient,
                            (friendUid, friendName) {
                              context.read<FriendMatchProvider>().sendInvite(friendUid, friendName);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FriendMatchConnectingScreen(
                                    peerName: friendName,
                                    showCancel: true,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 220.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 14),

                // Daily Challenge Banner
                CartoonCard(
                  color: AppColors.surfaceCardDark,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DailyChallengeScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withAlpha(30),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primaryOrange, width: 1.5),
                        ),
                        child: const Icon(LucideIcons.calendar, size: 22, color: AppColors.primaryOrange),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAILY CHALLENGE',
                              style: GoogleFonts.fredoka(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Puzzle #241 • 8 Target Words',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textMuted),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 250.ms),

                const SizedBox(height: 16),

                // Banner ad — sits inline in the natural gap between sections;
                // collapses to nothing while loading so it never blocks content.
                const AdBannerWidget(adUnitId: AdsService.homeBannerAdUnitId),

                const SizedBox(height: 16),

                // Progress Summary Card
                Text(
                  'PROGRESS SUMMARY',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.skyBlue,
                  ),
                ),
                const SizedBox(height: 12),
                CartoonCard(
                  color: AppColors.surfaceCardDark,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Level ${profile?.level ?? 1} Progress', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimaryLight)),
                          Text('${profile?.xpIntoLevel ?? 0} / ${profile?.xpForNextLevel ?? 200} XP', style: GoogleFonts.fredoka(fontSize: 13, color: AppColors.primaryYellow)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: profile?.xpProgress ?? 0,
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceBorderDark,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.surfaceBorderDark),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(label: 'Total Wins', value: '${profile?.totalWins ?? 0}'),
                          _StatItem(label: 'Win Rate', value: '${(profile?.winRate ?? 0).round()}%'),
                          _StatItem(label: 'Streak', value: '${profile?.winStreak ?? 0} Matches'),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color cardColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return CartoonCard(
      color: cardColor,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: iconColor),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.fredoka(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondaryLight)),
      ],
    );
  }
}
