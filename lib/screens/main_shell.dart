import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/update_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/cartoon_dialog.dart';
import '../widgets/mascot_widget.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  final int initialTab;
  const MainShell({super.key, this.initialTab = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    try {
      final result = await context.read<UpdateService>().check();
      if (!mounted || !result.updateAvailable) return;
      await CartoonDialog.show(
        context: context,
        mascotPose: MascotPose.idle,
        title: result.mandatory ? 'UPDATE REQUIRED' : 'UPDATE AVAILABLE',
        subtitle: result.mandatory
            ? 'A new version of Word Hunting is required to continue playing.'
            : 'A new version of Word Hunting is ready with fixes and improvements.',
        primaryButtonText: 'UPDATE NOW',
        onPrimaryPressed: () => context.read<UpdateService>().openUpdateUrl(result.updateUrl),
        secondaryButtonText: result.mandatory ? null : 'LATER',
        onSecondaryPressed: result.mandatory ? null : () => Navigator.of(context).pop(),
        barrierDismissible: !result.mandatory,
        preventPop: result.mandatory,
      );
    } catch (_) {
      // Silent — update checks should never block or interrupt the user.
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateTab: (index) => setState(() => _currentIndex = index)),
      const LeaderboardScreen(isEmbedded: true),
      const ProfileScreen(isEmbedded: true),
      const SettingsScreen(isEmbedded: true),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
