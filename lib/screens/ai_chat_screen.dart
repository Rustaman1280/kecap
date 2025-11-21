import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/ai_message.dart';
import '../services/ai_chat_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({required this.user, super.key});

  final User user;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final List<AiMessage> _messages = <AiMessage>[
    const AiMessage(
      text: 'Hai! Aku Gemini siap bantu belajar bahasa Sunda. Tanyakan apa saja 🎓',
      isUser: false,
    ),
  ];
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050E16),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: _handleBottomNavTap,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _HeroHeader(user: widget.user),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B111A),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[_messages.length - 1 - index];
                          return _ChatBubble(message: msg);
                        },
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _Composer(
                      controller: _controller,
                      focusNode: _focusNode,
                      sending: _sending,
                      onSend: _handleSend,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SuggestionChips(onTap: _useSuggestion),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _useSuggestion(String prompt) {
    _controller.text = prompt;
    _controller.selection = TextSelection.collapsed(offset: prompt.length);
    _handleSend();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(AiMessage(text: text, isUser: true));
      _sending = true;
      _error = null;
    });
    _controller.clear();
    _focusNode.requestFocus();

    try {
      final reply = await AiChatService.instance.sendMessage(history: _messages, prompt: text);
      if (!mounted) return;
      setState(() {
        _messages.add(AiMessage(text: reply, isUser: false));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _sending = false;
      });
    }
  }

  void _handleBottomNavTap(int index) {
    if (index == 2) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LeaderboardScreen(user: widget.user),
        ),
      );
      return;
    }
    if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProfileScreen(user: widget.user),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur segera hadir')),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final photo = user.photoURL;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1D2E43), Color(0xFF0B111A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF152032),
              backgroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
              child: photo == null || photo.isEmpty
                  ? Text(
                      (user.displayName?.isNotEmpty ?? false)
                          ? user.displayName!.characters.first.toUpperCase()
                          : 'K',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Gemini Chat', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Belajar bahasa Sunda bareng AI, kapan saja.', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.bolt, color: Color(0xFFFFB341)),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final AiMessage message;

  @override
  Widget build(BuildContext context) {
    final bool mine = message.isUser;
    final Alignment alignment = mine ? Alignment.centerRight : Alignment.centerLeft;
    final Color bubbleColor = mine ? const Color(0xFF2BBE65) : const Color(0xFF111A24);
    final Color textColor = mine ? Colors.black : Colors.white;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: mine ? const Radius.circular(20) : const Radius.circular(6),
            bottomRight: mine ? const Radius.circular(6) : const Radius.circular(20),
          ),
          boxShadow: mine
              ? [const BoxShadow(color: Color(0x332BBE65), blurRadius: 10, offset: Offset(0, 8))]
              : [const BoxShadow(color: Color(0x33111A24), blurRadius: 12, offset: Offset(0, 8))],
        ),
        child: Text(message.text, style: TextStyle(color: textColor, height: 1.4)),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1622),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Tanyakan apa saja...',
                hintStyle: TextStyle(color: Colors.white54),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({required this.onTap});

  final ValueChanged<String> onTap;

  static const List<String> _presets = <String>[
    'Ajari aku salam sopan dalam Sunda',
    'Buat dialog pendek antara guru dan murid',
    'Ubah kalimat ini ke bahasa Sunda: "Saya mau belajar"',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final text = _presets[index];
          return ActionChip(
            label: Text(text),
            onPressed: () => onTap(text),
            backgroundColor: const Color(0xFF101A28),
            labelStyle: const TextStyle(color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: _presets.length,
      ),
    );
  }
}
