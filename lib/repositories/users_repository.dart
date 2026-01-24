import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UsersRepository {
  final FirebaseFirestore _db;
  UsersRepository(this._db);

  Future<void> ensureProfile(UserProfile profile) async {
    final ref = _db.collection('users').doc(profile.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set(profile.toMap());
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      final typed = doc as DocumentSnapshot<Map<String, dynamic>>;
      if (!typed.exists) return null;
      return UserProfile.fromDoc(typed);
    });
  }

  Future<void> updateDisplayName(String uid, String displayName) async {
    await _db.collection('users').doc(uid).update({
      'displayName': displayName.trim().isEmpty ? 'User' : displayName.trim(),
    });
  }

  Future<String?> findUidByEmail(String email) async {
    final q = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return q.docs.first.id;
  }
}
