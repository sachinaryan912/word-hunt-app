import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../widgets/cartoon_button.dart';
import '../widgets/cartoon_card.dart';

class FriendSearchSheet extends StatefulWidget {
  final ApiClient apiClient;
  const FriendSearchSheet({super.key, required this.apiClient});

  static void show(BuildContext context, ApiClient apiClient) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppColors.surfaceBorderDark, width: 2),
      ),
      builder: (_) => FriendSearchSheet(apiClient: apiClient),
    );
  }

  @override
  State<FriendSearchSheet> createState() => _FriendSearchSheetState();
}

class _FriendSearchSheetState extends State<FriendSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<UserSearchResult> _results = [];
  final Set<String> _sentTo = {};
  bool _isLoading = false;

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final results = await widget.apiClient.searchUsers(query.trim());
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendRequest(String uid) async {
    setState(() => _sentTo.add(uid));
    try {
      await widget.apiClient.sendFriendRequest(uid);
    } catch (_) {
      if (mounted) setState(() => _sentTo.remove(uid));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
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
                'ADD FRIEND',
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
          TextField(
            controller: _controller,
            onChanged: _onChanged,
            style: GoogleFonts.fredoka(fontSize: 14, color: AppColors.textPrimaryLight),
            decoration: InputDecoration(
              hintText: 'Search by username...',
              hintStyle: GoogleFonts.fredoka(fontSize: 13, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceElevated,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.surfaceBorderDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primaryYellow, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = _results[index];
                      final sent = _sentTo.contains(user.uid);
                      return CartoonCard(
                        color: AppColors.surfaceCardDark,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.displayName, style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
                                Text('${user.rating} MMR', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondaryLight)),
                              ],
                            ),
                            CartoonButton(
                              text: sent ? 'SENT' : 'ADD',
                              onPressed: sent ? null : () => _sendRequest(user.uid),
                              variant: sent ? CartoonButtonVariant.outline : CartoonButtonVariant.primary,
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
