import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/match_state.dart';
import '../models/word_search_grid.dart';
import '../theme/app_colors.dart';
import '../state/match_provider.dart';
import '../services/ads_service.dart';
import '../services/socket_service.dart';
import '../services/sound_service.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/cartoon_background.dart';
import '../widgets/letter_grid_widget.dart';
import '../widgets/word_list_view.dart';
import '../widgets/state_indicators.dart';
import 'chat_bottom_sheet.dart';
import 'match_result_screen.dart';

class MultiplayerGameplayScreen extends StatefulWidget {
  const MultiplayerGameplayScreen({super.key});

  @override
  State<MultiplayerGameplayScreen> createState() => _MultiplayerGameplayScreenState();
}

class _MultiplayerGameplayScreenState extends State<MultiplayerGameplayScreen> {
  Timer? _tickTimer;
  int _secondsRemaining = 0;
  bool _navigatedToResult = false;
  int _ownFoundCount = 0;
  bool _chatSheetOpen = false;
  final ValueNotifier<List<ChatMessage>> _chatMessages = ValueNotifier<List<ChatMessage>>([]);

  @override
  void initState() {
    super.initState();
    final matchProvider = context.read<MatchProvider>();
    matchProvider.addListener(_onMatchChanged);
    context.read<SocketService>().on('chat:message', _onChatMessage);
    _recomputeRemaining();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_recomputeRemaining);
    });
  }

  void _recomputeRemaining() {
    final matchProvider = context.read<MatchProvider>();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final remainingMs = matchProvider.endAt - nowMs;
    _secondsRemaining = (remainingMs / 1000).ceil().clamp(0, matchProvider.durationSeconds);
  }

  void _onMatchChanged() {
    final matchProvider = context.read<MatchProvider>();
    final ownFoundCount = matchProvider.state?.grid.foundWords.where((f) => f.claimedBy == 'player').length ?? 0;
    if (ownFoundCount > _ownFoundCount) {
      context.read<SoundService>().playWordFoundSound();
    }
    _ownFoundCount = ownFoundCount;

    if (!_navigatedToResult && matchProvider.status == MatchmakingStatus.ended) {
      _navigatedToResult = true;
      final info = matchProvider.endInfo;
      final state = matchProvider.state;
      if (info == null || state == null) return;
      final myWordsFound = state.grid.foundWords.where((f) => f.claimedBy == 'player').length;
      final totalTargets = state.grid.targetWords.length;
      // A pushReplacement only swaps out this screen's own route — if the
      // chat sheet is open (a separate route stacked on top), it would keep
      // floating over the result screen instead of being dismissed with the
      // match. Pop it first so it closes along with the match ending.
      if (_chatSheetOpen && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MatchResultScreen(
            isWin: info.isWin,
            score: info.myScore,
            wordsFoundCount: myWordsFound,
            accuracyPercent: totalTargets == 0 ? 0 : ((myWordsFound / totalTargets) * 100).round(),
            durationSeconds: matchProvider.durationSeconds - _secondsRemaining,
            opponentName: state.opponent.name,
            opponentUid: state.opponent.id,
            matchId: matchProvider.matchId,
            ratingDelta: info.myRatingDelta,
            newRating: info.myNewRating,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    context.read<MatchProvider>().removeListener(_onMatchChanged);
    context.read<SocketService>().off('chat:message');
    _chatMessages.dispose();
    super.dispose();
  }

  void _onWordSelect(String word, List<GridPos> path) {
    context.read<MatchProvider>().selectWord(path);
  }

  void _onChatMessage(dynamic data) {
    final matchState = context.read<MatchProvider>().state;
    if (matchState == null || !mounted) return;
    final json = Map<String, dynamic>.from(data as Map);
    final senderId = json['senderId'] as String;
    _chatMessages.value = [
      ..._chatMessages.value,
      ChatMessage(
        id: json['id'] as String,
        senderId: senderId,
        senderName: json['senderName'] as String,
        text: json['text'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
        isUser: senderId == matchState.player.id,
      ),
    ];
  }

  void _handleSendMessage(String text) {
    final matchId = context.read<MatchProvider>().matchId;
    if (matchId == null) return;
    context.read<SocketService>().sendChat('match-$matchId', text);
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final matchProvider = context.watch<MatchProvider>();
    final matchState = matchProvider.state;

    if (matchState == null) {
      return Scaffold(
        body: CartoonBackground(
          mode: CartoonBackgroundMode.loading,
          child: const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)),
        ),
      );
    }

    return Scaffold(
      body: CartoonBackground(
        mode: CartoonBackgroundMode.gameplay,
        child: SafeArea(
          child: Column(
            children: [
              if (!matchProvider.opponentConnected)
                const ReconnectingBanner(text: 'Opponent disconnected — waiting to reconnect...'),

              // Top Player Battle Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceCardDark,
                  border: Border(bottom: BorderSide(color: AppColors.surfaceBorderDark, width: 2.0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // You
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          matchState.player.name.toUpperCase(),
                          style: GoogleFonts.fredoka(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryYellow,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${matchState.player.score} PTS',
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),

                    // Timer Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.surfaceBorderDark),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'TIME LEFT',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            _formatTime(_secondsRemaining),
                            style: GoogleFonts.fredoka(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Opponent
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          matchState.opponent.name.toUpperCase(),
                          style: GoogleFonts.fredoka(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.skyBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${matchState.opponent.score} PTS',
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
              ),

              // Event Feed Banner
              if (matchState.recentFeed.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  color: AppColors.primaryOrange,
                  child: Text(
                    matchState.recentFeed.first,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Shared Board Hero
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LetterGridWidget(
                  grid: matchState.grid,
                  onWordSelect: _onWordSelect,
                ),
              ),

              const SizedBox(height: 16),

              // Target Words List
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        'TARGET WORDS',
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                      const SizedBox(height: 10),
                      WordListView(
                        targetWords: matchState.grid.targetWords,
                        foundWords: matchState.grid.foundWords,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Chat Action
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ValueListenableBuilder<List<ChatMessage>>(
                      valueListenable: _chatMessages,
                      builder: (context, messages, _) => IconButton(
                        icon: Stack(
                          children: [
                            const Icon(LucideIcons.messageSquare, size: 24, color: AppColors.textPrimaryLight),
                            if (messages.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryYellow,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onPressed: () {
                          _chatSheetOpen = true;
                          ChatBottomSheet.show(
                            context,
                            _chatMessages,
                            _handleSendMessage,
                          ).then((_) => _chatSheetOpen = false);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const AdBannerWidget(adUnitId: AdsService.multiplayerBannerAdUnitId),
            ],
          ),
        ),
      ),
    );
  }
}
