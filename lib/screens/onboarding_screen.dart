import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_search_grid.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/cartoon_background.dart';
import '../widgets/cartoon_button.dart';
import '../widgets/cartoon_card.dart';
import '../widgets/letter_grid_widget.dart';
import '../widgets/mascot_widget.dart';
import 'main_shell.dart';
import 'welcome_auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final WordSearchGrid _sampleGrid = WordSearchGrid(
    rows: 5,
    cols: 5,
    grid: const [
      ['W', 'O', 'R', 'D', 'S'],
      ['H', 'U', 'N', 'T', 'X'],
      ['F', 'I', 'N', 'D', 'O'],
      ['P', 'A', 'T', 'H', 'Z'],
      ['G', 'R', 'I', 'D', 'K'],
    ],
    targetWords: const ['WORDS', 'HUNT', 'FIND'],
    foundWords: const [
      FoundWordPath(
        word: 'WORDS',
        path: [GridPos(0, 0), GridPos(0, 1), GridPos(0, 2), GridPos(0, 3), GridPos(0, 4)],
        claimedBy: 'player',
      )
    ],
  );

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    if (!mounted) return;
    final hasSession = context.read<AuthService>().hasSession;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => hasSession ? const MainShell() : const WelcomeAuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CartoonBackground(
        mode: CartoonBackgroundMode.onboarding,
        child: SafeArea(
          child: Column(
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset('assets/images/app_logo_cartoon.png', fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'WORD HUNTING',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.primaryYellow,
                          ),
                        ),
                      ],
                    ),
                    if (_currentPage < 3)
                      GestureDetector(
                        onTap: _finishOnboarding,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Page Carousel
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  children: [
                    _buildPage(
                      title: '1. FIND',
                      subtitle: 'Locate hidden words in the 2.5D grid.',
                      bodyText: 'Drag across matching letters horizontally, vertically, or diagonally.',
                      visualWidget: SizedBox(
                        width: 240,
                        child: LetterGridWidget(grid: _sampleGrid),
                      ),
                    ),
                    _buildPage(
                      title: '2. HUNT',
                      subtitle: 'Real-time 1v1 battle arena.',
                      bodyText: 'Both players share the exact same board. Race to claim words first!',
                      visualWidget: CartoonCard(
                        color: AppColors.surfaceCardDark,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('YOU', style: GoogleFonts.fredoka(fontSize: 14, color: AppColors.primaryYellow, fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.coral,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('VS', style: GoogleFonts.fredoka(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                Text('OPPONENT', style: GoogleFonts.fredoka(fontSize: 14, color: AppColors.skyBlue, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('Shared Board • Claimed words locked instantly', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondaryLight)),
                          ],
                        ),
                      ),
                    ),
                    _buildPage(
                      title: '3. COMPETE',
                      subtitle: 'Rankings, daily puzzles & private lobbies.',
                      bodyText: 'Climb the global rating leaderboard, solve daily challenges, and invite friends!',
                      visualWidget: CartoonCard(
                        color: AppColors.surfaceCardDark,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Global Rank #14', style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryYellow)),
                            const SizedBox(height: 6),
                            Text('Rating 1,840 • Win Rate 69%', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondaryLight)),
                          ],
                        ),
                      ),
                    ),
                    _buildPage(
                      title: '4. ADVENTURE AWAITS',
                      subtitle: 'Ready to enter the grid!',
                      bodyText: 'Join thousands of word search hunters worldwide.',
                      visualWidget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Animate(
                            child: MascotWidget(
                              pose: MascotPose.celebrating,
                              size: 110,
                            ),
                          ).scale(duration: 400.ms),
                          const SizedBox(height: 24),
                          CartoonButton(
                            text: 'START HUNTING',
                            onPressed: _finishOnboarding,
                            variant: CartoonButtonVariant.primary,
                            width: double.infinity,
                            height: 54,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Page Indicator & Action Controls
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primaryYellow : AppColors.surfaceBorderDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    if (_currentPage < 3) ...[
                      const SizedBox(height: 20),
                      CartoonButton(
                        text: 'CONTINUE',
                        onPressed: _nextPage,
                        variant: CartoonButtonVariant.primary,
                        width: double.infinity,
                        height: 52,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String subtitle,
    required String bodyText,
    required Widget visualWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            bodyText,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          visualWidget,
        ],
      ),
    );
  }
}
