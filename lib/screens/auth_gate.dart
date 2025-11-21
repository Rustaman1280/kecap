import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/user_progress_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthScaffold(child: CircularProgressIndicator());
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        // Prime the user document in Firestore (ignore errors silently here).
        UserProgressService.instance.ensureUserDocument(user);
        return HomeScreen(user: user);
      },
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1821),
      body: Center(child: child),
    );
  }
}
