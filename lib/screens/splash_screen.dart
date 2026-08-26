import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../state/session_state.dart';
import '../state/match_provider.dart';
import '../state/room_provider.dart';
import '../state/friend_match_provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';
import '../widgets/cartoon_background.dart';
import '../widgets/mascot_widget.dart';
import 'onboarding_screen.dart';
import 'main_shell.dart';
import 'welcome_auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SoundService>().playBackgroundMusic();
    _bootstrapAndNavigate();
  }

  Future<void> _bootstrapAndNavigate() async {
    final authService = context.read<AuthService>();
    final session = context.read<SessionState>();
    final minSplash = Future.delayed(const Duration(milliseconds: 2600));

    bool onboarded = false;
    // Only an already-signed-in return visitor bootstraps silently here — a
    // brand-new or signed-out user is routed to WelcomeAuthScreen instead of
    // being auto-signed-in as a guest without being asked.
    final hasSession = authService.hasSession;
    try {
      final prefs = await SharedPreferences.getInstance();
      onboarded = prefs.getBool('onboarded') ?? false;
      if (hasSession) {
        await session.bootstrap();
        final uid = session.profile?.id;
        if (uid != null && mounted) {
          context.read<MatchProvider>().startListening(uid);
          context.read<RoomProvider>().startListening();
          context.read<FriendMatchProvider>().startListening();
          unawaited(context.read<NotificationService>().initialize());
        }
      }
    } catch (_) {
      // Backend unavailable fallback
    }

    await minSplash;
    if (!mounted) return;

    final Widget target = !hasSession
        ? const WelcomeAuthScreen()
        : (onboarded ? const MainShell() : const OnboardingScreen());

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => target,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CartoonBackground(
        mode: CartoonBackgroundMode.loading,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 2.5D Cartoon App Logo
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.primaryYellowBevel,
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    'assets/images/app_logo_new.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.primaryYellow,
                      child: const Icon(Icons.search_rounded, size: 60, color: AppColors.bgDarkNavy),
                    ),
                  ),
                ),
              ).animate().scale(begin: const Offset(0.7, 0.7), end: const Offset(1.0, 1.0), duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),

              const SizedBox(height: 28),

              // Playful Title
              Text(
                'WORD HUNTING',
                style: GoogleFonts.fredoka(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: AppColors.primaryYellow,
                  shadows: const [
                    Shadow(
                      color: AppColors.shadowHard,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 6),

              Text(
                'CARTOON WORD SEARCH ADVENTURE',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.skyBlue,
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 350.ms),

              const SizedBox(height: 40),

              // Explorer Mascot loader
              Animate(
                child: MascotWidget(
                  pose: MascotPose.searching,
                  size: 80,
                ),
              ).fadeIn(duration: 400.ms, delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
