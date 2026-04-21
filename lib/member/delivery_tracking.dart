import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
// - Opens immediately, no button needed
// - Blue dot = real phone GPS location
// - Red line = route from current position to TARUMT Penang
// - Red school marker = TARUMT Penang Branch (fixed destination)
// ─────────────────────────────────────────────────────────────────────────────

class DeliveryTracking extends StatefulWidget {
  final String orderId;
  final bool isRider;

  const DeliveryTracking({
    super.key,
    this.orderId = 'ORDER 1',
    this.isRider = false,
  });

  @override
  State<DeliveryTracking> createState() => _DeliveryTrackingState();
}

class _DeliveryTrackingState extends State<DeliveryTracking>
    with TickerProviderStateMixin {

  static final SupabaseClient _supabase = Supabase.instance.client;

  // Fixed destination: TARUMT Penang Branch
  static const LatLng _tarumt =
  LatLng(5.453376084434956, 100.28490668650755);

  // Current rider position (updates in real time)
  LatLng _riderPosition =
  const LatLng(5.453880685162001, 100.28365408991911);

  // Route line points (from rider to TARUMT, updates as rider moves)
  List<LatLng> _routePoints = [];

  late final MapController _mapController;
  Timer? _gpsTimer;
  RealtimeChannel? _realtimeChannel;

  // Pulse animation for rider dot
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Distance to TARUMT in meters
  double _distanceMeters = 0;

  // Arrived flag
  bool _arrived = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 5.0, end: 14.0).animate(
      CurvedAnimation(
          parent: _pulseController, curve: Curves.easeInOut),
    );

    // Build initial route
    _updateRoute(_riderPosition);

    // Start immediately on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isRider) {
        _startRiderGPS();
      } else {
        _startCustomerListener();
      }
    });
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ─── Update route line from rider to TARUMT ────────────────────────────────
  Future<void> _updateRoute(LatLng from) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${from.longitude},${from.latitude};'
          '${_tarumt.longitude},${_tarumt.latitude}'
          '?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final coords = data['routes'][0]['geometry']['coordinates'];

        final List<LatLng> newRoute = coords.map<LatLng>((c) {
          return LatLng(c[1], c[0]);
        }).toList();

        final double distance = data['routes'][0]['distance'];

        setState(() {
          _routePoints = newRoute;

          _distanceMeters = distance;

          _arrived = _distanceMeters < 30;
        });
      }
    } catch (e) {
      debugPrint("Route error: $e");
    }
  }

  // ─── Get real GPS + upload to Supabase every 3 seconds ────────────

  Future<void> _startRiderGPS() async {
    LocationPermission permission =
    await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission required.'),
            backgroundColor: Color(0xFFCF0000),
          ),
        );
      }
      return;
    }

    // Get GPS and upload every 3 seconds
    _gpsTimer =
        Timer.periodic(const Duration(seconds: 2), (_) async {
          try {
            final Position pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );

            // Write to Supabase (always upsert row id = 1)
            await _supabase.from('rider_location').upsert({
              'id': 1,
              'latitude': pos.latitude,
              'longitude': pos.longitude,
              'updated_at':
              DateTime.now().toUtc().toIso8601String(),
            });

            if (!mounted) return;

            final LatLng newPos =
            LatLng(pos.latitude, pos.longitude);

            setState(() => _riderPosition = newPos);
            _updateRoute(newPos);

            // Camera follows rider
            try {
              _mapController.move(newPos, _mapController.camera.zoom);
            } catch (_) {}
          } catch (e) {
            debugPrint('GPS error: $e');
          }
        });
  }

  // ─── CUSTOMER: Listen to Supabase realtime ────────────────────────────────

  void _startCustomerListener() {
    // Fetch current position first
    _fetchCurrentPosition();

    _realtimeChannel = _supabase
        .channel('rider_loc')
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'rider_location',
      callback: (payload) {
        final data = payload.newRecord;
        final double lat =
        (data['latitude'] as num).toDouble();
        final double lng =
        (data['longitude'] as num).toDouble();

        if (!mounted) return;

        final LatLng newPos = LatLng(lat, lng);
        setState(() => _riderPosition = newPos);
        _updateRoute(newPos);

        try {
          _mapController.move(
              newPos, _mapController.camera.zoom);
        } catch (_) {}
      },
    )
        .subscribe();
  }

  Future<void> _fetchCurrentPosition() async {
    try {
      final rows = await _supabase
          .from('rider_location')
          .select('latitude, longitude')
          .eq('id', 1)
          .limit(1);

      if (rows.isNotEmpty && mounted) {
        final double lat =
        (rows.first['latitude'] as num).toDouble();
        final double lng =
        (rows.first['longitude'] as num).toDouble();
        final LatLng pos = LatLng(lat, lng);
        setState(() => _riderPosition = pos);
        _updateRoute(pos);
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
    }
  }

  // ─── Distance (Haversine) ─────────────────────────────────────────────────

  double _calcDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000;
    final double dLat = _rad(lat2 - lat1);
    final double dLon = _rad(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) *
            cos(_rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double deg) => deg * pi / 180;

  // ─── Distance label ───────────────────────────────────────────────────────

  String get _distanceLabel {
    if (_arrived) return 'Arrived!';
    if (_distanceMeters >= 1000) {
      return '${(_distanceMeters / 1000).toStringAsFixed(1)} km away';
    }
    return '${_distanceMeters.toInt()} m away';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildMap()),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _riderPosition,
        initialZoom: 17.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.cincai.food_ordering',
          maxZoom: 19,
        ),

        if (_routePoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                color: const Color(0xFFCF0000),
                strokeWidth: 4.5,
              ),
            ],
          ),

        MarkerLayer(
          markers: [
            // TARUMT destination
            Marker(
              point: _tarumt,
              width: 56,
              height: 68,
              child: _buildTarumtMarker(),
            ),

            // Current location
            Marker(
              point: _riderPosition,
              width: 54,
              height: 54,
              child: _buildRiderMarker(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTarumtMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFCF0000),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFCF0000).withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2)
            ],
          ),
          child:
          const Icon(Icons.school, color: Colors.white, size: 26),
        ),
        Container(
            width: 3, height: 16, color: const Color(0xFFCF0000)),
      ],
    );
  }

  Widget _buildRiderMarker() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, __) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring
            Container(
              width: _pulseAnimation.value * 2,
              height: _pulseAnimation.value * 2,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.25),
                shape: BoxShape.circle,
              ),
            ),
            // Blue dot
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF1565C0).withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 1)
                ],
              ),
              child: const Icon(Icons.delivery_dining,
                  color: Colors.white, size: 18),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back,
                  size: 18, color: Colors.black),
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Tracking',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                Text(
                  'Order #${widget.orderId}',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Live badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                const Text('LIVE',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          // Destination info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Delivering to',
                  style:
                  TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                const Text(
                  'TARUMT Penang Branch',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _arrived
                          ? Icons.check_circle
                          : Icons.directions_walk,
                      size: 14,
                      color: _arrived
                          ? Colors.green
                          : const Color(0xFFCF0000),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _distanceLabel,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _arrived
                              ? Colors.green
                              : const Color(0xFFCF0000)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // School icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _arrived
                  ? Colors.green.withOpacity(0.1)
                  : const Color(0xFFCF0000).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _arrived ? Icons.check_circle : Icons.school,
              color: _arrived
                  ? Colors.green
                  : const Color(0xFFCF0000),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}