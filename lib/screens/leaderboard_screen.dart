import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/leaderboard_entry.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/cartoon_background.dart';
import '../widgets/cartoon_card.dart';
import '../widgets/state_indicators.dart';
import 'friend_search_sheet.dart';
import 'friend_requests_sheet.dart';

class LeaderboardScreen extends StatefulWidget {
  final bool isEmbedded;
  const LeaderboardScreen({super.key, this.isEmbedded = false});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  LeaderboardTab _activeTab = LeaderboardTab.global;
  LeaderboardPeriod _activePeriod = LeaderboardPeriod.weekly;
  List<LeaderboardEntry> _entries = [];
  LeaderboardEntry? _me;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _periodParam {
    if (_activeTab == LeaderboardTab.friends) return 'global';
    switch (_activePeriod) {
      case LeaderboardPeriod.daily:
        return 'daily';
      case LeaderboardPeriod.weekly:
        return 'weekly';
      case LeaderboardPeriod.monthly:
        return 'monthly';
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final result = await context.read<ApiClient>().getLeaderboard(
            period: _periodParam,
            scope: _activeTab == LeaderboardTab.friends ? 'friends' : 'all',
          );
      if (!mounted) return;
      setState(() {
        _entries = result.entries;
        _me = result.me;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _switchTab(LeaderboardTab tab) {
    if (_activeTab == tab) return;
    setState(() => _activeTab = tab);
    _load();
  }

  void _switchPeriod(LeaderboardPeriod period) {
    if (_activePeriod == period) return;
    setState(() => _activePeriod = period);
    if (_activeTab == LeaderboardTab.global) _load();
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = context.read<ApiClient>();

    return Scaffold(
      appBar: widget.isEmbedded ? null : const AppHeader(title: 'LEADERBOARD', showBack: false),
      body: CartoonBackground(
        mode: CartoonBackgroundMode.dashboard,
        child: SafeArea(
          child: Column(
            children: [
              if (widget.isEmbedded)
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    'LEADERBOARD',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppColors.primaryYellow,
                    ),
                  ),
                ),

              // Segmented Tabs (Global / Friends)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildTextTab('GLOBAL', LeaderboardTab.global),
                        const SizedBox(width: 24),
                        _buildTextTab('FRIENDS', LeaderboardTab.friends),
                      ],
                    ),
                    if (_activeTab == LeaderboardTab.friends)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.inbox, size: 20, color: AppColors.textSecondaryLight),
                            onPressed: () => FriendRequestsSheet.show(context, apiClient, onChanged: _load),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.userPlus, size: 20, color: AppColors.skyBlue),
                            onPressed: () => FriendSearchSheet.show(context, apiClient),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const Divider(color: AppColors.surfaceBorderDark),

              // Filter Chips (Daily / Weekly / Monthly)
              if (_activeTab == LeaderboardTab.global)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      _buildPeriodChip('Daily', LeaderboardPeriod.daily),
                      const SizedBox(width: 8),
                      _buildPeriodChip('Weekly', LeaderboardPeriod.weekly),
                      const SizedBox(width: 8),
                      _buildPeriodChip('Monthly', LeaderboardPeriod.monthly),
                    ],
                  ),
                ),

              // Ranked List
              Expanded(
                child: _isLoading
                    ? ListView.builder(
                        itemCount: 8,
                        itemBuilder: (context, index) => const SkeletonListTile(),
                      )
                    : _entries.isEmpty
                        ? EmptyStateView(
                            title: _activeTab == LeaderboardTab.friends ? 'No friends yet' : 'No rankings yet',
                            description: _activeTab == LeaderboardTab.friends
                                ? 'Add friends to see how you compare.'
                                : 'Play a ranked match to appear on the leaderboard.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: _entries.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final entry = _entries[index];
                              final isTop3 = entry.rank <= 3;
                              final rankColor = entry.rank == 1
                                  ? AppColors.primaryYellow
                                  : entry.rank == 2
                                      ? AppColors.skyBlue
                                      : entry.rank == 3
                                          ? AppColors.primaryOrange
                                          : AppColors.textMuted;

                              return CartoonCard(
                                color: entry.isCurrentUser ? AppColors.royalBlue : AppColors.surfaceCardDark,
                                bevelColor: entry.isCurrentUser ? AppColors.royalBlueBevel : AppColors.surfaceBorderDark,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                child: Row(
                                  children: [
                                    // Rank Badge
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isTop3) ...[
                                          Icon(LucideIcons.trophy, size: 16, color: rankColor),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          '#${entry.rank}',
                                          style: GoogleFonts.fredoka(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: rankColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    // Player Name
                                    Expanded(
                                      child: Text(
                                        entry.playerName,
                                        style: GoogleFonts.fredoka(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimaryLight,
                                        ),
                                      ),
                                    ),
                                    // Score / Rating
                                    Text(
                                      '${entry.rating} MMR',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryYellow,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              // Sticky Current User Bottom Row
              if (_me != null)
                CartoonCard(
                  color: AppColors.royalBlue,
                  bevelColor: AppColors.royalBlueBevel,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Text(
                        '#${_me!.rank}',
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryYellow,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _me!.playerName,
                              style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            Text(
                              'Your Current Standing',
                              style: GoogleFonts.nunito(fontSize: 12, color: Colors.white.withAlpha(200)),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_me!.rating} MMR',
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryYellow,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextTab(String label, LeaderboardTab tab) {
    final isSelected = _activeTab == tab;
    return GestureDetector(
      onTap: () => _switchTab(tab),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isSelected ? AppColors.primaryYellow : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 3,
            width: 36,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryYellow : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, LeaderboardPeriod period) {
    final isSelected = _activePeriod == period;
    return GestureDetector(
      onTap: () => _switchPeriod(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryYellow : AppColors.surfaceCardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryYellowBevel : AppColors.surfaceBorderDark,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.bgDarkNavy : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}
