import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const KecapApp());
}

class KecapApp extends StatelessWidget {
  const KecapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kecap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF55DF5D),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0E1821),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
