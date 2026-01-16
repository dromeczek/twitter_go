import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:twitter_go/location/location_service.dart';
import 'package:twitter_go/posts/post.dart';
import 'package:twitter_go/posts/sample_posts.dart';
import 'package:twitter_go/utils/geo.dart';

const bool kDevFakeGps = bool.fromEnvironment('FAKE_GPS', defaultValue: false);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Twitter GO',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _locService = LocationService();

  GoogleMapController? _mapController;

  AppLocation? _realLoc;

  /// Nadpisywana lokalizacja do demo (tylko gdy kDevFakeGps == true)
  LatLng? _fakeUserPos;

  /// Posty “żywe” (startujemy od samplePosts, potem dodajesz własne)
  final List<Post> _posts = List<Post>.from(samplePosts);
  int _postSeq = 1000;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final loc = await _locService.getCurrent();
    if (!mounted) return;
    setState(() => _realLoc = loc);
  }

  LatLng? get _userPos {
    if (_realLoc == null) return null;
    final real = LatLng(_realLoc!.lat, _realLoc!.lng);
    return (kDevFakeGps && _fakeUserPos != null) ? _fakeUserPos : real;
  }

  Set<Marker> _buildMarkers(LatLng userPos) {
    final markers = <Marker>{};

    // Marker użytkownika (real lub fake)
    markers.add(
      Marker(
        markerId: const MarkerId('user'),
        position: userPos,
        infoWindow: InfoWindow(
          title: kDevFakeGps && _fakeUserPos != null ? 'User (FAKE)' : 'User',
          snippet: '${userPos.latitude}, ${userPos.longitude}',
        ),
      ),
    );

    // Markery postów (startowe + dodane)
    for (final p in _posts) {
      final postPos = LatLng(p.lat, p.lng);

      markers.add(
        Marker(
          markerId: MarkerId(p.id),
          position: postPos,
          infoWindow: InfoWindow(title: p.title),
          onTap: () => _openPost(p.id, userPos),
        ),
      );
    }

    return markers;
  }

  void _openPost(String postId, LatLng userPos) {
    final post = _posts.firstWhere((p) => p.id == postId);

    final d = distanceMeters(
      lat1: userPos.latitude,
      lng1: userPos.longitude,
      lat2: post.lat,
      lng2: post.lng,
    );

    final unlocked = d <= post.unlockRadiusMeters;
    final remaining = (d - post.unlockRadiusMeters).ceil();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('Dystans: ${d.toStringAsFixed(0)} m'),
              Text('Promień odblokowania: ${post.unlockRadiusMeters.toStringAsFixed(0)} m'),
              const SizedBox(height: 12),
              if (unlocked) ...[
                const Text(
                  'Odblokowano ✅',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(post.content),
              ] else ...[
                const Text(
                  'Zablokowane 🔒',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text('Podejdź bliżej o ok. $remaining m.'),
              ],
              const SizedBox(height: 12),
              if (kDevFakeGps)
                Text(
                  'DEV: przytrzymaj mapę aby „teleportować” usera.',
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        );
      },
    );
  }

  void _addPostSheet(LatLng tappedPos, LatLng userPos) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final radiusCtrl = TextEditingController(text: '80');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dodaj post',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'Punkt: ${tappedPos.latitude.toStringAsFixed(5)}, ${tappedPos.longitude.toStringAsFixed(5)}',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tytuł',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Treść',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: radiusCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Promień odblokowania (metry)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Anuluj'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final title = titleCtrl.text.trim();
                        final content = contentCtrl.text.trim();
                        final radius = double.tryParse(radiusCtrl.text.trim()) ?? 80;

                        if (title.isEmpty || content.isEmpty) return;

                        final id = 'u${_postSeq++}';

                        setState(() {
                          _posts.add(
                            Post(
                              id: id,
                              title: title,
                              content: content,
                              lat: tappedPos.latitude,
                              lng: tappedPos.longitude,
                              unlockRadiusMeters: radius.clamp(5, 500).toDouble(),
                            ),
                          );
                        });

                        Navigator.pop(context);
                      },
                      child: const Text('Dodaj'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _moveCameraTo(LatLng target, {double zoom = 16}) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userPos = _userPos;
    if (userPos == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(kDevFakeGps ? 'Twitter GO (DEV)' : 'Twitter GO'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: userPos, zoom: 16),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,

            // Gesty (żeby dało się oddalać/przybliżać itd.)
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,

            markers: _buildMarkers(userPos),

            // Tap na mapie = dodaj post
            onTap: (pos) => _addPostSheet(pos, userPos),

            // DEV: długie przytrzymanie = teleport usera
            onLongPress: kDevFakeGps
                ? (pos) async {
                    setState(() => _fakeUserPos = pos);
                    await _moveCameraTo(pos);
                  }
                : null,

            onMapCreated: (c) => _mapController = c,
          ),

          // Reset FAKE na górze (nie przeszkadza w mapie)
          if (kDevFakeGps)
            Positioned(
              top: 12,
              right: 12,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: Colors.black.withOpacity(0.7),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () async {
                  setState(() => _fakeUserPos = null);
                  await _moveCameraTo(userPos);
                },
                icon: const Icon(Icons.my_location, size: 16),
                label: const Text('Reset FAKE'),
              ),
            ),
        ],
      ),
    );
  }
}
