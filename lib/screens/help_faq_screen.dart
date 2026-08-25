import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/cartoon_background.dart';
import '../widgets/cartoon_card.dart';

class _FaqEntry {
  final String question;
  final String answer;
  const _FaqEntry(this.question, this.answer);
}

const _faqEntries = [
  _FaqEntry(
    'How do I play a word search?',
    'Drag your finger across the letters to trace a word in any direction — up, down, sideways, or diagonal. Find every word in the list to clear the board.',
  ),
  _FaqEntry(
    'What\'s the difference between Solo Play and Quick Match?',
    'Solo Play is you against the board, at your own pace, working through levels. Quick Match pairs you with a real opponent — whoever finds more words in the time limit wins rating.',
  ),
  _FaqEntry(
    'How does a Private Room work?',
    'Create a room to get a 6-digit code, then share it (or send an in-app invite to a friend). Once you\'re both marked ready, the host can start the match. Private Room matches have no time limit — take as long as you need.',
  ),
  _FaqEntry(
    'How many private rooms can I create per day?',
    'You get 5 free rooms every day. After that, creating another room costs a small amount of XP.',
  ),
  _FaqEntry(
    'How is my rating calculated?',
    'Your rating (MMR) goes up when you win a multiplayer match and down when you lose, based on your opponent\'s rating — beating a higher-rated player earns more.',
  ),
  _FaqEntry(
    'What is the Daily Challenge?',
    'A new editorial puzzle every day, the same for all players, with no time limit and a global leaderboard. It refreshes every 24 hours at midnight UTC.',
  ),
  _FaqEntry(
    'How do I earn XP?',
    'Completing solo levels, winning matches, finishing the Daily Challenge, and claiming your daily gift all earn XP. XP is used for things like extra private rooms and username changes.',
  ),
  _FaqEntry(
    'I lost connection mid-match — did I lose?',
    'You get a short grace period to reconnect from the same screen. If you don\'t reconnect in time, the match is scored as a forfeit.',
  ),
  _FaqEntry(
    'How do I report a player?',
    'On the match result screen, tap the flag icon next to your opponent\'s name and choose a reason. Our team reviews every report.',
  ),
  _FaqEntry(
    'How do I delete my account or data?',
    'Contact support with the email tied to your account and we\'ll take care of it — see Contact Support in Settings.',
  ),
];

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'HELP & FAQ'),
      body: CartoonBackground(
        mode: CartoonBackgroundMode.functional,
        child: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _faqEntries.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = _faqEntries[index];
              final isExpanded = _expandedIndex == index;
              return CartoonCard(
                color: AppColors.surfaceCardDark,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.question,
                            style: GoogleFonts.fredoka(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                          size: 18,
                          color: AppColors.primaryYellow,
                        ),
                      ],
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox(width: double.infinity, height: 0),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          entry.answer,
                          style: GoogleFonts.nunito(fontSize: 13, height: 1.5, color: AppColors.textSecondaryLight),
                        ),
                      ),
                      crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
