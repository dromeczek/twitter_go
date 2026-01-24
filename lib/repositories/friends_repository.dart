import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestItem {
  final String id;
  final String fromUid;
  final String toUid;

  FriendRequestItem({
    required this.id,
    required this.fromUid,
    required this.toUid,
  });

  static FriendRequestItem fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return FriendRequestItem(
      id: doc.id,
      fromUid: (d['fromUid'] as String?) ?? '',
      toUid: (d['toUid'] as String?) ?? '',
    );
  }
}

class FriendsRepository {
  final FirebaseFirestore _db;
  FriendsRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _requests => _db.collection('friendRequests');
  CollectionReference<Map<String, dynamic>> get _friendships => _db.collection('friendships');

  String _requestId(String fromUid, String toUid) => '${fromUid}_$toUid';

  String _friendshipId(String a, String b) {
    final pair = [a, b]..sort();
    return '${pair[0]}_${pair[1]}';
  }

  // -------------------- FRIENDS --------------------

  Stream<List<String>> watchFriends(String myUid) {
    return _friendships.where('uids', arrayContains: myUid).snapshots().map((snap) {
      final out = <String>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final uids = List<String>.from((data['uids'] ?? const []) as List);
        final other = uids.firstWhere((u) => u != myUid, orElse: () => '');
        if (other.isNotEmpty) out.add(other);
      }
      return out;
    });
  }

  /// ✅ potrzebne dla PostsRepository (friends-only allowedUids)
  Future<List<String>> getFriendsOnce(String myUid) async {
    final snap = await _friendships.where('uids', arrayContains: myUid).get();
    final out = <String>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final uids = List<String>.from((data['uids'] ?? const []) as List);
      final other = uids.firstWhere((u) => u != myUid, orElse: () => '');
      if (other.isNotEmpty) out.add(other);
    }
    return out;
  }

  // -------------------- REQUESTS --------------------

  Stream<List<FriendRequestItem>> watchIncoming(String myUid) {
    return _requests
        .where('toUid', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map(FriendRequestItem.fromDoc).toList());
  }

  Stream<List<FriendRequestItem>> watchOutgoing(String myUid) {
    return _requests
        .where('fromUid', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map(FriendRequestItem.fromDoc).toList());
  }

  Future<void> sendRequest({required String fromUid, required String toUid}) async {
    if (fromUid == toUid) return;

    // already friends?
    final fId = _friendshipId(fromUid, toUid);
    final friendship = await _friendships.doc(fId).get();
    if (friendship.exists) return;

    final rId = _requestId(fromUid, toUid);
    final reqRef = _requests.doc(rId);

    // already requested?
    final reqSnap = await reqRef.get();
    if (reqSnap.exists) return;

    await reqRef.set({
      'fromUid': fromUid,
      'toUid': toUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> accept({required String myUid, required FriendRequestItem req}) async {
    if (req.toUid != myUid) return;

    final reqRef = _requests.doc(req.id);
    final fId = _friendshipId(req.fromUid, req.toUid);
    final fRef = _friendships.doc(fId);

    final batch = _db.batch();
    batch.update(reqRef, {'status': 'accepted'});
    batch.set(fRef, {
      'uids': [req.fromUid, req.toUid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> decline({required String myUid, required FriendRequestItem req}) async {
    if (req.toUid != myUid) return;
    await _requests.doc(req.id).update({'status': 'declined'});
  }
}
