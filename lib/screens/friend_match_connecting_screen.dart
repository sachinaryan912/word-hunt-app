import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../state/match_provider.dart';
import '../state/friend_match_provider.dart';
import '../widgets/cartoon_background.dart';
import '../widgets/cartoon_button.dart';
import '../widgets/mascot_widget.dart';
import 'multiplayer_gameplay_screen.dart';

/// Shown while a "play with a friend" invite is in flight — either I just
/// sent one and am waiting for them to accept (`showCancel: true`), or I just
/// accepted one and am waiting for the server to actually start the match.
/// Either way this screen's only job is: watch MatchProvider, and once the
/// match goes active, hand off to MultiplayerGameplayScreen — same handoff
/// pattern as MatchmakingScreen uses for Quick Match.
class FriendMatchConnectingScreen extends StatefulWidget {
  final String peerName;
  final bool showCancel;

  const FriendMatchConnectingScreen({
    super.key,
    required this.peerName,
    this.showCancel = false,
  });

  @override
  State<FriendMatchConnectingScreen> createState() => _FriendMatchConnectingScreenState();
}

class _FriendMatchConnectingScreenState extends State<FriendMatchConnectingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _elapsedTimer;
  int _secondsWaiting = 0;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secondsWaiting++);
    });
    context.read<MatchProvider>().addListener(_onMatchChanged);
    context.read<FriendMatchProvider>().addListener(_onFriendMatchChanged);
  }

  void _onMatchChanged() {
    final matchProvider = context.read<MatchProvider>();
    if (!_navigated && matchProvider.status == MatchmakingStatus.active) {
      _navigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MultiplayerGameplayScreen()),
      );
    }
  }

  void _onFriendMatchChanged() {
    if (_navigated || !mounted) return;
    final provider = context.read<FriendMatchProvider>();

    if (widget.showCancel) {
      final outcome = provider.outgoingOutcome;
      if (outcome == FriendInviteOutcome.declined ||
          outcome == FriendInviteOutcome.expired ||
          outcome == FriendInviteOutcome.failed) {
        _navigated = true;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_outgoingMessage(outcome))),
        );
      }
    } else if (provider.acceptFailureCode != null) {
      _navigated = true;
      provider.clearAcceptFailure();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("That match couldn't be started — your friend may have gone offline.")),
      );
    }
  }

  String _outgoingMessage(FriendInviteOutcome outcome) {
    switch (outcome) {
      case FriendInviteOutcome.declined:
        return '${widget.peerName} declined the invite.';
      case FriendInviteOutcome.expired:
        return '${widget.peerName} didn\'t respond in time.';
      default:
        return "Couldn't reach ${widget.peerName} right now.";
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _elapsedTimer?.cancel();
    context.read<MatchProvider>().removeListener(_onMatchChanged);
    context.read<FriendMatchProvider>().removeListener(_onFriendMatchChanged);
    super.dispose();
  }

  void _cancel() {
    if (widget.showCancel) {
      context.read<FriendMatchProvider>().cancelOutgoing();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CartoonBackground(
        mode: CartoonBackgroundMode.matchmaking,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 24, color: AppColors.textPrimaryLight),
                    onPressed: _cancel,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RotationTransition(
                      turns: _controller,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.freshGreen.withAlpha(120), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.freshGreen.withAlpha(50),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: MascotWidget(pose: MascotPose.searching, size: 100, autoAnimate: false),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      widget.showCancel ? 'WAITING FOR ${widget.peerName.toUpperCase()}' : 'JOINING MATCH',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppColors.freshGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.showCancel
                          ? 'Waiting for them to accept • ${_secondsWaiting}s'
                          : 'Setting up your match with ${widget.peerName}...',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: CartoonButton(
                  text: 'CANCEL',
                  onPressed: _cancel,
                  variant: CartoonButtonVariant.outline,
                  width: double.infinity,
                  height: 52,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
