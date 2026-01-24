import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email.trim().toLowerCase(),
        'displayName': displayName.trim().isEmpty ? 'User' : displayName.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

  static UserProfile fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile(
      uid: (data['uid'] as String?) ?? doc.id,
      email: (data['email'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? 'User',
    );
  }
}
