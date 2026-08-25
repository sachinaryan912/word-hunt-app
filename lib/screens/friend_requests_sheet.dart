import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../widgets/cartoon_button.dart';
import '../widgets/cartoon_card.dart';

class FriendRequestsSheet extends StatefulWidget {
  final ApiClient apiClient;
  final VoidCallback? onChanged;
  const FriendRequestsSheet({super.key, required this.apiClient, this.onChanged});

  static void show(BuildContext context, ApiClient apiClient, {VoidCallback? onChanged}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppColors.surfaceBorderDark, width: 2),
      ),
      builder: (_) => FriendRequestsSheet(apiClient: apiClient, onChanged: onChanged),
    );
  }

  @override
  State<FriendRequestsSheet> createState() => _FriendRequestsSheetState();
}

class _FriendRequestsSheetState extends State<FriendRequestsSheet> {
  List<FriendRequestEntry> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final requests = await widget.apiClient.getFriendRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _respond(FriendRequestEntry request, bool accept) async {
    setState(() => _requests.removeWhere((r) => r.id == request.id));
    try {
      if (accept) {
        await widget.apiClient.acceptFriendRequest(request.id);
      } else {
        await widget.apiClient.declineFriendRequest(request.id);
      }
      widget.onChanged?.call();
    } catch (_) {
      if (mounted) setState(() => _requests.add(request));
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
                'FRIEND REQUESTS',
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
                : _requests.isEmpty
                    ? Center(
                        child: Text('No pending requests', style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondaryLight)),
                      )
                    : ListView.separated(
                        itemCount: _requests.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final request = _requests[index];
                          return CartoonCard(
                            color: AppColors.surfaceCardDark,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(request.fromDisplayName, style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CartoonButton(
                                      text: 'ACCEPT',
                                      onPressed: () => _respond(request, true),
                                      variant: CartoonButtonVariant.accentGreen,
                                      height: 36,
                                      fontSize: 12,
                                    ),
                                    const SizedBox(width: 8),
                                    CartoonButton(
                                      text: 'DECLINE',
                                      onPressed: () => _respond(request, false),
                                      variant: CartoonButtonVariant.outline,
                                      height: 36,
                                      fontSize: 12,
                                    ),
                                  ],
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
