import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/update_service.dart';
import '../state/friend_match_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/cartoon_dialog.dart';
import '../widgets/mascot_widget.dart';
import 'friend_match_connecting_screen.dart';
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
  final _leaderboardKey = GlobalKey<LeaderboardScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
    context.read<FriendMatchProvider>().addListener(_onFriendMatchChanged);
    // Covers a cold start from a tapped notification: the invite can arrive
    // (via NotificationService's getInitialMessage handling) before this
    // widget even exists, so notifyListeners() fires before the listener
    // above is attached and would otherwise be missed entirely.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFriendMatchChanged());
  }

  @override
  void dispose() {
    context.read<FriendMatchProvider>().removeListener(_onFriendMatchChanged);
    super.dispose();
  }

  void _onFriendMatchChanged() {
    final provider = context.read<FriendMatchProvider>();
    final invite = provider.incomingInvite;
    if (invite == null) return;
    // Consume it immediately so a rebuild (or a second invite arriving
    // later) doesn't stack duplicate dialogs.
    provider.dismissIncoming();

    CartoonDialog.show(
      context: context,
      mascotPose: MascotPose.idle,
      title: 'MATCH INVITE',
      subtitle: '${invite.fromDisplayName} wants to play a match with you right now.',
      primaryButtonText: 'ACCEPT',
      onPrimaryPressed: () {
        Navigator.of(context).pop();
        provider.accept(invite.inviteId);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FriendMatchConnectingScreen(
              peerName: invite.fromDisplayName,
              showCancel: false,
            ),
          ),
        );
      },
      secondaryButtonText: 'DECLINE',
      onSecondaryPressed: () {
        Navigator.of(context).pop();
        provider.decline(invite.inviteId);
      },
      barrierDismissible: false,
    );
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
    // The tab screens live in an IndexedStack and never dispose, so a tab
    // that fetches data once in initState (like Leaderboard) would keep
    // showing stale results from the first time it was ever opened.
    if (index == 1) _leaderboardKey.currentState?.refresh();
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
      HomeScreen(onNavigateTab: _switchTab),
      LeaderboardScreen(key: _leaderboardKey, isEmbedded: true),
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
        onTap: _switchTab,
      ),
    );
  }
}
