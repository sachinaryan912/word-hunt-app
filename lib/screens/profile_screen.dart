import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/player_profile.dart';
import '../state/session_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/cartoon_background.dart';
import '../widgets/cartoon_card.dart';
import '../widgets/avatar_display.dart';
import 'avatar_shop_sheet.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool isEmbedded;
  const ProfileScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();
    final profile = session.profile ?? PlayerProfile.empty('');
    final achievements = session.achievements
        .map((a) => AchievementItem(
              id: a.id,
              title: a.title,
              description: a.description,
              isUnlocked: a.isUnlocked,
              iconName: AchievementItem.iconFor(a.id),
            ))
        .toList();

    return Scaffold(
      appBar: isEmbedded
          ? null
          : AppHeader(
              title: 'PROFILE',
              showBack: false,
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.settings, size: 20, color: AppColors.textPrimaryLight),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
      body: CartoonBackground(
        mode: CartoonBackgroundMode.profile,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEmbedded)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PROFILE DASHBOARD',
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryYellow,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.settings, size: 20, color: AppColors.textPrimaryLight),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 12),

                // Player Info Header Card with Cartoon Mascot Avatar
                CartoonCard(
                  color: AppColors.surfaceCardDark,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Avatar — tap to open the avatar shop
                      GestureDetector(
                        onTap: () => AvatarShopSheet.show(context),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primaryYellow, width: 2.5),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: AvatarDisplay(
                                avatarId: profile.avatarId,
                                fallbackInitial: profile.name.isNotEmpty ? profile.name[0] : '?',
                                size: 58,
                              ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryYellow,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.pencil, size: 12, color: AppColors.bgDarkNavy),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: GoogleFonts.fredoka(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Level ${profile.level} • ${profile.rating} MMR',
                              style: GoogleFonts.fredoka(
                                fontSize: 13,
                                color: AppColors.primaryYellow,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // XP Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: profile.xpProgress,
                                minHeight: 6,
                                backgroundColor: AppColors.surfaceBorderDark,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${profile.xp} TOTAL XP',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.05, end: 0),

                const SizedBox(height: 24),

                // Statistics Grid
                Text(
                  'STATISTICS OVERVIEW',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(height: 12),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.15,
                  children: [
                    _buildStatTile('Rating', '${profile.rating}', LucideIcons.trophy, AppColors.primaryYellow),
                    _buildStatTile('Total Games', '${profile.totalGames}', LucideIcons.gamepad2, AppColors.skyBlue),
                    _buildStatTile('Total Wins', '${profile.totalWins}', LucideIcons.award, AppColors.freshGreen),
                    _buildStatTile('Win Rate', '${profile.winRate.round()}%', LucideIcons.percent, AppColors.coral),
                    _buildStatTile('Best Score', '${profile.bestScore}', LucideIcons.flame, AppColors.primaryOrange),
                    _buildStatTile('Win Streak', '${profile.winStreak}', LucideIcons.zap, AppColors.purple),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

                const SizedBox(height: 24),

                // Achievements List
                Text(
                  'ACHIEVEMENTS',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.skyBlue,
                  ),
                ),
                const SizedBox(height: 12),

                Column(
                  children: achievements.map((ach) {
                    return CartoonCard(
                      color: ach.isUnlocked ? AppColors.surfaceCardDark : AppColors.surfaceElevated,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(
                            ach.isUnlocked ? LucideIcons.checkCircle2 : LucideIcons.lock,
                            size: 20,
                            color: ach.isUnlocked ? AppColors.freshGreen : AppColors.textMuted,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ach.title,
                                  style: GoogleFonts.fredoka(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: ach.isUnlocked ? AppColors.textPrimaryLight : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ach.description,
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (ach.isUnlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.freshGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'UNLOCKED',
                                style: GoogleFonts.fredoka(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color accentColor) {
    return CartoonCard(
      color: AppColors.surfaceCardDark,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
