import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../services/driver_api_service.dart';
import '../../services/location_permission_service.dart';
import '../auth/driver_layout.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, TargetPlatform, defaultTargetPlatform;

class DriverActiveRide extends StatefulWidget {
  const DriverActiveRide({Key? key}) : super(key: key);

  @override
  _DriverActiveRideState createState() => _DriverActiveRideState();
}

class _DriverActiveRideState extends State<DriverActiveRide>
    with TickerProviderStateMixin {
  // ── GPS & Map ─────────────────────────────────────────────────────────
  Timer? _locationTimer;
  Timer? _roamTimer;
  Timer? _rideRefreshTimer;
  Timer? _socketTimer;
  Timer? _simulationTimer;
  LatLng? _currentPosition;
  LatLng? _originalPosition; // Position de départ du chauffeur
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  bool _mapReady = false;
  bool _permissionGranted = false;
  StreamSubscription<Position>? _positionSubscription;
  bool _simulateMode = false;

  // Angle de rotation du taxi pour l'image (heading)
  double _taxiHeading = 0.0;
  LatLng? _prevPosition;

  // ── WebSocket ─────────────────────────────────────────────────────────
  WebSocketChannel? _locationChannel;
  int? _driverId;

  // ── Ride data ─────────────────────────────────────────────────────────
  final DriverApiService _apiService = DriverApiService();
  Map<String, dynamic>? _activeRide;
  bool _isLoading = true;
  bool _rideStarted = false;
  bool _isActionLoading = false;
  double? _routeDistanceKm;
  int? _routeDurationMin;

  // ── Follow mode (camera locks on driver position) ────────────────────
  bool _followMode = true;

  // ── Animation pulse ───────────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // No API key needed — using free CARTO tiles + OSRM routing

  // ─────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Pulse animation for markers
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.7, end: 1.0).animate(_pulseController);

    _initWebSocket();

    // Request permission on start (popup) then start everything
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadDriverProfile();
      final bool granted = kIsWeb
          ? await _requestWebLocationPermission()
          : await LocationPermissionService.requestWithDialog(context);
      if (mounted) {
        setState(() => _permissionGranted = granted);
        if (granted) {
          await _initLocationAndRide();
        } else {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  void _initWebSocket() {
    if (_driverId == null) return;
    try {
      _locationChannel?.sink.close();
      final String wsUrl = kIsWeb
          ? 'ws://localhost:8000/ws/location/$_driverId'
          : (defaultTargetPlatform == TargetPlatform.android
              ? 'ws://10.0.2.2:8000/ws/location/$_driverId'
              : 'ws://localhost:8000/ws/location/$_driverId');

      _locationChannel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _locationChannel?.stream.listen(
        (message) => debugPrint('WS ack: $message'),
        onError: (e) {
          debugPrint('WS error: $e');
          Future.delayed(const Duration(seconds: 3), _initWebSocket);
        },
        onDone: () {
          debugPrint('WS closed — reconnecting in 3s');
          Future.delayed(const Duration(seconds: 3), _initWebSocket);
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('WS connect error: $e');
      Future.delayed(const Duration(seconds: 3), _initWebSocket);
    }
  }


  Future<void> _loadDriverProfile() async {
    try {
      final profile = await _apiService.getProfile();
      if (mounted) {
        setState(() {
          _driverId = profile['user_id'];
        });
        _initWebSocket();
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      // Fallback driver_id for testing
      if (mounted) {
        setState(() => _driverId = 1);
        _initWebSocket();
      }
    }
  }

  Future<void> _initLocationAndRide() async {
    await _startLocationTracking();
    await _loadActiveRide();
    _startActiveRidePolling();
    _startSocketPublishing();
  }

  Future<bool> _requestWebLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        return requested == LocationPermission.always ||
            requested == LocationPermission.whileInUse;
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Web permission error: $e');
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  //  GPS
  // ──────────────────────────────────────────────────────────────────────
  Future<void> _startLocationTracking() async {
    if (_simulateMode) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('Veuillez activer le GPS', Colors.orangeAccent);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

    try {
      Position pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        final latLng = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _currentPosition = latLng;
          _originalPosition ??= latLng; // Save original only once
        });
        _onPositionUpdated();
      }
    } catch (e) {
      debugPrint('GPS initial: $e');
    }

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen(
      (pos) {
        if (!mounted) return;
        final newPos = LatLng(pos.latitude, pos.longitude);
        _updateTaxiHeading(newPos);
        setState(() {
          _currentPosition = newPos;
          _originalPosition ??= newPos;
        });
        _onPositionUpdated();
      },
      onError: (e) => debugPrint('GPS stream error: $e'),
    );

    // Fallback timer for devices that throttle position streams.
    _locationTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      try {
        Position pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
          ),
        );
        if (!mounted) return;
        final newPos = LatLng(pos.latitude, pos.longitude);
        _updateTaxiHeading(newPos);
        setState(() {
          _currentPosition = newPos;
          _originalPosition ??= newPos;
        });
        _onPositionUpdated();
      } catch (e) {
        debugPrint('GPS fallback update: $e');
      }
    });
  }

  /// Calcule la rotation du taxi en degrés depuis la position précédente
  void _updateTaxiHeading(LatLng newPos) {
    if (_currentPosition == null) return;
    final dLat = newPos.latitude - _currentPosition!.latitude;
    final dLng = newPos.longitude - _currentPosition!.longitude;
    if (dLat.abs() < 0.000001 && dLng.abs() < 0.000001) return;
    final angle = math.atan2(dLng, dLat) * (180 / math.pi);
    setState(() => _taxiHeading = angle);
    _prevPosition = _currentPosition;
  }

  /// Appelé chaque fois que la position change
  Future<void> _onPositionUpdated() async {
    if (_currentPosition != null && _mapReady && _followMode) {
      try {
        _mapController.move(_currentPosition!, _mapController.camera.zoom);
      } catch (_) {}
    }

    if (_activeRide != null) {
      final now = DateTime.now();
      if (_lastRouteFetchAt != null &&
          now.difference(_lastRouteFetchAt!) < _routeRefreshInterval) {
        return;
      }
      _lastRouteFetchAt = now;
      await _fetchRoute();
      if (_followMode) _focusMapOnRide();
    }
  }

  void _startSocketPublishing() {
    _socketTimer?.cancel();
    _socketTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _publishCurrentPositionToSocket();
    });
  }

  void _publishCurrentPositionToSocket() {
    if (_currentPosition == null || _driverId == null) return;
    try {
      if (_locationChannel == null) {
        _initWebSocket();
        return;
      }
      final payload = jsonEncode({
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _locationChannel!.sink.add(payload);
    } catch (e) {
      debugPrint('WebSocket publish error: $e');
      _initWebSocket();
    }
  }

  void _toggleSimulationMode() {
    setState(() {
      _simulateMode = !_simulateMode;
    });

    if (_simulateMode) {
      _positionSubscription?.cancel();
      _positionSubscription = null;
      _locationTimer?.cancel();
      _startSimulationMovement();
      _showSnack('Mode simulation active', const Color(0xFF60A5FA));
    } else {
      _stopSimulationMovement();
      _startLocationTracking();
      _showSnack('Mode GPS reel active', const Color(0xFF4ADE80));
    }
  }

  void _startSimulationMovement() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _activeRide == null) return;
      final target = _getDestinationCoords();
      if (target == null) return;

      final current = _currentPosition;
      if (current == null) {
        setState(() {
          _currentPosition = target;
          _originalPosition ??= target;
        });
        _onPositionUpdated();
        return;
      }

      const step = 0.00035;
      final dLat = target.latitude - current.latitude;
      final dLng = target.longitude - current.longitude;
      final distance = math.sqrt((dLat * dLat) + (dLng * dLng));

      if (distance < step) {
        setState(() {
          _currentPosition = target;
        });
        _onPositionUpdated();
        return;
      }

      final next = LatLng(
        current.latitude + (dLat / distance) * step,
        current.longitude + (dLng / distance) * step,
      );

      _updateTaxiHeading(next);
      setState(() {
        _currentPosition = next;
      });
      _onPositionUpdated();
    });
  }

  void _stopSimulationMovement() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  void _focusMapOnRide() {
    if (!_mapReady || _currentPosition == null) return;
    _mapController.move(_currentPosition!, 15.2);
  }

  // ──────────────────────────────────────────────────────────────────────
  //  ROAMING (aucune course active)
  // ──────────────────────────────────────────────────────────────────────
  void _startRoaming() {
    // Le roaming utilise maintenant uniquement le GPS réel mis à jour par le timer principal
    debugPrint("Mode roaming activé : utilisant le GPS en temps réel.");
  }

  void _stopRoaming() {
    _roamTimer?.cancel();
    _roamTimer = null;
  }

  // ──────────────────────────────────────────────────────────────────────
  //  OSRM Directions — itinéraire réel
  // ──────────────────────────────────────────────────────────────────────
  bool _isFetchingRoute = false;
  DateTime? _lastRouteFetchAt;
  static const Duration _routeRefreshInterval = Duration(seconds: 6);
  Future<void> _fetchRoute() async {
    if (_currentPosition == null || _activeRide == null || _isFetchingRoute) return;
    _isFetchingRoute = true;

    LatLng? destination = _getDestinationCoords();
    if (destination == null) {
      _isFetchingRoute = false;
      return;
    }

    final origin = _currentPosition!;
    // OSRM — free routing, no API key, same JSON format as Mapbox Directions
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes[0] as Map<String, dynamic>;
          final coords = firstRoute['geometry']['coordinates'] as List;
          final points = coords
              .map<LatLng>(
                  (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          if (mounted) {
            setState(() {
              _routePoints = points;
              final distanceMeters = (firstRoute['distance'] as num?)?.toDouble();
              final durationSeconds = (firstRoute['duration'] as num?)?.toDouble();
              _routeDistanceKm =
                  distanceMeters != null ? distanceMeters / 1000.0 : null;
              _routeDurationMin = durationSeconds != null
                  ? (durationSeconds / 60).round()
                  : null;
            });
            debugPrint('Route OSRM : ${points.length} points récupérés.');
          }
        }
      }
    } catch (e) {
      debugPrint('OSRM routing error: $e');
    } finally {
      _isFetchingRoute = false;
    }
  }

  /// Retourne la destination selon l'état de la course
  LatLng? _getDestinationCoords() {
    if (_activeRide == null) return null;
    if (!_rideStarted) {
      final lat = _activeRide!['pickup_lat'];
      final lng = _activeRide!['pickup_lng'];
      if (lat != null && lng != null) {
        return LatLng((lat as num).toDouble(), (lng as num).toDouble());
      }
    } else {
      final lat = _activeRide!['dropoff_lat'];
      final lng = _activeRide!['dropoff_lng'];
      if (lat != null && lng != null) {
        return LatLng((lat as num).toDouble(), (lng as num).toDouble());
      }
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────
  //  Active Ride API
  // ──────────────────────────────────────────────────────────────────────
  void _startActiveRidePolling() {
    _rideRefreshTimer?.cancel();
    _rideRefreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _loadActiveRide(silent: true);
    });
  }

  Future<void> _loadActiveRide({bool silent = false}) async {
    try {
      final ride = await _apiService.getActiveRide();
      if (mounted) {
        final hadRideBefore = _activeRide != null;
        final hasRideNow = ride != null;
        setState(() {
          _activeRide = ride;
          if (!silent) {
            _isLoading = false;
          }
          _rideStarted = ride != null && (ride['ride_started'] == true);
          if (_activeRide == null) {
            _routeDistanceKm = null;
            _routeDurationMin = null;
            _routePoints = [];
          }
        });
        if (hasRideNow) {
          _stopRoaming();
          await _fetchRoute();
          _focusMapOnRide();
        } else {
          // Pas de course → démarrer le roaming
          _startRoaming();
        }
        if (!hadRideBefore && hasRideNow) {
          _showSnack('Nouvelle course active detectee', const Color(0xFF4ADE80));
        }
      }
    } catch (e) {
      if (mounted) {
        if (!silent) {
          setState(() => _isLoading = false);
          _startRoaming();
        }
      }
    }
  }

  Future<void> _startRide() async {
    if (_activeRide == null) return;
    setState(() => _isActionLoading = true);
    try {
      await _apiService.updateRideStatus(_activeRide!['id'], 'start');
      setState(() {
        _rideStarted = true;
        _isActionLoading = false;
        _routePoints = [];
        _routeDistanceKm = null;
        _routeDurationMin = null;
      });
      _showSnack('Course démarrée ! 🚕', const Color(0xFF4ADE80));
      await _fetchRoute();
    } catch (e) {
      setState(() => _isActionLoading = false);
      _showSnack('Erreur lors du démarrage', Colors.redAccent);
    }
  }

  Future<void> _endRide() async {
    if (_activeRide == null) return;
    setState(() => _isActionLoading = true);
    try {
      await _apiService.updateRideStatus(_activeRide!['id'], 'complete');
      setState(() {
        _activeRide = null;
        _rideStarted = false;
        _routePoints = [];
        _routeDistanceKm = null;
        _routeDurationMin = null;
        _isActionLoading = false;
      });
      _showSnack('Course terminée ! ✅', const Color(0xFFFFCC00));
      // Reprendre le roaming après la fin de la course
      _startRoaming();
    } catch (e) {
      setState(() => _isActionLoading = false);
      _showSnack('Erreur lors de la fin', Colors.redAccent);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _roamTimer?.cancel();
    _rideRefreshTimer?.cancel();
    _socketTimer?.cancel();
    _simulationTimer?.cancel();
    _positionSubscription?.cancel();
    _pulseController.dispose();
    _mapController.dispose();
    _locationChannel?.sink.close();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return DriverLayout(
        title: 'Active Ride',
        currentIndex: 2,
        child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFCC00))),
      );
    }

    // Permission refusée
    if (!_permissionGranted) {
      return DriverLayout(
        title: 'Active Ride',
        currentIndex: 2,
        child: _buildPermissionDenied(),
      );
    }

    if (_activeRide == null) {
      // Pas de course → afficher la carte avec le taxi en roaming
      return DriverLayout(
        title: 'Active Ride',
        currentIndex: 2,
        child: _buildRoamingView(),
      );
    }

    return DriverLayout(
      title: 'Active Ride',
      currentIndex: 2,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildMap(height: 340),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildDetails(),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  //  No-permission fallback
  // ──────────────────────────────────────────────────────────────────────
  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, color: Color(0xFFF87171), size: 72),
            const SizedBox(height: 20),
            const Text(
              'Localisation requise',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'SmartPickup a besoin de votre localisation pour fonctionner correctement.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCC00),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.location_on),
              label: const Text('Autoriser la localisation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: () async {
                final bool granted = kIsWeb
                    ? await _requestWebLocationPermission()
                    : await LocationPermissionService.requestWithDialog(context);
                if (mounted) {
                  setState(() => _permissionGranted = granted);
                  if (granted) _initLocationAndRide();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  //  ROAMING VIEW (aucune course)
  // ──────────────────────────────────────────────────────────────────────
  Widget _buildRoamingView() {
    return Column(
      children: [
        _buildMap(height: MediaQuery.of(context).size.height * 0.55),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (_, __) => Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Disponible — En attente d\'une course',
                          style: TextStyle(
                            color: Color(0xFF4ADE80),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'En attente d\'une course 🚕',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Votre position GPS est mise à jour en temps réel. Acceptez une course depuis le Dashboard ou l\'onglet Requests.',
                    style:
                        TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  if (_originalPosition != null) ...[
                    _positionCard(
                      label: 'Position Originale',
                      icon: Icons.home_rounded,
                      color: const Color(0xFF60A5FA),
                      lat: _originalPosition!.latitude,
                      lng: _originalPosition!.longitude,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_currentPosition != null)
                    _positionCard(
                      label: 'Position Actuelle',
                      icon: Icons.my_location,
                      color: const Color(0xFFFFCC00),
                      lat: _currentPosition!.latitude,
                      lng: _currentPosition!.longitude,
                    ),
                  const SizedBox(height: 24),
                  if (_originalPosition != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFFCC00)),
                          foregroundColor: const Color(0xFFFFCC00),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.home_rounded, size: 20),
                        label: const Text(
                          'Recentrer sur ma position originale',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          if (_mapReady && _originalPosition != null) {
                            _mapController.move(_originalPosition!, 15.0);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _positionCard({
    required String label,
    required IconData icon,
    required Color color,
    required double lat,
    required double lng,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  'Lat: ${lat.toStringAsFixed(5)}  •  Lng: ${lng.toStringAsFixed(5)}',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  //  MAP
  // ──────────────────────────────────────────────────────────────────────
  Widget _buildMap({double? height}) {
    final LatLng center =
        _currentPosition ?? const LatLng(36.8065, 10.1815); // Tunis by default if no GPS yet

    final map = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15.0,
        onMapReady: () {
          _mapReady = true;
          if (_currentPosition != null) {
            _mapController.move(_currentPosition!, 15.0);
          }
        },
        onPositionChanged: (_, hasGesture) {
          if (hasGesture && _followMode) {
            setState(() => _followMode = false);
          }
        },
      ),
      children: [
        // ── Tuiles CARTO Dark Matter (gratuit, sans clé API) ──
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.example.app',
          maxZoom: 20,
        ),

        // ── Cercle roaming (uniquement sans course active) ──
        if (_activeRide == null && _originalPosition != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: _originalPosition!,
                radius: 300,
                useRadiusInMeter: true,
                color: const Color(0xFF60A5FA).withOpacity(0.08),
                borderColor: const Color(0xFF60A5FA).withOpacity(0.3),
                borderStrokeWidth: 1.5,
              ),
            ],
          ),

        // ── Itinéraire (polyline OSRM Directions) ──
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              // Ombre
              Polyline(
                points: _routePoints,
                color: Colors.black.withOpacity(0.4),
                strokeWidth: 9.0,
              ),
              // Route principale jaune
              Polyline(
                points: _routePoints,
                color: const Color(0xFFFFCC00),
                strokeWidth: 5.0,
              ),
            ],
          ),

        // ── Markers ──
        MarkerLayer(
          markers: [
            // ── Marqueur position ORIGINALE (maison bleue) ──
            if (_originalPosition != null && _activeRide == null)
              Marker(
                width: 44,
                height: 44,
                point: _originalPosition!,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF60A5FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Base',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold)),
                    ),
                    const Icon(Icons.home_rounded,
                        color: Color(0xFF60A5FA), size: 26),
                  ],
                ),
              ),

            // ── Marqueur PICKUP (si pas encore démarré) ──
            if (_activeRide != null && _activeRide!['pickup_lat'] != null && !_rideStarted)
              Marker(
                width: 50,
                height: 60,
                point: LatLng(
                  (_activeRide!['pickup_lat'] as num).toDouble(),
                  (_activeRide!['pickup_lng'] as num).toDouble(),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF60A5FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Pickup',
                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.person_pin_circle, color: Color(0xFF60A5FA), size: 38),
                  ],
                ),
              ),

            // ── Marqueur DESTINATION (Drop-off) ──
            if (_activeRide != null && _activeRide!['dropoff_lat'] != null)
              Marker(
                width: 50,
                height: 60,
                point: LatLng(
                  (_activeRide!['dropoff_lat'] as num).toDouble(),
                  (_activeRide!['dropoff_lng'] as num).toDouble(),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF87171),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Destination',
                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.flag_rounded, color: Color(0xFFF87171), size: 38),
                  ],
                ),
              ),

            // ── Marqueur TAXI (image réelle avec rotation) ──
            if (_currentPosition != null)
              Marker(
                width: 80,
                height: 80,
                point: _currentPosition!,
                child: Transform.rotate(
                  angle: _taxiHeading * (math.pi / 180),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Cercle de pulsation
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (_, __) => Container(
                          width: 62 * _pulseAnimation.value,
                          height: 62 * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFFCC00).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Car icon
                      Image.asset(
                        'assets/taxi_car.png',
                        width: 45,
                        height: 45,
                        errorBuilder: (_, __, ___) => Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFCC00).withOpacity(0.9),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: const Icon(Icons.local_taxi, color: Colors.black, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    return SizedBox(
      height: height ?? 340,
      child: Stack(
        children: [
          map,
          // Center on me button
          // ── Follow mode button (lock camera on GPS) ──
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'follow_btn',
              backgroundColor: _followMode
                  ? const Color(0xFFFFCC00)
                  : const Color(0xFF1A1A1A),
              foregroundColor: _followMode ? Colors.black : Colors.white,
              onPressed: () {
                setState(() => _followMode = !_followMode);
                if (_followMode && _currentPosition != null) {
                  _mapController.move(_currentPosition!, 15.5);
                }
              },
              child: Icon(
                _followMode ? Icons.navigation : Icons.navigation_outlined,
              ),
            ),
          ),
          // ── Simulation toggle ──
          Positioned(
            bottom: 16,
            right: 70,
            child: FloatingActionButton.small(
              heroTag: 'sim_toggle_btn',
              backgroundColor:
                  _simulateMode ? const Color(0xFF60A5FA) : const Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              onPressed: _toggleSimulationMode,
              child:
                  Icon(_simulateMode ? Icons.smart_toy : Icons.smart_toy_outlined),
            ),
          ),
          _buildCoordinatesOverlay(),
          if (_currentPosition == null)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFFFCC00)),
                    SizedBox(height: 12),
                    Text('Waiting for GPS...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  //  DETAILS PANEL (course active)
  // ──────────────────────────────────────────────────────────────────────
  Widget _buildDetails() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _rideStarted ? 'RIDE IN PROGRESS' : 'ON THE WAY',
                      style: const TextStyle(
                        color: Color(0xFFFFCC00),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      _activeRide!['passenger'] ?? 'Passenger',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _routeDurationMin != null
                      ? '~$_routeDurationMin min'
                      : (_activeRide!['eta'] ?? '--'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DESTINATION',
                  style: TextStyle(
                    color: Color(0xFFA0A0A0),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _activeRide!['dropoff'] ?? 'Destination',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _isActionLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _rideStarted ? const Color(0xFFEF4444) : const Color(0xFFFFCC00),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: _rideStarted ? _endRide : _startRide,
                        child: Text(
                          _rideStarted ? 'COMPLETE RIDE' : 'START RIDE',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Petit overlay flottant pour afficher les coordonnées (X, Y) en temps réel
  Widget _buildCoordinatesOverlay() {
    if (_currentPosition == null) return const SizedBox.shrink();
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFCC00).withOpacity(0.4)),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.gps_fixed, color: Color(0xFFFFCC00), size: 14),
            const SizedBox(width: 8),
            Text(
              'X: ${_currentPosition!.latitude.toStringAsFixed(5)}  •  Y: ${_currentPosition!.longitude.toStringAsFixed(5)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
