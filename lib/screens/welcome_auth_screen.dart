import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../state/session_state.dart';
import '../state/match_provider.dart';
import '../state/room_provider.dart';
import '../widgets/cartoon_background.dart';
import '../widgets/cartoon_button.dart';
import '../widgets/google_logo.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

class WelcomeAuthScreen extends StatefulWidget {
  const WelcomeAuthScreen({super.key});

  @override
  State<WelcomeAuthScreen> createState() => _WelcomeAuthScreenState();
}

class _WelcomeAuthScreenState extends State<WelcomeAuthScreen> {
  bool _isGuestLoading = false;
  bool _isGoogleLoading = false;

  bool get _isBusy => _isGuestLoading || _isGoogleLoading;

  Future<void> _continueAsGuest() async {
    if (_isBusy) return;
    setState(() => _isGuestLoading = true);
    try {
      await context.read<SessionState>().bootstrap();
      if (!mounted) return;
      await _afterAuthSuccess();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not continue as guest — check your connection and try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGuestLoading = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    if (_isBusy) return;
    setState(() => _isGoogleLoading = true);
    try {
      await context.read<AuthService>().signInWithGoogle();
      if (!mounted) return;
      await context.read<SessionState>().bootstrap();
      if (!mounted) return;
      await _afterAuthSuccess();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in was cancelled or failed — try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _afterAuthSuccess() async {
    final uid = context.read<SessionState>().profile?.id;
    if (uid != null && mounted) {
      context.read<MatchProvider>().startListening(uid);
      context.read<RoomProvider>().startListening();
      unawaited(context.read<NotificationService>().initialize());
    }
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarded') ?? false;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => onboarded ? const MainShell() : const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CartoonBackground(
        mode: CartoonBackgroundMode.onboarding,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(color: AppColors.primaryYellowBevel, blurRadius: 24, spreadRadius: 2, offset: Offset(0, 8)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset('assets/images/app_logo_new.png', fit: BoxFit.cover),
                  ),
                ).animate().scale(begin: const Offset(0.7, 0.7), end: const Offset(1.0, 1.0), duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),

                const SizedBox(height: 24),

                Text(
                  'WORD HUNTING',
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: AppColors.primaryYellow,
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 8),

                Text(
                  'Find words. Race friends. Climb the ranks.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600),
                ).animate().fadeIn(duration: 400.ms, delay: 250.ms),

                const Spacer(),

                CartoonButton(
                  text: 'CONTINUE WITH GOOGLE',
                  leading: const GoogleLogo(size: 20),
                  variant: CartoonButtonVariant.secondary,
                  isLoading: _isGoogleLoading,
                  onPressed: _isBusy ? null : _continueWithGoogle,
                  width: double.infinity,
                  height: 52,
                ).animate().fadeIn(duration: 400.ms, delay: 350.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 12),

                CartoonButton(
                  text: 'CONTINUE AS GUEST',
                  icon: LucideIcons.user,
                  variant: CartoonButtonVariant.outline,
                  isLoading: _isGuestLoading,
                  onPressed: _isBusy ? null : _continueAsGuest,
                  width: double.infinity,
                  height: 52,
                ).animate().fadeIn(duration: 400.ms, delay: 420.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                Text(
                  'Guest progress can be linked to Google later in Settings.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textMuted),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
