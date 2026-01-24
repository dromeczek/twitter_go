import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/post_model.dart';
import '../models/user_profile.dart';
import '../repositories/friends_repository.dart';
import '../repositories/posts_repository.dart';
import '../repositories/users_repository.dart';
import '../services/location_service.dart';
import '../widgets/create_post_sheet.dart';

class MapScreen extends StatefulWidget {
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const bool fakeGpsEnabled = bool.fromEnvironment('FAKE_GPS');

  final _db = FirebaseFirestore.instance;
  final _loc = LocationService();

  late final UsersRepository _users;
  late final FriendsRepository _friends;
  late final PostsRepository _posts;

  GoogleMapController? _map;
  bool _gpsReady = false;

  LatLng _realLast = const LatLng(50.0647, 19.9450);
  LatLng? _fakeLast;

  LatLng get _currentPos => (fakeGpsEnabled && _fakeLast != null) ? _fakeLast! : _realLast;

  @override
  void initState() {
    super.initState();
    _users = UsersRepository(_db);
    _friends = FriendsRepository(_db);
    _posts = PostsRepository(_db, _friends);

    _ensureProfile();
    _refreshGps();
  }

  Future<void> _ensureProfile() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    final email = (u.email ?? '').toLowerCase();
    final display = email.isNotEmpty ? email.split('@').first : 'User';

    await _users.ensureProfile(UserProfile(uid: u.uid, email: email, displayName: display));
  }

  Future<void> _refreshGps() async {
    if (fakeGpsEnabled && _fakeLast != null) {
      _gpsReady = true;
      if (mounted) setState(() {});
      return;
    }

    try {
      final pos = await _loc.getCurrentPosition();
      _realLast = LatLng(pos.latitude, pos.longitude);
      _gpsReady = true;

      if (_map != null) {
        await _map!.animateCamera(CameraUpdate.newLatLngZoom(_realLast, 16));
      }
      if (mounted) setState(() {});
    } catch (e) {
      _gpsReady = false;
      if (mounted) setState(() {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GPS error: $e')));
    }
  }

  void _setFake(LatLng p) {
    if (!fakeGpsEnabled) return;
    setState(() {
      _fakeLast = p;
      _gpsReady = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('FAKE: ${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}')),
    );
  }

  Future<void> _addPost() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    if (!_gpsReady && !(fakeGpsEnabled && _fakeLast != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak lokalizacji. Ustaw FAKE (long-press) albo włącz GPS.')),
      );
      return;
    }

    final res = await showModalBottomSheet<CreatePostResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreatePostSheet(),
    );
    if (res == null) return;

    await _posts.createPost(
      authorUid: u.uid,
      authorDisplayName: res.displayName,
      text: res.text,
      location: GeoPoint(_currentPos.latitude, _currentPos.longitude),
      unlockRadiusMeters: res.radiusMeters,
      visibility: res.visibility,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.visibility == PostVisibility.friends ? 'Post friends-only dodany.' : 'Post public dodany.')),
    );
  }

  double _metersBetween(LatLng a, GeoPoint b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  void _showPostDetails(PostModel p, double distanceMeters) {
    final unlocked = distanceMeters <= p.unlockRadiusMeters;
    final missing = (distanceMeters - p.unlockRadiusMeters);
    final missingText = missing > 0 ? '${missing.toStringAsFixed(0)} m' : '0 m';

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.authorDisplayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Widoczność: ${p.visibility.name}'),
            Text('Promień: ${p.unlockRadiusMeters.toStringAsFixed(0)} m'),
            Text('Dystans do Ciebie: ${distanceMeters.toStringAsFixed(0)} m'),
            const SizedBox(height: 12),

            if (!unlocked) ...[
              const Text('🔒 ZABLOKOWANE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Podejdź bliżej: brakuje $missingText'),
            ] else ...[
              Text(p.text, style: const TextStyle(fontSize: 16)),
            ],

            const SizedBox(height: 12),
            Text(
              'Lokacja: ${p.location.latitude.toStringAsFixed(5)}, ${p.location.longitude.toStringAsFixed(5)}',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      appBar: AppBar(
        title: Text(fakeGpsEnabled ? 'Twitter GO (FAKE_GPS)' : 'Twitter GO'),
        actions: [
          IconButton(icon: const Icon(Icons.people), onPressed: () => Navigator.pushNamed(context, '/friends')),
          IconButton(icon: const Icon(Icons.person), onPressed: () => Navigator.pushNamed(context, '/profile')),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(heroTag: 'gps', onPressed: _refreshGps, child: const Icon(Icons.my_location)),
          const SizedBox(height: 10),
          FloatingActionButton(heroTag: 'add', onPressed: _addPost, child: const Icon(Icons.add)),
        ],
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: _posts.watchVisiblePosts(u.uid),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final myPos = _currentPos;

          final markers = snap.data!.map((p) {
            final d = _metersBetween(myPos, p.location);
            final unlocked = d <= p.unlockRadiusMeters;

            // ✅ NIE WYCIEKA TREŚĆ: snippet nigdy nie zawiera p.text
            final snippet = unlocked
                ? '✅ ODLOKOWANE • ${d.toStringAsFixed(0)}m / ${p.unlockRadiusMeters.toStringAsFixed(0)}m'
                : '🔒 ZABLOKOWANE • ${d.toStringAsFixed(0)}m / ${p.unlockRadiusMeters.toStringAsFixed(0)}m';

            return Marker(
              markerId: MarkerId(p.id),
              position: LatLng(p.location.latitude, p.location.longitude),
              infoWindow: InfoWindow(
                title: p.authorDisplayName,
                snippet: snippet,
                onTap: () => _showPostDetails(p, d),
              ),
            );
          }).toSet();

          markers.add(
            Marker(
              markerId: const MarkerId('me'),
              position: myPos,
              infoWindow: InfoWindow(title: fakeGpsEnabled ? 'ME (FAKE)' : 'ME'),
            ),
          );

          return GoogleMap(
            initialCameraPosition: CameraPosition(target: myPos, zoom: 14),
            onMapCreated: (c) => _map = c,
            myLocationEnabled: !fakeGpsEnabled && _gpsReady,
            myLocationButtonEnabled: false,
            onLongPress: fakeGpsEnabled ? _setFake : null,
            markers: markers,
          );
        },
      ),
    );
  }
}
