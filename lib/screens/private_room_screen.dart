import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/cartoon_background.dart';
import '../widgets/cartoon_button.dart';
import '../widgets/cartoon_card.dart';
import '../widgets/mascot_widget.dart';
import '../widgets/state_indicators.dart';
import '../state/room_provider.dart';
import '../state/match_provider.dart';
import '../state/session_state.dart';
import 'friend_invite_sheet.dart';
import 'multiplayer_gameplay_screen.dart';

class PrivateRoomScreen extends StatefulWidget {
  /// Set when arriving from a "room invite" push notification tap — skips
  /// hosting and joins this code directly instead.
  final String? initialJoinCode;
  const PrivateRoomScreen({super.key, this.initialJoinCode});

  @override
  State<PrivateRoomScreen> createState() => _PrivateRoomScreenState();
}

class _PrivateRoomScreenState extends State<PrivateRoomScreen> {
  bool _isHost = true;
  bool _hasNavigated = false;
  final TextEditingController _joinCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final roomProvider = context.read<RoomProvider>();
    roomProvider.addListener(_onRoomChanged);
    context.read<MatchProvider>().addListener(_onMatchChanged);
    final joinCode = widget.initialJoinCode;
    if (joinCode != null) {
      _isHost = false;
      _joinCodeController.text = joinCode;
      roomProvider.join(joinCode);
    }
    // Otherwise wait for the player to tap "Generate Code" — see
    // _generateCode(). A code isn't created until they explicitly ask for
    // one, so a room (and today's free-room count) is never spent on a
    // visit where they just look around and leave.
  }

  @override
  void dispose() {
    final roomProvider = context.read<RoomProvider>();
    roomProvider.removeListener(_onRoomChanged);
    if (!_hasNavigated) roomProvider.leave();
    context.read<MatchProvider>().removeListener(_onMatchChanged);
    _joinCodeController.dispose();
    super.dispose();
  }

  static const _roomErrorMessages = {
    'room_not_found': 'Room not found — check the code and try again.',
    'room_full': 'That room is already full.',
    'already_in_room': "You're already in a room — leave it first.",
    'not_host': 'Only the host can start the match.',
    'not_ready': 'Both players must be ready before the match can start.',
  };

  void _onRoomChanged() {
    final roomProvider = context.read<RoomProvider>();

    final errorCode = roomProvider.errorCode;
    if (errorCode != null) {
      final xpNeeded = roomProvider.errorXpNeeded;
      roomProvider.clearError();
      final message = errorCode == 'insufficient_xp_for_room'
          ? "You've used today's 5 free rooms and don't have enough XP (${xpNeeded ?? 10}) to create another."
          : _roomErrorMessages[errorCode] ??
                'Something went wrong — please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      if (errorCode == 'insufficient_xp_for_room') {
        Navigator.of(context).pop();
      }
      return;
    }

    if (roomProvider.xpChargedAmount != null) {
      final amount = roomProvider.xpChargedAmount!;
      roomProvider.clearXpCharge();
      context.read<SessionState>().refreshProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Today's free rooms are used — $amount XP charged for this one.",
          ),
        ),
      );
    }

    if (roomProvider.closedReason != null && mounted && !_hasNavigated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room closed (${roomProvider.closedReason})')),
      );
      Navigator.of(context).pop();
    }
  }

  void _onMatchChanged() {
    final matchProvider = context.read<MatchProvider>();
    if (!_hasNavigated && matchProvider.status == MatchmakingStatus.active) {
      _hasNavigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MultiplayerGameplayScreen()),
      );
    }
  }

  void _switchMode(bool host) {
    if (_isHost == host) return;
    final roomProvider = context.read<RoomProvider>();
    if (roomProvider.code != null) roomProvider.leave();
    setState(() => _isHost = host);
  }

  void _generateCode() {
    context.read<RoomProvider>().create();
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Room code copied to clipboard',
          style: GoogleFonts.fredoka(color: Colors.black),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.primaryYellow,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _joinRoom() {
    final code = _joinCodeController.text.trim();
    if (code.length != 6) return;
    context.read<RoomProvider>().join(code);
  }

  @override
  Widget build(BuildContext context) {
    final roomProvider = context.watch<RoomProvider>();
    final myUid = context.watch<SessionState>().profile?.id;
    final isMeHost = roomProvider.host?.uid == myUid;
    final joined =
        roomProvider.code != null &&
        (isMeHost || roomProvider.guest?.uid == myUid);
    final bothReady =
        (roomProvider.host?.ready ?? false) &&
        (roomProvider.guest?.ready ?? false) &&
        roomProvider.guest != null;

    return Scaffold(
      appBar: const AppHeader(title: 'PRIVATE LOBBY'),
      body: CartoonBackground(
        mode: CartoonBackgroundMode.dashboard,
        child: SafeArea(
          child: Column(
            children: [
              if (roomProvider.disconnectedUid != null &&
                  roomProvider.disconnectedUid != myUid)
                const ReconnectingBanner(
                  text: 'Opponent disconnected — waiting to reconnect...',
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Segmented Tab Toggle (Host / Join)
                      Row(
                        children: [
                          Expanded(
                            child: CartoonButton(
                              text: 'CREATE ROOM',
                              onPressed: () => _switchMode(true),
                              variant: _isHost
                                  ? CartoonButtonVariant.primary
                                  : CartoonButtonVariant.outline,
                              height: 46,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CartoonButton(
                              text: 'JOIN ROOM',
                              onPressed: () => _switchMode(false),
                              variant: !_isHost
                                  ? CartoonButtonVariant.primary
                                  : CartoonButtonVariant.outline,
                              height: 46,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (_isHost) ...[
                        // Room Code Display Card — shows a "Generate Code" prompt
                        // until the player explicitly asks for one, rather than
                        // spending a free room the moment this screen opens.
                        CartoonCard(
                          color: AppColors.surfaceCardDark,
                          padding: const EdgeInsets.all(20),
                          child: roomProvider.code == null
                              ? Column(
                                  children: [
                                    Icon(
                                      LucideIcons.keyRound,
                                      size: 32,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Generate a room code to invite an opponent',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    CartoonButton(
                                      text: 'GENERATE CODE',
                                      onPressed: _generateCode,
                                      variant: CartoonButtonVariant.primary,
                                      width: double.infinity,
                                      height: 46,
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Text(
                                      'ROOM CODE',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                        color: AppColors.primaryOrange,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          roomProvider.code!,
                                          style: GoogleFonts.fredoka(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 4.0,
                                            color: AppColors.primaryYellow,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.copy_rounded,
                                            size: 22,
                                            color: AppColors.primaryYellow,
                                          ),
                                          onPressed: () =>
                                              _copyCode(roomProvider.code!),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            LucideIcons.userPlus,
                                            size: 22,
                                            color: AppColors.skyBlue,
                                          ),
                                          onPressed: () =>
                                              FriendInviteSheet.show(
                                                context,
                                                context
                                                    .read<SessionState>()
                                                    .apiClient,
                                                (friendUid) => roomProvider
                                                    .invite(friendUid),
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Share this 6-digit code with your opponent',
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ] else ...[
                        // Enter Join Code Card
                        CartoonCard(
                          color: AppColors.surfaceCardDark,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ENTER 6-DIGIT ROOM CODE',
                                style: GoogleFonts.fredoka(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _joinCodeController,
                                style: GoogleFonts.fredoka(
                                  fontSize: 20,
                                  letterSpacing: 3.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimaryLight,
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                onSubmitted: (_) => _joinRoom(),
                                decoration: InputDecoration(
                                  hintText: '000000',
                                  hintStyle: GoogleFonts.fredoka(
                                    color: AppColors.textMuted,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.surfaceElevated,
                                  counterText: '',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppColors.surfaceBorderDark,
                                    ),
                                  ),
                                ),
                              ),
                              if (!joined) ...[
                                const SizedBox(height: 14),
                                CartoonButton(
                                  text: 'JOIN ROOM',
                                  onPressed:
                                      _joinCodeController.text.trim().length ==
                                          6
                                      ? _joinRoom
                                      : null,
                                  variant: CartoonButtonVariant.secondary,
                                  width: double.infinity,
                                  height: 46,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      Text(
                        'LOBBY PARTICIPANTS',
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.skyBlue,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (roomProvider.host != null)
                        _buildPlayerRow(
                          name: '${roomProvider.host!.displayName} (Host)',
                          rating: '${roomProvider.host!.rating} MMR',
                          isReady: roomProvider.host!.ready,
                          onToggleReady: isMeHost
                              ? () => roomProvider.setReady(
                                  !roomProvider.host!.ready,
                                )
                              : null,
                        ),
                      const SizedBox(height: 10),
                      if (roomProvider.guest != null)
                        _buildPlayerRow(
                          name: roomProvider.guest!.displayName,
                          rating: '${roomProvider.guest!.rating} MMR',
                          isReady: roomProvider.guest!.ready,
                          onToggleReady: !isMeHost
                              ? () => roomProvider.setReady(
                                  !roomProvider.guest!.ready,
                                )
                              : null,
                        )
                      else
                        CartoonCard(
                          color: AppColors.surfaceCardDark,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              const MascotWidget(
                                pose: MascotPose.searching,
                                size: 40,
                                autoAnimate: false,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Waiting for opponent to join...',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const Spacer(),

                      // Start Match Action Button
                      CartoonButton(
                        text: isMeHost ? 'START MATCH' : 'WAITING FOR HOST',
                        onPressed: (isMeHost && bothReady)
                            ? () => roomProvider.start()
                            : null,
                        variant: CartoonButtonVariant.primary,
                        width: double.infinity,
                        height: 54,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerRow({
    required String name,
    required String rating,
    required bool isReady,
    VoidCallback? onToggleReady,
  }) {
    return CartoonCard(
      color: AppColors.surfaceCardDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryYellow,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name[0],
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.bgDarkNavy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fredoka(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rating,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isReady
                      ? AppColors.freshGreen
                      : AppColors.surfaceBorderDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isReady ? 'READY' : 'NOT READY',
                  style: GoogleFonts.fredoka(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              if (onToggleReady != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onToggleReady,
                  child: Text(
                    isReady ? 'Unready' : 'Set Ready',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.skyBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
