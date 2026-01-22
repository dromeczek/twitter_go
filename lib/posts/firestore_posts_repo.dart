import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'post.dart';

class FirestorePostsRepo {
  final _col = FirebaseFirestore.instance.collection('posts');

  Stream<List<Post>> streamPosts() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  Future<void> addPost(Post p) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'unknown';
    final email = user?.email ?? 'unknown';

    await _col.add({
      'title': p.title,
      'content': p.content,
      'lat': p.lat,
      'lng': p.lng,
      'unlockRadiusMeters': p.unlockRadiusMeters,
      'ownerUid': uid,
      'ownerEmail': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Post _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    return Post(
      id: d.id,
      title: (data['title'] ?? '').toString(),
      content: (data['content'] ?? '').toString(),
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      unlockRadiusMeters: (data['unlockRadiusMeters'] as num).toDouble(),
    );
  }
}
