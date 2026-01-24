import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../repositories/users_repository.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = FirebaseFirestore.instance;
  late final UsersRepository _users;

  final _nameCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _users = UsersRepository(_db);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: StreamBuilder<UserProfile?>(
        stream: _users.watchProfile(u.uid),
        builder: (_, snap) {
          final profile = snap.data;
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_nameCtrl.text.isEmpty) _nameCtrl.text = profile.displayName;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${profile.email}'),
                const SizedBox(height: 6),
                Text('UID: ${profile.uid}'),
                const SizedBox(height: 16),
                const Text('Display name'),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            try {
                              await _users.updateDisplayName(u.uid, _nameCtrl.text);
                            } finally {
                              if (mounted) setState(() => _saving = false);
                            }
                          },
                    child: _saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
