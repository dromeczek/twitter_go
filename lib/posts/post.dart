class Post {
  final String id;
  final String title;
  final String content;

  final double lat;
  final double lng;

  final double unlockRadiusMeters;

  const Post({
    required this.id,
    required this.title,
    required this.content,
    required this.lat,
    required this.lng,
    required this.unlockRadiusMeters,
  });
}
