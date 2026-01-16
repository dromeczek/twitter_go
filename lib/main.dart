import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location/location_service.dart';

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
      ),
      home: const MyHomePage(title: 'Twitter GO'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _locService = LocationService();

  GoogleMapController? _mapController;
  AppLocation? _loc;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final loc = await _locService.getCurrent();
    if (!mounted) return;
    setState(() => _loc = loc);
  }

  @override
  Widget build(BuildContext context) {
    if (_loc == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userPos = LatLng(_loc!.lat, _loc!.lng);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: userPos,
          zoom: 16,
        ),
        myLocationEnabled: true,
        markers: {
          Marker(
            markerId: const MarkerId('user'),
            position: userPos,
          ),
        },
        onMapCreated: (c) => _mapController = c,
      ),
    );
  }
}
