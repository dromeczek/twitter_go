import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../repositories/friends_repository.dart';
import '../repositories/users_repository.dart';

class FriendsScreen extends StatefulWidget {
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _db = FirebaseFirestore.instance;

  late final FriendsRepository _friends;
  late final UsersRepository _users;

  final _emailCtrl = TextEditingController();
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _friends = FriendsRepository(_db);
    _users = UsersRepository(_db);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      appBar: AppBar(title: const Text('Znajomi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _inviteBox(me.uid, me.email ?? ''),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 12),

          _sectionIncoming(me.uid),
          const SizedBox(height: 12),

          _sectionFriends(me.uid),
          const SizedBox(height: 12),

          _sectionOutgoing(me.uid),
        ],
      ),
    );
  }

  Widget _inviteBox(String myUid, String myEmail) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Zaproś znajomego', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      hintText: 'email (np. test2@gmail.com)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sending ? null : () => _invite(myUid, myEmail),
                  child: _sending
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Zaproś'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _sectionIncoming(String myUid) {
    return _sectionCard(
      title: 'Zaproszenia do mnie',
      child: StreamBuilder<List<FriendRequestItem>>(
        stream: _friends.watchIncoming(myUid),
        builder: (_, snap) {
          final list = snap.data ?? const [];
          if (list.isEmpty) return const Text('Brak');
          return Column(
            children: list.map((req) {
              return _UserRow(
                users: _users,
                uid: req.fromUid,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Akceptuj',
                      icon: const Icon(Icons.check),
                      onPressed: () async {
                        setState(() => _error = null);
                        try {
                          await _friends.accept(myUid: myUid, req: req);
                        } catch (e) {
                          setState(() => _error = e.toString());
                        }
                      },
                    ),
                    IconButton(
                      tooltip: 'Odrzuć',
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        setState(() => _error = null);
                        try {
                          await _friends.decline(myUid: myUid, req: req);
                        } catch (e) {
                          setState(() => _error = e.toString());
                        }
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _sectionOutgoing(String myUid) {
    return _sectionCard(
      title: 'Wysłane zaproszenia',
      child: StreamBuilder<List<FriendRequestItem>>(
        stream: _friends.watchOutgoing(myUid),
        builder: (_, snap) {
          final list = snap.data ?? const [];
          if (list.isEmpty) return const Text('Brak');
          return Column(
            children: list.map((req) {
              return _UserRow(
                users: _users,
                uid: req.toUid,
                trailing: const Text('Oczekuje...', style: TextStyle(color: Colors.black54)),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _sectionFriends(String myUid) {
    return _sectionCard(
      title: 'Znajomi',
      child: StreamBuilder<List<String>>(
        stream: _friends.watchFriends(myUid),
        builder: (_, snap) {
          final list = snap.data ?? const [];
          if (list.isEmpty) return const Text('Brak');
          return Column(
            children: list.map((uid) => _UserRow(users: _users, uid: uid)).toList(),
          );
        },
      ),
    );
  }

  Future<void> _invite(String myUid, String myEmail) async {
    setState(() {
      _error = null;
      _sending = true;
    });

    try {
      final email = _emailCtrl.text.trim().toLowerCase();
      if (email.isEmpty) return;

      if (myEmail.toLowerCase() == email) {
        setState(() => _error = 'Nie możesz zaprosić siebie.');
        return;
      }

      final toUid = await _users.findUidByEmail(email);
      if (toUid == null) {
        setState(() => _error = 'Nie znaleziono usera z tym emailem (musi się choć raz zalogować).');
        return;
      }

      await _friends.sendRequest(fromUid: myUid, toUid: toUid);
      _emailCtrl.clear();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _UserRow extends StatelessWidget {
  final UsersRepository users;
  final String uid;
  final Widget? trailing;

  const _UserRow({
    required this.users,
    required this.uid,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: users.watchProfile(uid),
      builder: (context, snap) {
        final profile = snap.data;

        final name = (profile?.displayName.trim().isNotEmpty == true)
            ? profile!.displayName.trim()
            : 'Użytkownik';

        final email = (profile?.email.trim().isNotEmpty == true)
            ? profile!.email.trim()
            : '';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: email.isEmpty ? null : Text(email, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: trailing,
        );
      },
    );
  }
}
