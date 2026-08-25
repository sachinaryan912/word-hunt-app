import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/match_state.dart';
import '../theme/app_colors.dart';
import '../widgets/cartoon_button.dart';

class ChatBottomSheet extends StatefulWidget {
  final ValueListenable<List<ChatMessage>> messages;
  final Function(String text) onSendMessage;

  const ChatBottomSheet({
    super.key,
    required this.messages,
    required this.onSendMessage,
  });

  static Future<void> show(BuildContext context, ValueListenable<List<ChatMessage>> messages, Function(String text) onSendMessage) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppColors.surfaceBorderDark, width: 2),
      ),
      builder: (_) => ChatBottomSheet(messages: messages, onSendMessage: onSendMessage),
    );
  }

  @override
  State<ChatBottomSheet> createState() => _ChatBottomSheetState();
}

class _ChatBottomSheetState extends State<ChatBottomSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // The sheet is built once when opened — without this listener it would
    // never show a message the opponent sends while it's still on screen,
    // since that only mutates the parent screen's state, not this route's.
    widget.messages.addListener(_onMessagesChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    widget.messages.removeListener(_onMessagesChanged);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onMessagesChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      _textController.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.messages.value;

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
                'IN-MATCH CHAT',
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryYellow,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.textPrimaryLight),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(color: AppColors.surfaceBorderDark),
          const SizedBox(height: 8),

          // Message List
          SizedBox(
            height: 220,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: msg.isUser ? AppColors.primaryYellow : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: msg.isUser ? AppColors.primaryYellowBevel : AppColors.surfaceBorderDark,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.text,
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            color: msg.isUser ? AppColors.bgDarkNavy : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            color: msg.isUser ? AppColors.bgDarkNavy.withAlpha(180) : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: GoogleFonts.fredoka(fontSize: 14, color: AppColors.textPrimaryLight),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
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
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                CartoonButton(
                  text: 'SEND',
                  onPressed: _send,
                  variant: CartoonButtonVariant.primary,
                  height: 46,
                  fontSize: 13,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
