import 'package:cloud_firestore/cloud_firestore.dart';

enum PostVisibility { public, friends }

class PostModel {
  final String id;
  final String authorUid;
  final String authorDisplayName;
  final String text;
  final GeoPoint location;
  final double unlockRadiusMeters;
  final PostVisibility visibility;
  final List<String> allowedUids;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.authorUid,
    required this.authorDisplayName,
    required this.text,
    required this.location,
    required this.unlockRadiusMeters,
    required this.visibility,
    required this.allowedUids,
    required this.createdAt,
  });

  static PostModel fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'];
    final createdAt = ts is Timestamp ? ts.toDate() : DateTime.fromMillisecondsSinceEpoch(0);

    return PostModel(
      id: doc.id,
      authorUid: (data['authorUid'] as String?) ?? '',
      authorDisplayName: (data['authorDisplayName'] as String?) ?? 'User',
      text: (data['text'] as String?) ?? '',
      location: (data['location'] as GeoPoint?) ?? const GeoPoint(0, 0),
      unlockRadiusMeters: ((data['unlockRadiusMeters'] as num?) ?? 200).toDouble(),
      visibility: (data['visibility'] as String?) == 'friends'
          ? PostVisibility.friends
          : PostVisibility.public,
      allowedUids: List<String>.from((data['allowedUids'] ?? const []) as List),
      createdAt: createdAt,
    );
  }
}
