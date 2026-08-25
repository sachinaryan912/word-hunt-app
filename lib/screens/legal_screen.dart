import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/cartoon_background.dart';

const String privacyPolicyText = '''
Effective date: August 24, 2026

Word Hunting ("we", "our", "the app") is a word-search game published by Cluifyy. This policy explains what data we collect and how it's used.

WHAT WE COLLECT
• Account info: a unique player ID, and — if you sign in with Google — your name, email address, and profile photo. Guest players are identified only by an anonymous device-linked ID.
• Gameplay data: scores, levels completed, match history, rating, XP, and achievements, so your progress and leaderboard position can be saved and synced across sessions.
• Device token: a push-notification token (Firebase Cloud Messaging), used only to deliver game-related notifications you've enabled.
• Advertising data: if you interact with ads, our ad partner (Google AdMob) may collect device identifiers and usage data under its own privacy policy.

HOW WE USE IT
Solely to run the game: authenticate you, save your progress, power multiplayer matches and leaderboards, send optional notifications, and show ads. We do not sell your personal data.

DATA SHARING
We share data only with the service providers that run the app — Google Firebase (authentication, database, notifications) and Google AdMob (advertising) — under their respective privacy policies.

DATA RETENTION & DELETION
Your data is retained while your account is active. To request deletion of your account and associated data, contact us using the details below.

CHILDREN'S PRIVACY
Word Hunting is not directed at children under 13. We do not knowingly collect personal data from children under 13.

CHANGES
We may update this policy from time to time; continued use of the app after a change means you accept the update.

CONTACT
Questions about this policy? Reach us at cluifyy@gmail.com.
''';

const String termsOfServiceText = '''
Effective date: August 24, 2026

By using Word Hunting ("the app"), published by Cluifyy, you agree to these terms.

1. ACCOUNTS
You may play as a guest or sign in with Google. You're responsible for keeping your account secure. One account per person — creating multiple accounts to manipulate rankings or rewards is not allowed.

2. FAIR PLAY
Cheating, exploiting bugs, using automation/bots, or abusing other players (harassment, offensive usernames, cheating in matches) may result in suspension or a permanent ban, at our discretion.

3. VIRTUAL CURRENCY (XP)
XP earned in the app has no real-world monetary value, cannot be exchanged for cash, and may be adjusted or reset if we detect abuse of the reward or economy systems.

4. ADVERTISING
The app may show ads (including rewarded video ads) supplied by Google AdMob. Ad availability isn't guaranteed at all times.

5. AVAILABILITY
We aim to keep the app and its multiplayer services running smoothly but don't guarantee uninterrupted availability. Features may change, be added, or be removed over time.

6. TERMINATION
We may suspend or terminate access for violation of these terms. You may stop using the app and request account deletion at any time.

7. DISCLAIMER
The app is provided "as is" without warranties of any kind, to the extent permitted by law.

8. CHANGES TO THESE TERMS
We may update these terms; continued use after a change means you accept the update.

CONTACT
Questions about these terms? Reach us at cluifyy@gmail.com.
''';

class LegalScreen extends StatelessWidget {
  final String title;
  final String body;
  const LegalScreen({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: title),
      body: CartoonBackground(
        mode: CartoonBackgroundMode.functional,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              body,
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                height: 1.6,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
