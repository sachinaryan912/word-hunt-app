import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../state/session_state.dart';
import '../theme/app_colors.dart';
import '../widgets/avatar_display.dart';
import '../widgets/cartoon_dialog.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/mascot_widget.dart';

class AvatarShopSheet extends StatefulWidget {
  const AvatarShopSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppColors.surfaceBorderDark, width: 2),
      ),
      builder: (_) => const AvatarShopSheet(),
    );
  }

  @override
  State<AvatarShopSheet> createState() => _AvatarShopSheetState();
}

class _AvatarShopSheetState extends State<AvatarShopSheet> {
  AvatarCatalog? _catalog;
  bool _isLoading = true;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final catalog = await context.read<ApiClient>().getAvatars();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _equip(String id) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    LoadingOverlay.show(context);
    try {
      final apiClient = context.read<ApiClient>();
      final session = context.read<SessionState>();
      await apiClient.equipAvatar(id);
      if (!mounted) return;
      await session.refreshProfile();
      if (!mounted) return;
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not equip that avatar — try again.')),
        );
      }
    } finally {
      if (mounted) {
        LoadingOverlay.hide(context);
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _confirmUnlock(AvatarEntry entry) async {
    final profile = context.read<SessionState>().profile;
    final hasEnoughXp = (profile?.xp ?? 0) >= entry.cost;

    await CartoonDialog.show(
      context: context,
      mascotPose: MascotPose.idle,
      title: 'UNLOCK AVATAR?',
      subtitle: hasEnoughXp
          ? 'Spend ${entry.cost} XP to unlock this avatar.'
          : 'You need ${entry.cost} XP to unlock this avatar.',
      primaryButtonText: hasEnoughXp ? 'UNLOCK (${entry.cost} XP)' : null,
      onPrimaryPressed: hasEnoughXp
          ? () {
              Navigator.of(context).pop();
              _unlockAndEquip(entry.id);
            }
          : null,
      secondaryButtonText: 'CLOSE',
      onSecondaryPressed: () => Navigator.of(context).pop(),
    );
  }

  Future<void> _unlockAndEquip(String id) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    LoadingOverlay.show(context);
    try {
      final apiClient = context.read<ApiClient>();
      final session = context.read<SessionState>();
      await apiClient.unlockAvatar(id);
      if (!mounted) return;
      await apiClient.equipAvatar(id);
      if (!mounted) return;
      await session.refreshProfile();
      if (!mounted) return;
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        final message = e.statusCode == 402 ? 'Not enough XP for that avatar.' : 'Could not unlock that avatar.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not unlock that avatar — try again.')),
        );
      }
    } finally {
      if (mounted) {
        LoadingOverlay.hide(context);
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final xp = context.watch<SessionState>().profile?.xp ?? 0;

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
              Text('AVATAR SHOP', style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryYellow)),
              Row(
                children: [
                  Icon(LucideIcons.star, size: 16, color: AppColors.primaryYellow),
                  const SizedBox(width: 4),
                  Text('$xp XP', style: GoogleFonts.fredoka(fontSize: 14, color: AppColors.primaryYellow)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.textPrimaryLight),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: AppColors.surfaceBorderDark),
          const SizedBox(height: 8),
          SizedBox(
            height: 420,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
                : _catalog == null
                    ? const Center(
                        child: Text('Could not load avatars.', style: TextStyle(color: AppColors.textSecondaryLight)),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: _catalog!.avatars.length,
                        itemBuilder: (context, index) {
                          final entry = _catalog!.avatars[index];
                          final isEquipped = _catalog!.equipped == entry.id;
                          return GestureDetector(
                            onTap: _isBusy
                                ? null
                                : () => entry.unlocked ? _equip(entry.id) : _confirmUnlock(entry),
                            child: Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isEquipped ? AppColors.primaryYellow : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: Opacity(
                                        opacity: entry.unlocked ? 1.0 : 0.45,
                                        child: AvatarDisplay(avatarId: entry.id, fallbackInitial: '?', size: 56),
                                      ),
                                    ),
                                    if (!entry.unlocked)
                                      const Positioned(
                                        right: -2,
                                        bottom: -2,
                                        child: Icon(LucideIcons.lock, size: 16, color: AppColors.textSecondaryLight),
                                      ),
                                    if (isEquipped)
                                      const Positioned(
                                        right: -2,
                                        bottom: -2,
                                        child: Icon(LucideIcons.checkCircle2, size: 16, color: AppColors.freshGreen),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  entry.unlocked ? (isEquipped ? 'EQUIPPED' : 'TAP TO WEAR') : '${entry.cost} XP',
                                  style: GoogleFonts.nunito(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondaryLight),
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
