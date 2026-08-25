import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/cartoon_background.dart';
import '../widgets/cartoon_button.dart';
import '../widgets/cartoon_card.dart';
import '../widgets/mascot_widget.dart';

const String supportEmail = 'cluifyy@gmail.com';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  Future<void> _emailUs(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {'subject': 'Word Hunting Support'},
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _copyEmail(context);
    }
  }

  void _copyEmail(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: supportEmail));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email copied to clipboard', style: GoogleFonts.fredoka(color: Colors.black)),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.primaryYellow,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'CONTACT SUPPORT'),
      body: CartoonBackground(
        mode: CartoonBackgroundMode.functional,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      const MascotWidget(pose: MascotPose.idle, size: 90),
                      const SizedBox(height: 12),
                      Text(
                        "NEED A HAND?",
                        style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primaryYellow),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Check Help & FAQ first — if that doesn't cover it, reach out below and we'll get back to you.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(fontSize: 13.5, height: 1.5, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                CartoonCard(
                  color: AppColors.surfaceCardDark,
                  padding: const EdgeInsets.all(20),
                  onTap: () => _copyEmail(context),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withAlpha(30),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primaryOrange, width: 1.5),
                        ),
                        child: const Icon(LucideIcons.mail, size: 22, color: AppColors.primaryOrange),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SUPPORT EMAIL',
                              style: GoogleFonts.fredoka(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: AppColors.textSecondaryLight),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              supportEmail,
                              style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.copy, size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CartoonButton(
                  text: 'EMAIL US',
                  icon: LucideIcons.send,
                  onPressed: () => _emailUs(context),
                  variant: CartoonButtonVariant.primary,
                  width: double.infinity,
                  height: 52,
                ),
                const SizedBox(height: 20),
                CartoonCard(
                  color: AppColors.surfaceElevated,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.info, size: 18, color: AppColors.primaryYellow),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'When reporting a bug, include your username and what you were doing — it helps us fix it faster.',
                          style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondaryLight, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
