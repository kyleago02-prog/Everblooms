// lib/screens/seller/order_tracking_map_screen.dart
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

enum TravelMode { driving, walking, cycling }

extension TravelModeExtension on TravelMode {
  String get apiProfile {
    switch (this) {
      case TravelMode.driving: return 'driving';
      case TravelMode.walking: return 'walking';
      case TravelMode.cycling: return 'cycling';
    }
  }
  String get displayName {
    switch (this) {
      case TravelMode.driving: return 'Drive';
      case TravelMode.walking: return 'Walk';
      case TravelMode.cycling: return 'Bike';
    }
  }
  IconData get icon {
    switch (this) {
      case TravelMode.driving: return Icons.directions_car;
      case TravelMode.walking: return Icons.directions_walk;
      case TravelMode.cycling: return Icons.directions_bike;
    }
  }
}

double _getSpeedKmh(TravelMode mode) {
  switch (mode) {
    case TravelMode.driving: return 40.0;
    case TravelMode.walking: return 5.0;
    case TravelMode.cycling: return 15.0;
  }
}

class _PositionData {
  final LatLng point;
  final DateTime timestamp;
  _PositionData({required this.point, required this.timestamp});
}

class _RouteResult {
  final List<LatLng> points;
  final double km;
  final int minutes;
  const _RouteResult({required this.points, required this.km, required this.minutes});
}

class OrderTrackingMapScreen extends StatefulWidget {
  final String customerName;
  final String customerAddress;
  final LatLng customerLatLng;
  final String orderId;
  final String productName;
  final bool isPickup; // NEW: true for pickup (store location), false for delivery

  const OrderTrackingMapScreen({
    Key? key,
    required this.customerName,
    required this.customerAddress,
    required this.customerLatLng,
    required this.orderId,
    required this.productName,
    this.isPickup = false,
  }) : super(key: key);

  @override
  State<OrderTrackingMapScreen> createState() => _OrderTrackingMapScreenState();
}

class _OrderTrackingMapScreenState extends State<OrderTrackingMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  LatLng? _sellerLatLng;
  List<LatLng> _routePoints = [];
  double? _distanceKm;
  int? _durationMinutes;

  TravelMode _travelMode = TravelMode.driving;

  bool _isNavigating = false;
  StreamSubscription<Position>? _positionStream;
  double? _currentSpeedKmh;
  double? _currentBearing;
  _RouteResult? _currentRoute;
  bool _userInteracted = false;
  Timer? _resetInteractionTimer;
  _PositionData? _lastPosition;

  bool _isLocating = true;
  bool _isRouting = false;
  String? _errorMsg;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _init();
  }

  @override
  void dispose() {
    _stopNavigation();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final seller = await _getSellerLocation();
    if (seller == null || !mounted) return;

    setState(() {
      _sellerLatLng = seller;
      _isLocating = false;
      _isRouting = true;
    });

    final routeResult = await _fetchRoute(seller, widget.customerLatLng);
    if (!mounted) return;
    if (routeResult == null) {
      setState(() {
        _isRouting = false;
        _errorMsg = 'Could not calculate route.';
      });
      return;
    }

    setState(() {
      _routePoints = routeResult.points;
      _distanceKm = routeResult.km;
      _durationMinutes = routeResult.minutes;
      _isRouting = false;
      _currentRoute = routeResult;
    });

    _fitCamera(routeResult.points);
    _startNavigation();
  }

  Future<LatLng?> _getSellerLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _setError('Location services are disabled.');
        return null;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _setError('Location permission denied.');
          return null;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        _setError('Location permission permanently denied.');
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      _setError('Could not get location: $e');
      return null;
    }
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const double R = 6371;
    final dLat = (p2.latitude - p1.latitude) * pi / 180;
    final dLon = (p2.longitude - p1.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(p1.latitude * pi / 180) * cos(p2.latitude * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Future<_RouteResult?> _fetchRoute(LatLng origin, LatLng dest, {TravelMode? mode}) async {
    final travelMode = mode ?? _travelMode;
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/${travelMode.apiProfile}/'
          '${origin.longitude},${origin.latitude};'
          '${dest.longitude},${dest.latitude}',
      {'overview': 'full', 'geometries': 'geojson'},
    );
    try {
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return null;
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) return null;
      final route = routes[0] as Map<String, dynamic>;
      final coords = (route['geometry']['coordinates'] as List<dynamic>)
          .map((c) => LatLng(
        (c[1] as num).toDouble(),
        (c[0] as num).toDouble(),
      ))
          .toList();
      final distanceKm = (route['distance'] as num) / 1000;
      final speedKmh = _getSpeedKmh(travelMode);
      final minutes = (distanceKm / speedKmh * 60).round();
      return _RouteResult(points: coords, km: distanceKm, minutes: minutes);
    } catch (_) {
      return null;
    }
  }

  void _recalculateRoute() async {
    if (_sellerLatLng == null) return;
    setState(() => _isRouting = true);
    final newRoute = await _fetchRoute(_sellerLatLng!, widget.customerLatLng);
    if (newRoute != null && mounted) {
      setState(() {
        _routePoints = newRoute.points;
        _distanceKm = newRoute.km;
        _durationMinutes = newRoute.minutes;
        _currentRoute = newRoute;
        _isRouting = false;
      });
      _fitCamera(newRoute.points);
    } else {
      setState(() => _isRouting = false);
    }
  }

  void _fitCamera(List<LatLng> points) {
    if (points.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(48, 60, 48, 200),
      ),
    );
  }

  void _startNavigation() {
    if (_sellerLatLng == null) return;
    setState(() {
      _isNavigating = true;
      _currentSpeedKmh = 0;
      _currentBearing = 0;
      _lastPosition = null;
    });
    _mapController.move(_sellerLatLng!, 16.0);
    _userInteracted = false;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((Position pos) async {
      if (!_isNavigating) return;
      final newLoc = LatLng(pos.latitude, pos.longitude);
      final bearing = pos.heading;

      double speedKmh = pos.speed * 3.6;
      if (speedKmh < 0.5 && _lastPosition != null) {
        final distKm = _calculateDistance(_lastPosition!.point, newLoc);
        final timeHours = DateTime.now().difference(_lastPosition!.timestamp).inSeconds / 3600.0;
        if (timeHours > 0 && distKm > 0.005) {
          speedKmh = distKm / timeHours;
        }
      }
      _lastPosition = _PositionData(point: newLoc, timestamp: DateTime.now());

      setState(() {
        _sellerLatLng = newLoc;
        _currentSpeedKmh = speedKmh.clamp(0, 120);
        if (bearing >= 0) _currentBearing = bearing;
      });

      if (_currentRoute != null) {
        final distanceToRoute = _distanceToPolyline(newLoc, _currentRoute!.points);
        if (distanceToRoute > 0.05) {
          final newRoute = await _fetchRoute(newLoc, widget.customerLatLng);
          if (newRoute != null) {
            setState(() {
              _currentRoute = newRoute;
              _routePoints = newRoute.points;
              _distanceKm = newRoute.km;
              _durationMinutes = newRoute.minutes;
            });
          }
        }
      }

      if (!_userInteracted && _currentBearing != null) {
        _mapController.rotate(_currentBearing! * pi / 180);
      }
      _mapController.move(newLoc, _mapController.camera.zoom);

      if (_calculateDistance(newLoc, widget.customerLatLng) < 0.05) {
        _stopNavigation();
        _setError('You have arrived! 🎉');
      }
    });
  }

  double _distanceToPolyline(LatLng point, List<LatLng> polyline) {
    double minDist = double.infinity;
    for (int i = 0; i < polyline.length - 1; i++) {
      final a = polyline[i], b = polyline[i + 1];
      final dist = _pointToSegmentDistance(point, a, b);
      if (dist < minDist) minDist = dist;
    }
    return minDist;
  }

  double _pointToSegmentDistance(LatLng p, LatLng a, LatLng b) {
    final abx = b.longitude - a.longitude;
    final aby = b.latitude - a.latitude;
    final t = ((p.longitude - a.longitude) * abx + (p.latitude - a.latitude) * aby) /
        (abx * abx + aby * aby);
    if (t <= 0) return _calculateDistance(p, a);
    if (t >= 1) return _calculateDistance(p, b);
    final proj = LatLng(a.latitude + t * aby, a.longitude + t * abx);
    return _calculateDistance(p, proj);
  }

  void _stopNavigation() {
    _positionStream?.cancel();
    _positionStream = null;
    if (mounted) {
      setState(() {
        _isNavigating = false;
        _currentSpeedKmh = null;
        _currentBearing = null;
        _currentRoute = null;
        _lastPosition = null;
      });
    }
    _mapController.rotate(0);
  }

  void _recenter() {
    if (_sellerLatLng != null) {
      _mapController.move(_sellerLatLng!, _mapController.camera.zoom);
      _userInteracted = false;
      if (_currentBearing != null) _mapController.rotate(_currentBearing! * pi / 180);
    }
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() {
      _errorMsg = msg;
      _isLocating = false;
      _isRouting = false;
    });
  }

  Future<void> _refresh() async {
    _stopNavigation();
    setState(() {
      _sellerLatLng = null;
      _routePoints = [];
      _distanceKm = null;
      _durationMinutes = null;
      _errorMsg = null;
      _isLocating = true;
      _isRouting = false;
      _currentSpeedKmh = null;
      _currentBearing = null;
      _currentRoute = null;
    });
    await _init();
  }

  Widget _buildTravelModeChip(TravelMode mode) {
    final isSelected = _travelMode == mode;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() => _travelMode = mode);
          _recalculateRoute();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink.shade400 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.pink.shade400 : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(mode.icon, size: 15,
                color: isSelected ? Colors.white : Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              mode.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.isPickup ? 'Pickup' : 'Delivery',
                style: const TextStyle(fontSize: 16, color: Colors.white)),

          ],
        ),
        backgroundColor: Colors.pink.shade400,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: (_isLocating || _isRouting) ? null : _refresh,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMap(),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0,2))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: TravelMode.values.map(_buildTravelModeChip).toList(),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _buildLegend(),
          ),
          if (_isNavigating && !_userInteracted)
            Positioned(
              bottom: 120,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: _recenter,
                tooltip: 'Recenter',
                backgroundColor: Colors.white,
                foregroundColor: Colors.pink.shade400,
                child: const Icon(Icons.my_location),
              ),
            ),
          if (_distanceKm != null && !_isRouting)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildSummaryCard(),
            ),
          if (_errorMsg != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildErrorCard(),
            ),
          if (_isLocating || _isRouting)
            Container(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.55),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      _isLocating ? 'Getting your location…' : 'Calculating route…',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final center = _sellerLatLng ?? widget.customerLatLng;
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14.0,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
        onMapEvent: (MapEvent event) {
          if (event is MapEventMoveStart || event is MapEventRotateStart) {
            setState(() => _userInteracted = true);
            _resetInteractionTimer?.cancel();
            _resetInteractionTimer = Timer(const Duration(seconds: 5), () {
              if (mounted) setState(() => _userInteracted = false);
            });
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.yourcompany.everbloom',
        ),
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                color: Colors.blue.shade700,
                strokeWidth: 5,
                borderColor: Colors.blue.shade900,
                borderStrokeWidth: 1,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            // Destination marker — store (pickup) or customer (delivery)
            Marker(
              point: widget.customerLatLng,
              width: 56,
              height: 66,
              child: Tooltip(
                message: widget.isPickup
                    ? 'Store: ${widget.customerAddress}'
                    : 'Customer: ${widget.customerName}\n${widget.customerAddress}',
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.isPickup ? Colors.orange.shade400 : const Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [BoxShadow(color: (widget.isPickup ? Colors.orange : Colors.green).withValues(alpha: 0.35), blurRadius: 8)],
                      ),
                      child: Icon(
                        widget.isPickup ? Icons.storefront_rounded : Icons.person_pin,
                        color: Colors.white, size: 22),
                    ),
                    Container(width: 3, height: 14,
                        color: widget.isPickup ? Colors.orange : const Color(0xFF2E7D32)),
                  ],
                ),
              ),
            ),
            // Current location marker (seller/person)
            if (_sellerLatLng != null)
              Marker(
                point: _sellerLatLng!,
                width: 60,
                height: 60,
                child: _isNavigating
                    ? Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (ctx, child) => Container(
                        width: 60 * _pulseAnimation.value,
                        height: 60 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    ),
                    Transform.rotate(
                      angle: (_currentBearing ?? 0) * pi / 180,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.shade400),
                        child: const Icon(Icons.person_pin, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                )
                    : Tooltip(
                  message: 'Your Location',
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.person_pin, color: Colors.white, size: 22),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current location (always person_pin / blue)
          _legendItem(Colors.blue.shade400, Icons.person_pin, 'Your Location'),
          const SizedBox(height: 6),
          // Destination (store or customer)
          _legendItem(
            widget.isPickup ? Colors.orange.shade400 : const Color(0xFF2E7D32),
            widget.isPickup ? Icons.storefront_rounded : Icons.storefront_rounded,
            widget.customerAddress,
          ),
          if (_isNavigating) ...[
            const SizedBox(height: 6),
            _legendItem(Colors.blue.shade700, Icons.navigation, 'Live tracking'),
          ],
        ],
      ),
    );
  }

  Widget _legendItem(Color color, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final km = _distanceKm!;
    final mins = _durationMinutes!;
    final hours = mins ~/ 60;
    final rem = mins % 60;
    final dur = hours > 0 ? '${hours}h ${rem}m' : '$rem min';
    final speed = _currentSpeedKmh ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Customer store info row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.isPickup ? Colors.orange.shade50 : Colors.green.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.isPickup ? Colors.orange.shade200 : Colors.green.shade200),
                ),
                child: Icon(
                    widget.isPickup ? Icons.storefront_rounded : Icons.person_pin,
                    color: widget.isPickup ? Colors.orange : const Color(0xFF2E7D32), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.isPickup ? 'Pickup Store' : widget.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(widget.customerAddress,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Product info row
          Row(
            children: [
              Icon(Icons.shopping_bag, color: Colors.pink.shade400, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.productName,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 0),
          const SizedBox(height: 12),
          // Metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _metricTile(Icons.straighten, Colors.blue.shade700, '${km.toStringAsFixed(2)} km', 'Distance'),
              Container(width: 1, height: 36, color: Colors.grey.shade200),
              _metricTile(Icons.access_time_filled, Colors.orange.shade700, dur, 'ETA'),
              Container(width: 1, height: 36, color: Colors.grey.shade200),
              _metricTile(Icons.speed, Colors.green.shade700, '${speed.toStringAsFixed(0)} km/h', 'Speed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile(IconData icon, Color color, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400),
          const SizedBox(width: 11),
          Expanded(
            child: Text(_errorMsg!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            color: Colors.red.shade400,
            onPressed: _refresh,
          ),
        ],
      ),
    );
  }
}