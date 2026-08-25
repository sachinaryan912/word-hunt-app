import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/api_client.dart';
import '../services/sound_service.dart';
import '../services/update_service.dart';
import '../state/session_state.dart';
import '../widgets/app_header.dart';
import '../widgets/cartoon_background.dart';
import '../widgets/cartoon_button.dart';
import '../widgets/cartoon_card.dart';
import '../widgets/cartoon_dialog.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/mascot_widget.dart';
import 'contact_support_screen.dart';
import 'help_faq_screen.dart';
import 'legal_screen.dart';
import 'splash_screen.dart';

/// Must match USERNAME_CHANGE_COST_XP in word-hunting-server/src/lib/avatars.ts.
const int usernameChangeCostXp = 100;

class SettingsScreen extends StatefulWidget {
  final bool isEmbedded;
  const SettingsScreen({super.key, this.isEmbedded = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _musicEnabled = true;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _isLinkingGoogle = false;
  bool _isCheckingUpdate = false;
  String _versionLabel = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _versionLabel = 'WORD HUNTING v${info.version} (Build ${info.buildNumber})');
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool('pref_notifications') ?? true;
      _musicEnabled = prefs.getBool('pref_music') ?? true;
      _soundEnabled = prefs.getBool('pref_sound') ?? true;
      _hapticsEnabled = prefs.getBool('pref_haptics') ?? true;
    });
  }

  Future<void> _setPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _handleAccountTap() async {
    final session = context.read<SessionState>();
    if (!session.isAnonymous) return;
    setState(() => _isLinkingGoogle = true);
    LoadingOverlay.show(context);
    try {
      await session.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        LoadingOverlay.hide(context);
        setState(() => _isLinkingGoogle = false);
      }
    }
  }

  Future<void> _handleChangeUsername() async {
    final controller = TextEditingController(text: context.read<SessionState>().profile?.name ?? '');
    final newName = await CartoonDialog.show<String>(
      context: context,
      mascotPose: MascotPose.idle,
      title: 'CHANGE USERNAME',
      subtitle: 'Costs $usernameChangeCostXp XP',
      content: TextField(
        controller: controller,
        maxLength: 24,
        autofocus: true,
        style: GoogleFonts.fredoka(fontSize: 15, color: AppColors.textPrimaryLight),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surfaceElevated,
          counterStyle: GoogleFonts.nunito(color: AppColors.textSecondaryLight),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
      primaryButtonText: 'SAVE ($usernameChangeCostXp XP)',
      onPrimaryPressed: () => Navigator.of(context).pop(controller.text.trim()),
      secondaryButtonText: 'CANCEL',
      onSecondaryPressed: () => Navigator.of(context).pop(),
    );
    if (newName == null || newName.isEmpty || !mounted) return;

    LoadingOverlay.show(context);
    try {
      final apiClient = context.read<ApiClient>();
      final session = context.read<SessionState>();
      await apiClient.patchMe(displayName: newName);
      if (!mounted) return;
      await session.refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username updated!')));
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = e.statusCode == 402
          ? 'Not enough XP to change your username (needs $usernameChangeCostXp XP).'
          : 'Could not update username.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update username — try again.')),
      );
    } finally {
      if (mounted) LoadingOverlay.hide(context);
    }
  }

  Future<void> _checkForUpdate() async {
    if (_isCheckingUpdate) return;
    setState(() => _isCheckingUpdate = true);
    LoadingOverlay.show(context);
    try {
      final result = await context.read<UpdateService>().check();
      if (!mounted) return;
      LoadingOverlay.hide(context);
      if (result.updateAvailable) {
        await CartoonDialog.show(
          context: context,
          mascotPose: MascotPose.idle,
          title: result.mandatory ? 'UPDATE REQUIRED' : 'UPDATE AVAILABLE',
          subtitle: 'A new version of Word Hunting is ready.',
          primaryButtonText: 'UPDATE NOW',
          onPrimaryPressed: () => context.read<UpdateService>().openUpdateUrl(result.updateUrl),
          secondaryButtonText: result.mandatory ? null : 'LATER',
          onSecondaryPressed: result.mandatory ? null : () => Navigator.of(context).pop(),
          barrierDismissible: !result.mandatory,
          preventPop: result.mandatory,
        );
      } else {
        await CartoonDialog.show(
          context: context,
          mascotPose: MascotPose.celebrating,
          title: "YOU'RE UP TO DATE!",
          subtitle: '${result.currentVersionLabel} is the latest version.',
          primaryButtonText: 'NICE!',
          onPrimaryPressed: () => Navigator.of(context).pop(),
        );
      }
    } catch (_) {
      if (!mounted) return;
      LoadingOverlay.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not check for updates — try again later.')),
      );
    } finally {
      if (mounted) {
        LoadingOverlay.hide(context);
        setState(() => _isCheckingUpdate = false);
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await CartoonDialog.show<bool>(
      context: context,
      mascotPose: MascotPose.idle,
      title: 'LOG OUT?',
      subtitle: "You'll need to sign back in to continue playing on this device.",
      primaryButtonText: 'LOG OUT',
      onPrimaryPressed: () => Navigator.of(context).pop(true),
      secondaryButtonText: 'CANCEL',
      onSecondaryPressed: () => Navigator.of(context).pop(false),
    );
    if (confirmed != true || !mounted) return;

    await context.read<SessionState>().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isEmbedded ? null : const AppHeader(title: 'SETTINGS'),
      body: CartoonBackground(
        mode: CartoonBackgroundMode.functional,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              if (widget.isEmbedded)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'SETTINGS',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppColors.primaryYellow,
                    ),
                  ),
                ),
              _buildSectionHeader('PREFERENCES'),
              _buildToggleRow(
                icon: LucideIcons.bell,
                title: 'Push Notifications',
                value: _notificationsEnabled,
                onChanged: (val) {
                  setState(() => _notificationsEnabled = val);
                  _setPref('pref_notifications', val);
                  context.read<ApiClient>().updateNotificationsEnabled(val);
                },
              ),
              _buildToggleRow(
                icon: LucideIcons.music,
                title: 'Background Music',
                value: _musicEnabled,
                onChanged: (val) {
                  setState(() => _musicEnabled = val);
                  _setPref('pref_music', val);
                  context.read<SoundService>().setMusicEnabled(val);
                },
              ),
              _buildToggleRow(
                icon: LucideIcons.volume2,
                title: 'Sound Effects',
                value: _soundEnabled,
                onChanged: (val) {
                  setState(() => _soundEnabled = val);
                  _setPref('pref_sound', val);
                  context.read<SoundService>().setSoundEnabled(val);
                },
              ),
              _buildToggleRow(
                icon: LucideIcons.smartphone,
                title: 'Haptic Feedback',
                value: _hapticsEnabled,
                onChanged: (val) {
                  setState(() => _hapticsEnabled = val);
                  _setPref('pref_haptics', val);
                },
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('ACCOUNT & SECURITY'),
              Consumer<SessionState>(
                builder: (context, session, _) {
                  final subtitle = _isLinkingGoogle
                      ? 'Linking Google account…'
                      : (session.isAnonymous ? 'Guest account — tap to link Google' : (session.email ?? 'Google account linked'));
                  return _buildNavigationRow(
                    icon: LucideIcons.user,
                    title: 'Account Information',
                    subtitle: subtitle,
                    onTap: session.isAnonymous ? _handleAccountTap : null,
                  );
                },
              ),
              _buildNavigationRow(
                icon: LucideIcons.edit3,
                title: 'Change Username',
                subtitle: 'Costs $usernameChangeCostXp XP',
                onTap: _handleChangeUsername,
              ),
              _buildNavigationRow(
                icon: LucideIcons.globe,
                title: 'Language',
                subtitle: 'English (US)',
              ),
              _buildNavigationRow(
                icon: LucideIcons.shieldCheck,
                title: 'Privacy Policy',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LegalScreen(title: 'PRIVACY POLICY', body: privacyPolicyText)),
                ),
              ),
              _buildNavigationRow(
                icon: LucideIcons.fileText,
                title: 'Terms of Service',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LegalScreen(title: 'TERMS OF SERVICE', body: termsOfServiceText)),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('SUPPORT'),
              _buildNavigationRow(
                icon: LucideIcons.helpCircle,
                title: 'Help & FAQ',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HelpFaqScreen()),
                ),
              ),
              _buildNavigationRow(
                icon: LucideIcons.mail,
                title: 'Contact Support',
                subtitle: supportEmail,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ContactSupportScreen()),
                ),
              ),
              _buildNavigationRow(
                icon: LucideIcons.refreshCw,
                title: 'Check for Updates',
                subtitle: _versionLabel.isEmpty ? null : _versionLabel,
                onTap: _checkForUpdate,
              ),

              const SizedBox(height: 32),
              // Logout Button
              CartoonButton(
                text: 'LOG OUT',
                icon: LucideIcons.logOut,
                onPressed: _confirmLogout,
                variant: CartoonButtonVariant.accentRed,
                width: double.infinity,
                height: 50,
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _versionLabel,
                  style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
              ),
            ].animate(interval: 50.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: GoogleFonts.fredoka(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.primaryOrange,
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return CartoonCard(
      color: AppColors.surfaceCardDark,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.skyBlue),
              const SizedBox(width: 14),
              Text(
                title,
                style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primaryYellow,
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.surfaceElevated,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRow({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return CartoonCard(
      color: AppColors.surfaceCardDark,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap ?? () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.skyBlue),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
