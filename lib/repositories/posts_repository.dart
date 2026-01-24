import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import 'friends_repository.dart';

class PostsRepository {
  final FirebaseFirestore _db;
  final FriendsRepository _friends;
  PostsRepository(this._db, this._friends);

  CollectionReference<Map<String, dynamic>> get _posts => _db.collection('posts');

Stream<List<PostModel>> watchVisiblePosts(String myUid) {
  final publicQ = _posts
      .where('visibility', isEqualTo: 'public')
      .limit(200)
      .snapshots();

  final friendsQ = _posts
      .where('visibility', isEqualTo: 'friends')
      .where('allowedUids', arrayContains: myUid)
      .limit(200)
      .snapshots();

  final controller = StreamController<List<PostModel>>.broadcast();
  final Map<String, PostModel> cache = {};

  void emit() {
    final list = cache.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // sort lokalnie
    controller.add(list);
  }

  final sub1 = publicQ.listen((snap) {
    for (final d in snap.docs) {
      cache[d.id] = PostModel.fromDoc(d);
    }
    emit();
  }, onError: controller.addError);

  final sub2 = friendsQ.listen((snap) {
    for (final d in snap.docs) {
      cache[d.id] = PostModel.fromDoc(d);
    }
    emit();
  }, onError: controller.addError);

  controller.onCancel = () async {
    await sub1.cancel();
    await sub2.cancel();
  };

  return controller.stream;
}


  Future<void> createPost({
    required String authorUid,
    required String authorDisplayName,
    required String text,
    required GeoPoint location,
    required double unlockRadiusMeters,
    required PostVisibility visibility,
  }) async {
    List<String> allowed = <String>[];

    if (visibility == PostVisibility.friends) {
      final friendUids = await _friends.getFriendsOnce(authorUid);
      allowed = <String>{authorUid, ...friendUids}.toList();
    }

    await _posts.add({
      'authorUid': authorUid,
      'authorDisplayName': authorDisplayName,
      'text': text,
      'location': location,
      'unlockRadiusMeters': unlockRadiusMeters,
      'visibility': visibility == PostVisibility.friends ? 'friends' : 'public',
      'allowedUids': allowed,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
