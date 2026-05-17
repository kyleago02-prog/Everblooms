
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../data/florist_data.dart';

export '../data/florist_data.dart' show FloristLocation;

typedef ST = AppTheme;

enum TravelMode { driving, walking, cycling }

extension TravelModeExtension on TravelMode {
  String get apiProfile {
    switch (this) {
      case TravelMode.driving:
        return 'driving';
      case TravelMode.walking:
        return 'walking';
      case TravelMode.cycling:
        return 'cycling';
    }
  }
  String get displayName {
    switch (this) {
      case TravelMode.driving:
        return 'Drive';
      case TravelMode.walking:
        return 'Walk';
      case TravelMode.cycling:
        return 'Bike';
    }
  }
  IconData get icon {
    switch (this) {
      case TravelMode.driving:
        return Icons.directions_car;
      case TravelMode.walking:
        return Icons.directions_walk;
      case TravelMode.cycling:
        return Icons.directions_bike;
    }
  }
}

double _getSpeedKmh(TravelMode mode) {
  switch (mode) {
    case TravelMode.driving:
      return 40.0;
    case TravelMode.walking:
      return 5.0;
    case TravelMode.cycling:
      return 15.0;
  }
}

class _PositionData {
  final LatLng point;
  final DateTime timestamp;
  _PositionData({required this.point, required this.timestamp});
}

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  RouteResult({required this.points, required this.distanceKm, required this.durationMinutes});
}

class MapScreen extends StatefulWidget {
  final String? initialFloristName;
  const MapScreen({Key? key, this.initialFloristName}) : super(key: key);
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  // Controllers
  final MapController _mapController = MapController();
  final TextEditingController _originCtrl = TextEditingController();
  final TextEditingController _destCtrl = TextEditingController();
  final FocusNode _originFocus = FocusNode();
  final FocusNode _destFocus = FocusNode();

  // Route data
  LatLng? _originPoint, _destPoint;
  FloristLocation? _selectedFlorist;
  List<LatLng> _routePoints = [];
  double? _distanceKm;
  int? _durationMinutes;

  // UI states
  bool _isLoading = false, _isLocating = false, _isFindingNearest = false, _isAutoNavigating = false;
  String? _errorMsg;
  bool _panelExpanded = true;
  TravelMode _travelMode = TravelMode.driving;

  // Navigation live tracking
  bool _isNavigating = false;
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentLocation;
  double? _currentSpeedKmh;
  double? _currentBearing;
  RouteResult? _currentRoute;
  bool _userInteracted = false;
  Timer? _resetInteractionTimer;
  _PositionData? _lastPosition;

  // Animation for current location pulse
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    if (widget.initialFloristName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoNavigateToFlorist(widget.initialFloristName!);
      });
    }
  }

  @override
  void dispose() {
    _stopNavigation();
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _mapController.dispose();
    _originCtrl.dispose();
    _destCtrl.dispose();
    _originFocus.dispose();
    _destFocus.dispose();
    super.dispose();
  }


  Future<void> _autoNavigateToFlorist(String floristName) async {
    setState(() => _isAutoNavigating = true);
    final florist = FloristData.florists.firstWhere(
          (f) => f.name == floristName,
      orElse: () => FloristData.florists.first,
    );
    await _navigateToFlorist(florist);
    if (mounted) setState(() => _isAutoNavigating = false);
  }

  Future<LatLng?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('Location services are disabled.');
      return null;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnack('Location permission denied.');
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnack('Location permission permanently denied.');
      return null;
    }
    final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
    return LatLng(pos.latitude, pos.longitude);
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const double R = 6371;
    final dLat = (p2.latitude - p1.latitude) * pi / 180;
    final dLon = (p2.longitude - p1.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(p1.latitude * pi / 180) *
            cos(p2.latitude * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Future<LatLng?> _geocode(String address) async {
    final hint = address.toLowerCase().contains('philippines') ? address : '$address, Digos City, Philippines';
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {'q': hint, 'format': 'json', 'limit': '1'});
    final resp = await http.get(uri, headers: {'User-Agent': 'EverbloomFloristApp/1.0'});
    if (resp.statusCode == 200) {
      final list = json.decode(resp.body) as List<dynamic>;
      if (list.isNotEmpty) return LatLng(double.parse(list[0]['lat']), double.parse(list[0]['lon']));
    }
    return null;
  }

  Future<RouteResult?> _fetchRoute(LatLng origin, LatLng dest, {TravelMode? mode}) async {
    final travelMode = mode ?? _travelMode;
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/${travelMode.apiProfile}/'
          '${origin.longitude},${origin.latitude};'
          '${dest.longitude},${dest.latitude}',
      {'overview': 'full', 'geometries': 'geojson'},
    );

    final resp = await http.get(uri);
    if (resp.statusCode != 200) return null;
    final data = json.decode(resp.body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>;
    if (routes.isEmpty) return null;
    final route = routes[0] as Map<String, dynamic>;

    final coords = (route['geometry']['coordinates'] as List<dynamic>)
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();

    final distanceKm = (route['distance'] as num) / 1000;
    final speedKmh = _getSpeedKmh(travelMode);
    final durationMinutes = (distanceKm / speedKmh * 60).round();

    return RouteResult(
      points: coords,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
    );
  }

  Future<void> _findNearestFlorist() async {
    setState(() {
      _isFindingNearest = true;
      _errorMsg = null;
    });
    final currentLocation = await _getCurrentLocation();
    if (currentLocation == null) {
      setState(() => _isFindingNearest = false);
      return;
    }
    FloristLocation? nearest;
    double minDistance = double.infinity;
    for (final florist in FloristData.florists) {
      final dist = _calculateDistance(currentLocation, florist.point);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = florist;
      }
    }
    setState(() => _isFindingNearest = false);
    if (nearest == null) {
      _showSnack('No florist shops found.');
      return;
    }
    _mapController.move(nearest.point, 15.0);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NearestFloristBottomSheet(
        florist: nearest!,
        distanceKm: minDistance,
        onNavigate: () {
          Navigator.pop(ctx);
          _navigateToFlorist(nearest!);
        },
      ),
    );
  }

  void _onFloristTapped(FloristLocation florist) {
    _mapController.move(florist.point, 15.0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FloristBottomSheet(
        florist: florist,
        onNavigate: () {
          Navigator.pop(ctx);
          _navigateToFlorist(florist);
        },
      ),
    );
  }

  Future<void> _navigateToFlorist(FloristLocation florist, {bool startNavigationAfter = true}) async {
    _stopNavigation();
    setState(() {
      _isLocating = true;
      _errorMsg = null;
      _routePoints = [];
      _distanceKm = null;
      _durationMinutes = null;
      _selectedFlorist = florist;
      _panelExpanded = false;
    });
    try {
      final origin = await _getCurrentLocation();
      if (origin == null) {
        setState(() => _isLocating = false);
        return;
      }
      setState(() {
        _isLocating = false;
        _isLoading = true;
        _originCtrl.text = 'My current location';
        _destCtrl.text = florist.name;
      });
      final routeResult = await _fetchRoute(origin, florist.point);
      if (routeResult == null) {
        _showError('Could not calculate route.');
        return;
      }
      setState(() {
        _originPoint = origin;
        _destPoint = florist.point;
        _routePoints = routeResult.points;
        _distanceKm = routeResult.distanceKm;
        _durationMinutes = routeResult.durationMinutes;
      });
      _fitCamera();
      if (startNavigationAfter) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _startNavigation();
        });
      }
    } catch (e) {
      _showError('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startNavigation() async {
    if (_destPoint == null) return;
    final currentLoc = await _getCurrentLocation();
    if (currentLoc == null) {
      _showSnack('Cannot start navigation: no GPS location.');
      return;
    }
    final route = await _fetchRoute(currentLoc, _destPoint!, mode: _travelMode);
    if (route == null) {
      _showSnack('Failed to refresh route.');
      return;
    }

    setState(() {
      _isNavigating = true;
      _currentLocation = currentLoc;
      _currentRoute = route;
      _originPoint = currentLoc;
      _routePoints = route.points;
      _distanceKm = route.distanceKm;
      _durationMinutes = route.durationMinutes;
    });

    _mapController.move(currentLoc, 16.0);
    _userInteracted = false;
    _lastPosition = null;

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
        _currentLocation = newLoc;
        _originPoint = newLoc;
        _currentSpeedKmh = speedKmh.clamp(0, 120);
        if (bearing >= 0) _currentBearing = bearing;
      });

      if (_currentRoute != null && _destPoint != null) {
        final distanceToRoute = _distanceToPolyline(newLoc, _currentRoute!.points);
        if (distanceToRoute > 0.05) {
          final newRoute = await _fetchRoute(newLoc, _destPoint!, mode: _travelMode);
          if (newRoute != null) {
            setState(() {
              _currentRoute = newRoute;
              _routePoints = newRoute.points;
              _distanceKm = newRoute.distanceKm;
              _durationMinutes = newRoute.durationMinutes;
            });
          }
        }
      }

      if (!_userInteracted && _currentBearing != null) {
        _mapController.rotate(_currentBearing! * pi / 180);
      }
      _mapController.move(newLoc, _mapController.camera.zoom);

      if (_destPoint != null && _calculateDistance(newLoc, _destPoint!) < 0.05) {
        _stopNavigation();
        _showSnack('You have arrived at your destination!');
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
    final t = ((p.longitude - a.longitude) * abx + (p.latitude - a.latitude) * aby) / (abx * abx + aby * aby);
    if (t <= 0) return _calculateDistance(p, a);
    if (t >= 1) return _calculateDistance(p, b);
    final proj = LatLng(a.latitude + t * aby, a.longitude + t * abx);
    return _calculateDistance(p, proj);
  }

  void _stopNavigation() {
    _positionStream?.cancel();
    _positionStream = null;
    _lastPosition = null;
    if (mounted) {
      setState(() {
        _isNavigating = false;
        _currentLocation = null;
        _currentSpeedKmh = null;
        _currentBearing = null;
        _currentRoute = null;
      });
    }
    _mapController.rotate(0);
  }

  void _recenter() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 16.0);
      _userInteracted = false;
      if (_currentBearing != null) _mapController.rotate(_currentBearing! * pi / 180);
    }
  }

  Future<void> _search() async {
    final originText = _originCtrl.text.trim(), destText = _destCtrl.text.trim();
    if (originText.isEmpty || destText.isEmpty) {
      _showError('Please enter both origin and destination.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _routePoints = [];
      _distanceKm = null;
      _durationMinutes = null;
      _selectedFlorist = null;
      _isNavigating = false;
    });
    try {
      LatLng? origin;
      if (originText == 'My current location') {
        origin = await _getCurrentLocation();
      } else {
        final results = await Future.wait([_geocode(originText), _geocode(destText)]);
        origin = results[0];
        final dest = results[1];
        if (origin == null) {
          _showError('Origin not found');
          return;
        }
        if (dest == null) {
          _showError('Destination not found');
          return;
        }
        final routeResult = await _fetchRoute(origin, dest);
        if (routeResult == null) {
          _showError('Route error');
          return;
        }
        setState(() {
          _originPoint = origin;
          _destPoint = dest;
          _routePoints = routeResult.points;
          _distanceKm = routeResult.distanceKm;
          _durationMinutes = routeResult.durationMinutes;
          _panelExpanded = false;
        });
        _fitCamera();
        return;
      }
      if (origin == null) return;
      final dest = await _geocode(destText);
      if (dest == null) {
        _showError('Destination not found');
        return;
      }
      final routeResult = await _fetchRoute(origin, dest);
      if (routeResult == null) {
        _showError('Route error');
        return;
      }
      setState(() {
        _originPoint = origin;
        _destPoint = dest;
        _routePoints = routeResult.points;
        _distanceKm = routeResult.distanceKm;
        _durationMinutes = routeResult.durationMinutes;
        _panelExpanded = false;
      });
      _fitCamera();
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    final loc = await _getCurrentLocation();
    if (loc != null && mounted) {
      setState(() {
        _originCtrl.text = 'My current location';
        _originPoint = loc;
      });
    }
    if (mounted) setState(() => _isLocating = false);
  }

  void _fitCamera() {
    if (_routePoints.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(_routePoints);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.fromLTRB(48, 80, 48, 100)));
  }

  void _showError(String msg) {
    if (!mounted) return;
    setState(() {
      _errorMsg = msg;
      _isLoading = false;
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _clearRoute() {
    _stopNavigation();
    setState(() {
      _originCtrl.clear();
      _destCtrl.clear();
      _originPoint = null;
      _destPoint = null;
      _selectedFlorist = null;
      _routePoints = [];
      _distanceKm = null;
      _durationMinutes = null;
      _errorMsg = null;
      _panelExpanded = true;
    });
    _mapController.move(const LatLng(6.7621, 125.2891), 13.0);
  }

  // -------------------------------------------------------------------------
  // UI Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildMap(),
          Positioned(top: 0, left: 0, right: 0, child: _buildInputPanel()),
          if (_distanceKm != null && !_isNavigating)
            Positioned(bottom: 16, left: 12, right: 12, child: _buildSummaryCard()),
          if (_isNavigating && _currentLocation != null)
            Positioned(bottom: 0, left: 0, right: 0, child: _buildNavigationPanel()),
          if (_isNavigating && !_userInteracted)
            Positioned(
              bottom: 120,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: _recenter,
                tooltip: 'Recenter',
                backgroundColor: Colors.white,
                foregroundColor: ST.primary,
                child: const Icon(Icons.my_location),
              ),
            ),
          if (_isLoading || _isLocating || _isFindingNearest || _isAutoNavigating)
            Container(
              color: ST.textPrimary.withOpacity(0.5),
              child: Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(strokeWidth: 2),
                        const SizedBox(width: 16),
                        Text(
                          _isAutoNavigating
                              ? 'Loading route…'
                              : (_isFindingNearest ? 'Finding nearest…' : (_isLocating ? 'Getting location…' : 'Calculating…')),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Everbloom Florist', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF2D3142),
      elevation: 0,
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.storefront),
          tooltip: 'Nearest florist',
          onPressed: _findNearestFlorist,
          color: ST.primary,
        ),
        if (_routePoints.isNotEmpty && !_isNavigating)
          IconButton(
            icon: const Icon(Icons.navigation_rounded),
            tooltip: 'Start Live Navigation',
            onPressed: _startNavigation,
            color: ST.primary,
          ),
        if (_routePoints.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear route',
            onPressed: _clearRoute,
            color: ST.textSecondary,
          ),
      ],
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(6.7621, 125.2891),
        initialZoom: 13.0,
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
                color: Colors.blue,
                strokeWidth: 5,
                borderColor: Colors.white,
                borderStrokeWidth: 1.5,
              ),
            ],
          ),
        MarkerLayer(markers: _buildFloristMarkers()),
        MarkerLayer(markers: _buildNavigationMarkers()),
      ],
    );
  }

  List<Marker> _buildFloristMarkers() {
    return FloristData.florists.map((loc) {
      final isSelected = _selectedFlorist?.name == loc.name;
      return Marker(
        point: loc.point,
        width: isSelected ? 60 : 48,
        height: isSelected ? 60 : 48,
        child: GestureDetector(
          onTap: () => _onFloristTapped(loc),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            decoration: BoxDecoration(
              color: isSelected ? ST.primaryLight : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                if (isSelected)
                  BoxShadow(color: ST.primary.withOpacity(0.5).withValues(alpha: 0.6), blurRadius: 16, spreadRadius: 4)
                else
                  BoxShadow(color: ST.textPrimary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
              ],
              border: Border.all(color: isSelected ? Colors.white : ST.primary.withOpacity(0.5), width: isSelected ? 3 : 2),
            ),
            child: Icon(
              Icons.local_florist,
              color: isSelected ? Colors.white : ST.primaryLight,
              size: isSelected ? 32 : 24,
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Marker> _buildNavigationMarkers() {
    final markers = <Marker>[];
    if (_originPoint != null && !_isNavigating) {
      markers.add(
        Marker(
          point: _originPoint!,
          width: 56,
          height: 56,
          child: Tooltip(
            message: _originCtrl.text,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.blue.shade400,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 1)],
              ),
              child: const Icon(Icons.person_pin, color: Colors.white, size: 22),
            ),
          ),
        ),
      );
    }
    if (_destPoint != null) {
      markers.add(
        Marker(
          point: _destPoint!,
          width: 56,
          height: 64,
          child: Tooltip(
            message: _destCtrl.text,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: Color(0xFF2E7D32).withValues(alpha: 0.35), blurRadius: 12, spreadRadius: 2)],
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                ),
                Container(width: 4, height: 12, color: const Color(0xFF2E7D32)),
              ],
            ),
          ),
        ),
      );
    }
    if (_isNavigating && _currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (ctx, child) => Container(
                  width: 80 * _pulseAnimation.value,
                  height: 80 * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withValues(alpha: 0.25 - (0.25 * _pulseAnimation.value)),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.5 - (0.5 * _pulseAnimation.value)), width: 2),
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ST.surface,
                  boxShadow: [BoxShadow(color: ST.textPrimary.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 2)],
                ),
              ),
              Transform.rotate(
                angle: (_currentBearing ?? 0) * pi / 180,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                    border: Border.all(color: ST.surface, width: 2),
                  ),
                  child: const Icon(Icons.navigation_rounded, color: ST.surface, size: 18),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return markers;
  }

  Widget _buildInputPanel() {
    return SafeArea(
      bottom: false,
      child: _GlassContainer(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.fastOutSlowIn,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => setState(() => _panelExpanded = !_panelExpanded),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ST.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.route, color: ST.primary, size: 20),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Plan your route',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.3),
                        ),
                      ),
                      Icon(
                        _panelExpanded ? Icons.expand_less : Icons.expand_more,
                        color: ST.surface,
                      ),
                    ],
                  ),
                ),
              ),
              if (_panelExpanded) ...[
                Divider(height: 1, thickness: 1, color: ST.textSecondary.withValues(alpha: 0.1)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildAddressField(
                          controller: _originCtrl,
                          focusNode: _originFocus,
                          nextFocus: _destFocus,
                          icon: Icons.my_location,
                          iconColor: Colors.blue,
                          label: 'Current location',
                          hint: 'e.g., Zone I, Digos City',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Tooltip(
                        message: 'Use my current location',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isLocating ? null : _useCurrentLocation,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1.5),
                              boxShadow: [
                                BoxShadow(color: Colors.blue.withOpacity(0.2).withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: _isLocating
                                ? const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.blue),
                                  )
                                : Icon(Icons.my_location, color: Colors.blue, size: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: _buildAddressField(
                    controller: _destCtrl,
                    focusNode: _destFocus,
                    icon: Icons.location_pin,
                    iconColor: ST.error,
                    label: 'Destination',
                    hint: 'Florist name or landmark',
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: TravelMode.values.map((mode) => _buildTravelModeChip(mode)).toList(),
                  ),
                ),
                if (_errorMsg != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: ST.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ST.error.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: ST.error, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMsg!,
                              style: TextStyle(color: ST.error, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _search,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ST.primary,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: ST.primary.withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.directions, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Get Directions',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTravelModeChip(TravelMode mode) {
    final isSelected = _travelMode == mode;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() => _travelMode = mode);
          if (_originPoint != null && _destPoint != null) _recalculateRoute();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? ST.primaryLight : ST.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? ST.primaryLight : const Color(0xFFE2E8F0)),
          boxShadow: isSelected
              ? [BoxShadow(color: ST.primary.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(mode.icon, size: 18, color: isSelected ? Colors.white : ST.textSecondary),
            const SizedBox(width: 6),
            Text(
              mode.displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : ST.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recalculateRoute() async {
    if (_originPoint == null || _destPoint == null) return;
    setState(() => _isLoading = true);
    final route = await _fetchRoute(_originPoint!, _destPoint!);
    if (route != null && mounted) {
      setState(() {
        _routePoints = route.points;
        _distanceKm = route.distanceKm;
        _durationMinutes = route.durationMinutes;
        _fitCamera();
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Widget _buildAddressField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String hint,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ST.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFFE2E8F0), blurRadius: 6, offset: const Offset(0, 2), spreadRadius: 0) // subtle outer shadow
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: textInputAction,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        onSubmitted: onSubmitted ??
            (_) {
              if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
            },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: ST.textSecondary, fontWeight: FontWeight.w500),
          hintText: hint,
          hintStyle: TextStyle(color: ST.textSecondary.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: iconColor, size: 22),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.cancel_rounded, size: 20, color: ST.textSecondary.withOpacity(0.5)),
                  onPressed: () => setState(() => controller.clear()),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: ST.background, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: ST.primary.withOpacity(0.5), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          isDense: true,
          filled: true,
          fillColor: ST.surface.withValues(alpha: 0.5),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final km = _distanceKm!;
    final mins = _durationMinutes!;
    final hours = mins ~/ 60;
    final remainMins = mins % 60;
    final durationText = hours > 0 ? '${hours}h ${remainMins}m' : '$remainMins min';
    return _GlassContainer(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedFlorist != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ST.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.local_florist, color: ST.primary, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Route to ${_selectedFlorist!.name}',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: ST.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: ST.textSecondary.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _summaryTile(
                icon: Icons.straighten,
                iconColor: Colors.blue,
                value: '${km.toStringAsFixed(2)} km',
                label: 'Distance',
              ),
              Container(width: 1, height: 40, color: ST.textSecondary.withValues(alpha: 0.2)),
              _summaryTile(
                icon: Icons.access_time_filled,
                iconColor: Colors.orange,
                value: durationText,
                label: _travelMode.displayName,
              ),
              Container(width: 1, height: 40, color: ST.textSecondary.withValues(alpha: 0.2)),
              _summaryTile(
                icon: _travelMode.icon,
                iconColor: ST.secondary,
                value: _travelMode.displayName.split(' ').last,
                label: 'Mode',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTile({required IconData icon, required Color iconColor, required String value, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: ST.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildNavigationPanel() {
    final remainingKm = _distanceKm ?? 0;
    final remainingMin = _durationMinutes ?? 0;
    final speed = _currentSpeedKmh ?? 0;
    final hours = remainingMin ~/ 60;
    final mins = remainingMin % 60;
    final etaText = hours > 0 ? '${hours}h ${mins}m' : '$mins min';
    return _GlassContainer(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_travelMode.icon, size: 16, color: ST.primary),
                        const SizedBox(width: 6),
                        Text(
                          _travelMode.displayName.toUpperCase(),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: ST.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${remainingKm.toStringAsFixed(1)} km',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 2),
                    Text('Remaining', style: TextStyle(fontSize: 13, color: ST.textSecondary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.access_time_filled, color: Colors.orange, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(etaText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('ETA', style: TextStyle(fontSize: 13, color: ST.textSecondary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: ST.secondary.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.speed, color: ST.secondary, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text('${speed.toStringAsFixed(0)} km/h', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('Speed', style: TextStyle(fontSize: 13, color: ST.textSecondary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _stopNavigation,
              icon: const Icon(Icons.stop_rounded, size: 24),
              label: const Text('Stop Navigation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ST.error.withOpacity(0.1),
                foregroundColor: Colors.white,
                elevation: 6,
                shadowColor: Colors.red.shade200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Bottom Sheets (Redesigned)
// -----------------------------------------------------------------------------
class _FloristBottomSheet extends StatelessWidget {
  final FloristLocation florist;
  final VoidCallback onNavigate;
  const _FloristBottomSheet({required this.florist, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      borderRadius: BorderRadius.circular(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: ST.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(3)),
            ),
          ),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: ST.primaryLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: ST.primary.withOpacity(0.5), width: 2),
                  boxShadow: [BoxShadow(color: ST.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Icon(Icons.local_florist, color: ST.primaryLight, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(florist.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: ST.background, borderRadius: BorderRadius.circular(8)),
                      child: Text('Florist Shop · Digos City', style: TextStyle(color: ST.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: ST.textSecondary.withValues(alpha: 0.2), thickness: 1),
          const SizedBox(height: 20),
          _infoRow(
            icon: Icons.location_pin,
            label: 'Coordinates',
            value: '${florist.point.latitude.toStringAsFixed(4)}°N, ${florist.point.longitude.toStringAsFixed(4)}°E',
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFFE2E8F0), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: ST.textPrimary,
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text('Navigate', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ST.primary,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: ST.primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: ST.textSecondary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: ST.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Premium UI Helpers
// -----------------------------------------------------------------------------
class _GlassContainer extends StatelessWidget {
  final Widget child;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final double blur;

  const _GlassContainer({
    required this.child,
    required this.borderRadius,
    this.padding,
    this.margin,
    this.color = const Color(0xB3FFFFFF), // Semi-transparent white
    this.blur = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.12), blurRadius: 20, spreadRadius: -5, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: ST.surface.withValues(alpha: 0.5), width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _NearestFloristBottomSheet extends StatelessWidget {
  final FloristLocation florist;
  final double distanceKm;
  final VoidCallback onNavigate;
  const _NearestFloristBottomSheet({required this.florist, required this.distanceKm, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      borderRadius: BorderRadius.circular(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: ST.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(3)),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: ST.primaryLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: ST.primary.withOpacity(0.2))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: ST.primary, size: 18),
                  const SizedBox(width: 6),
                  Text('Nearest Florist', style: TextStyle(color: ST.primary, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.2)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: ST.primaryLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: ST.primary.withOpacity(0.5), width: 2),
                  boxShadow: [BoxShadow(color: ST.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Icon(Icons.local_florist, color: ST.primary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(florist.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    Text(
                      'Only ${distanceKm.toStringAsFixed(1)} km away',
                      style: TextStyle(color: ST.secondary, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: ST.textSecondary.withValues(alpha: 0.2), thickness: 1),
          const SizedBox(height: 20),
          _infoRow(
            icon: Icons.location_pin,
            label: 'Coordinates',
            value: '${florist.point.latitude.toStringAsFixed(4)}°N, ${florist.point.longitude.toStringAsFixed(4)}°E',
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFFE2E8F0), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: ST.textPrimary,
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text('Navigate', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ST.primary,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: ST.primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: ST.textSecondary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: ST.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}