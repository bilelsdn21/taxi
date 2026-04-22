import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../auth/driver_layout.dart';
import '../../services/driver_api_service.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({Key? key}) : super(key: key);

  @override
  _DriverDashboardState createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  bool _isOnline = true;
  int? _expandedRequestId;
  Timer? _locationTimer;
  LatLng? _currentPosition;

  final DriverApiService _apiService = DriverApiService();
  List<Map<String, dynamic>> _urgentRequests = [];
  bool _isLoading = false;

  Map<String, dynamic>? _activeRide;
  Map<String, dynamic>? _driverProfile;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      Position p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) setState(() => _currentPosition = LatLng(p.latitude, p.longitude));
    } catch (e) {
      debugPrint('GPS initial error: $e');
    }

    _locationTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        Position p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
        );
        if (mounted) {
          final newPos = LatLng(p.latitude, p.longitude);
          setState(() => _currentPosition = newPos);
          try {
            _mapController.move(newPos, _mapController.camera.zoom);
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('GPS update error: $e');
      }
    });
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getAvailableRides();
      
      Map<String, dynamic>? currentRide;
      try {
        currentRide = await _apiService.getActiveRide();
      } catch (e) {
        currentRide = null;
      }
      
      Map<String, dynamic>? profile;
      try {
        profile = await _apiService.getProfile();
      } catch (e) {
        profile = null;
      }

      setState(() {
        _urgentRequests = data.map((e) => {
          'id': e['request_id'],
          'userName': 'Passenger',
          'userType': 'Standard',
          'pickup': e['pickup'],
          'dropoff': e['dropoff'],
          'time': 'NOW',
          'distance': '${e['distance_km']} km',
          'duration': '${e['time_mins']} min',
          'expiresIn': 60,
        }).toList();
        _activeRide = currentRide;
        _driverProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Load requests error: $e');
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void toggleRequestDetails(int id) {
    setState(() {
      _expandedRequestId = _expandedRequestId == id ? null : id;
    });
  }

  String formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return DriverLayout(
        title: 'Dashboard',
        currentIndex: 0,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFCC00)),
        ),
      );
    }
    return DriverLayout(
      title: 'Dashboard',
      currentIndex: 0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Driver Hub 🚗',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome back, ${_driverProfile != null && _driverProfile!['user'] != null ? _driverProfile!['user']['full_name'] : 'Driver'}! Manage all your rides here',
                  style: const TextStyle(color: Color(0xFFA0A0A0)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                setState(() {
                  _isOnline = !_isOnline;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: _isOnline
                      ? const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF10B981)],
                        )
                      : null,
                  color: _isOnline ? null : const Color(0xFF1A1A1A),
                  border: _isOnline
                      ? null
                      : Border.all(color: const Color(0xFF333333), width: 2),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isOnline
                      ? [
                          BoxShadow(
                            color: const Color(0xFF22C55E).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.power_settings_new,
                      color: _isOnline ? Colors.white : const Color(0xFFA0A0A0),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isOnline
                                ? Colors.white.withOpacity(0.8)
                                : const Color(0xFFA0A0A0),
                          ),
                        ),
                        Text(
                          _isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isOnline
                                ? Colors.white
                                : const Color(0xFFA0A0A0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_urgentRequests.isNotEmpty && _isOnline) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFEF4444).withOpacity(0.2),
                      const Color(0xFFF97316).withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.5),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_active,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🔥 Urgent Requests',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${_urgentRequests.length} ride${_urgentRequests.length > 1 ? 's' : ''} waiting for your response',
                                style: TextStyle(
                                  color: const Color(0xFFA0A0A0),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ..._urgentRequests.map((req) {
                      final isExpanded = _expandedRequestId == req['id'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0A),
                          border: Border.all(color: const Color(0xFF333333)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF06B6D4),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        req['userName'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        req['userType'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: const Color(0xFFA0A0A0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${req['distance']} • ${req['duration']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFFA0A0A0),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A),
                                      border: Border.all(
                                        color: const Color(0xFF333333),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Scheduled',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: const Color(0xFFA0A0A0),
                                          ),
                                        ),
                                        Text(
                                          req['time'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFFCC00),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFEF4444,
                                      ).withOpacity(0.1),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFEF4444,
                                        ).withOpacity(0.3),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'EXPIRES IN',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: const Color(0xFFF87171),
                                          ),
                                        ),
                                        Text(
                                          formatTime(req['expiresIn']),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFF87171),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isExpanded) ...[
                              const SizedBox(height: 16),
                              Container(
                                height: 1,
                                color: const Color(0xFF333333),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF22C55E,
                                  ).withOpacity(0.1),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF22C55E,
                                    ).withOpacity(0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Color(0xFF4ADE80),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'PICKUP LOCATION',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF4ADE80),
                                            ),
                                          ),
                                          Text(
                                            req['pickup'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFEF4444,
                                  ).withOpacity(0.1),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withOpacity(0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Color(0xFFF87171),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'DROPOFF LOCATION',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFFF87171),
                                            ),
                                          ),
                                          Text(
                                            req['dropoff'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(
                                      Icons.info_outline,
                                      color: Color(0xFFFFCC00),
                                      size: 12,
                                    ),
                                    label: Text(
                                      isExpanded ? 'Hide' : 'Details',
                                      style: const TextStyle(
                                        color: Color(0xFFFFCC00),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    onPressed: () =>
                                        toggleRequestDetails(req['id']),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 8,
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFFFFCC00),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  flex: 3,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    label: const Text(
                                      'Accept',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    onPressed: () async {
                                      try {
                                        await _apiService.acceptRide(req['id']);
                                        setState(() {
                                          _urgentRequests.removeWhere(
                                            (r) => r['id'] == req['id'],
                                          );
                                        });
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('✅ Course acceptée !'),
                                              backgroundColor: Color(0xFF22C55E),
                                            ),
                                          );
                                          // Navigate to active ride
                                          Navigator.pushReplacementNamed(context, '/driver/active');
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Erreur: $e')),
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 8,
                                      ),
                                      backgroundColor: const Color(0xFF22C55E),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  flex: 3,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(
                                      Icons.cancel,
                                      color: Color(0xFFF87171),
                                      size: 12,
                                    ),
                                    label: const Text(
                                      'Reject',
                                      style: TextStyle(
                                        color: Color(0xFFF87171),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    onPressed: () async {
                                      try {
                                        await _apiService.cancelRide(req['id']);
                                      } catch (_) {}
                                      setState(() {
                                        _urgentRequests.removeWhere(
                                          (r) => r['id'] == req['id'],
                                        );
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 8,
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFFEF4444),
                                        width: 2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (_isOnline) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: _activeRide != null ? const LinearGradient(
                    colors: [Color(0xFFFFCC00), Color(0xFFFF9900)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ) : const LinearGradient(
                    colors: [Color(0xFF222222), Color(0xFF111111)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFCC00).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.navigation,
                                size: 24,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _activeRide != null ? '🚕 Active Ride' : '📍 Waiting for rides...',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _activeRide != null ? Colors.black : Colors.white,
                                  ),
                                ),
                                Text(
                                  _activeRide != null ? 'In progress' : 'Online & ready',
                                  style: TextStyle(
                                    color: _activeRide != null ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.map_outlined, color: Color(0xFFFFCC00), size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'Live tracking is active',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Switch to the Active Ride tab to see the map',
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_activeRide != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PASSENGER',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black.withOpacity(0.7),
                                    ),
                                  ),
                                  Text(
                                    _activeRide!['passenger'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ETA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black.withOpacity(0.7),
                                    ),
                                  ),
                                  Text(
                                    '${_activeRide!['eta']} • ${_activeRide!['distance']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
