import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/auth_gate.dart';
import 'screens/friends_screen.dart';
import 'screens/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(TwitterGoApp());
}

class TwitterGoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Twitter GO',
      debugShowCheckedModeBanner: false,
      routes: {
        '/friends': (_) => FriendsScreen(),
        '/profile': (_) => ProfileScreen(),
      },
      home: AuthGate(),
    );
  }
}
