import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
import 'ai_chat_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';

class AiHubScreen extends StatelessWidget {
  const AiHubScreen({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050E16),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (index) => _handleBottomNav(context, index),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            _HeroSection(user: user),
            const SizedBox(height: 20),
            _ModeGrid(
              onChatTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AiChatScreen(user: user)),
              ),
              onVoiceTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Voice chat segera hadir 🎙️')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleBottomNav(BuildContext context, int index) {
    if (index == 2) return;
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LeaderboardScreen(user: user),
        ),
      );
      return;
    }
    if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProfileScreen(user: user),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur segera hadir')),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final photo = user.photoURL;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2E46), Color(0xFF0A111C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 26, offset: Offset(0, 18)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF152236),
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('AI Learning Lab', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Pilih cara belajar favoritmu: chat atau suara.', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.auto_awesome, color: Color(0xFFFFB341), size: 30),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1621),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              children: const [
                Icon(Icons.tips_and_updates, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gemini membantu kamu latihan percakapan Sunda dengan gaya santai maupun formal.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeGrid extends StatelessWidget {
  const _ModeGrid({required this.onChatTap, required this.onVoiceTap});

  final VoidCallback onChatTap;
  final VoidCallback onVoiceTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ModeCard(
          title: 'Chatbot Gemini',
          description: 'Ngobrol santai, minta terjemahan, atau latihan dialog.',
          gradient: const [Color(0xFF2BBE65), Color(0xFF109C53)],
          icon: Icons.chat_bubble_outline,
          onTap: onChatTap,
          badge: 'Aktif',
        ),
        const SizedBox(height: 16),
        _ModeCard(
          title: 'Voice Chat',
          description: 'Latihan pengucapan dengan AI yang merespons suara.',
          gradient: const [Color(0xFF3B3F82), Color(0xFF1A1E45)],
          icon: Icons.graphic_eq,
          onTap: onVoiceTap,
          badge: 'Coming Soon',
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.description,
    required this.gradient,
    required this.icon,
    required this.onTap,
    required this.badge,
  });

  final String title;
  final String description;
  final List<Color> gradient;
  final IconData icon;
  final VoidCallback onTap;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 12)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(badge, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Icon(icon, color: Colors.white, size: 28),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 18),
            Row(
              children: const [
                Text('Jelajahi sekarang', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
