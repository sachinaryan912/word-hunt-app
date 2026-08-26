import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../widgets/cartoon_button.dart';
import '../widgets/cartoon_card.dart';

class FriendInviteSheet extends StatefulWidget {
  final ApiClient apiClient;
  final void Function(String friendUid, String friendDisplayName) onInvite;
  const FriendInviteSheet({super.key, required this.apiClient, required this.onInvite});

  static void show(
    BuildContext context,
    ApiClient apiClient,
    void Function(String friendUid, String friendDisplayName) onInvite,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppColors.surfaceBorderDark, width: 2),
      ),
      builder: (_) => FriendInviteSheet(apiClient: apiClient, onInvite: onInvite),
    );
  }

  @override
  State<FriendInviteSheet> createState() => _FriendInviteSheetState();
}

class _FriendInviteSheetState extends State<FriendInviteSheet> {
  List<FriendEntry> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final friends = await widget.apiClient.getFriends();
      if (!mounted) return;
      setState(() {
        _friends = friends;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INVITE A FRIEND',
                style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryYellow),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.textPrimaryLight),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(color: AppColors.surfaceBorderDark),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
                : _friends.isEmpty
                    ? Center(
                        child: Text('Add friends to invite them here', style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondaryLight)),
                      )
                    : ListView.separated(
                        itemCount: _friends.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          return CartoonCard(
                            color: AppColors.surfaceCardDark,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(friend.displayName, style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
                                    Text('${friend.rating} MMR', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondaryLight)),
                                  ],
                                ),
                                CartoonButton(
                                  text: 'INVITE',
                                  onPressed: () {
                                    widget.onInvite(friend.uid, friend.displayName);
                                    Navigator.of(context).pop();
                                  },
                                  variant: CartoonButtonVariant.primary,
                                  height: 38,
                                  fontSize: 12,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
