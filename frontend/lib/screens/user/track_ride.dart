import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

/// Énumération pour les statuts de course
enum RideStatus {
  confirmed,
  driverAssigned,
  driverApproaching,
  arrived,
  inProgress,
  completed
}

/// Page de suivi de course en temps réel
/// Équivalent de TrackRide.tsx en React
class TrackRidePage extends StatefulWidget {
  const TrackRidePage({Key? key}) : super(key: key);

  @override
  State<TrackRidePage> createState() => _TrackRidePageState();
}

class _TrackRidePageState extends State<TrackRidePage>
    with TickerProviderStateMixin {
  // État de la course
  RideStatus _rideStatus = RideStatus.driverApproaching;
  double _eta = 5.0; // minutes
  double _distance = 2.3; // km
  int _elapsedTime = 0; // secondes
  Timer? _updateTimer;

  // Contrôleurs d'animation
  late AnimationController _carAnimationController;
  late Animation<Offset> _carAnimation;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    // Animation de la voiture
    _carAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _carAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0.4),
      end: const Offset(0.25, 0.25),
    ).animate(CurvedAnimation(
      parent: _carAnimationController,
      curve: Curves.easeInOut,
    ));

    // Animation de fade
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();

    // Démarrer les mises à jour en temps réel
    _startRealTimeUpdates();
  }

  void _startRealTimeUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_rideStatus == RideStatus.driverApproaching && _eta > 0) {
          _eta = math.max(0, _eta - 0.1);
          _distance = math.max(0, _distance - 0.05);
        } else if (_rideStatus == RideStatus.driverApproaching && _eta <= 0) {
          _rideStatus = RideStatus.arrived;
        }

        if (_rideStatus == RideStatus.inProgress) {
          _elapsedTime++;
        }
      });
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _carAnimationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  // Données de la course
  Map<String, dynamic> get _rideData => {
        'id': 'R-2024',
        'pickup': {
          'address': '123 Main Street, Downtown',
          'time': '08:00 AM',
        },
        'dropoff': {
          'address': '456 School Road, Oakville',
          'distance': '5.2 km',
          'estimatedDuration': '15 min',
        },
        'driver': {
          'name': 'Michael Rodriguez',
          'rating': 4.9,
          'totalTrips': 1247,
          'phone': '+1 (555) 987-6543',
          'vehicle': {
            'make': 'Toyota',
            'model': 'Camry',
            'color': 'Silver',
            'plate': 'ABC-1234',
          },
        },
        'scheduledTime': '08:00 AM',
        'fare': '\$18.50',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 24),

                // Barre de progression du statut
                _buildStatusProgressBar(),
                const SizedBox(height: 24),

                // Layout responsive
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 900) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildLeftColumn(),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 1,
                            child: _buildRightColumn(),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildLeftColumn(),
                          const SizedBox(height: 24),
                          _buildRightColumn(),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Track Your Ride 🚗',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ride #${_rideData['id']} - Real-time tracking',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFa0a0a0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusProgressBar() {
    final statusSteps = [
      {'key': RideStatus.confirmed, 'label': 'Ride Confirmed', 'icon': Icons.check_circle},
      {'key': RideStatus.driverAssigned, 'label': 'Driver Assigned', 'icon': Icons.person},
      {'key': RideStatus.driverApproaching, 'label': 'Driver Approaching', 'icon': Icons.navigation},
      {'key': RideStatus.arrived, 'label': 'Driver Arrived', 'icon': Icons.location_on},
      {'key': RideStatus.inProgress, 'label': 'Ride in Progress', 'icon': Icons.directions_car},
      {'key': RideStatus.completed, 'label': 'Ride Completed', 'icon': Icons.check_circle},
    ];

    final currentStepIndex = statusSteps.indexWhere((step) => step['key'] == _rideStatus);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        border: Border.all(color: const Color(0xFF333333)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(statusSteps.length, (idx) {
            final step = statusSteps[idx];
            final isCompleted = idx <= currentStepIndex;
            
            return Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? const LinearGradient(
                                colors: [Color(0xFFFFCC00), Color(0xFFff9900)],
                              )
                            : null,
                        color: isCompleted ? null : const Color(0xFF0f0f0f),
                        border: isCompleted ? null : Border.all(color: const Color(0xFF333333), width: 2),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isCompleted
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFFCC00).withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        step['icon'] as IconData,
                        color: isCompleted ? Colors.black : const Color(0xFF555555),
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (MediaQuery.of(context).size.width > 600)
                      SizedBox(
                        width: 80,
                        child: Text(
                          step['label'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: isCompleted ? Colors.white : const Color(0xFF555555),
                            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                  ],
                ),
                if (idx < statusSteps.length - 1)
                  Container(
                    width: 40,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 40),
                    decoration: BoxDecoration(
                      gradient: idx < currentStepIndex
                          ? const LinearGradient(
                              colors: [Color(0xFFFFCC00), Color(0xFFff9900)],
                            )
                          : null,
                      color: idx < currentStepIndex ? null : const Color(0xFF333333),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      children: [
        _buildLiveMap(),
        const SizedBox(height: 24),
        _buildRouteDetails(),
      ],
    );
  }

  Widget _buildLiveMap() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        border: Border.all(color: const Color(0xFF333333)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.navigation, color: Color(0xFFFFCC00), size: 24),
              SizedBox(width: 8),
              Text(
                'Live GPS Tracking',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Carte simulée
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0f0f0f),
                border: Border.all(color: const Color(0xFF333333)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Fond de carte simulé
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.green.withOpacity(0.1),
                              Colors.blue.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Marqueur de prise en charge (vert)
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.25,
                      top: MediaQuery.of(context).size.width * 0.08,
                      child: _buildMarker(Colors.green),
                    ),

                    // Marqueur de destination (rouge)
                    Positioned(
                      right: MediaQuery.of(context).size.width * 0.15,
                      bottom: MediaQuery.of(context).size.width * 0.08,
                      child: _buildMarker(Colors.red),
                    ),

                    // Voiture animée
                    if (_rideStatus == RideStatus.driverApproaching)
                      AnimatedBuilder(
                        animation: _carAnimation,
                        builder: (context, child) {
                          return Positioned(
                            left: MediaQuery.of(context).size.width * _carAnimation.value.dx,
                            top: MediaQuery.of(context).size.width * _carAnimation.value.dy,
                            child: _buildCarMarker(),
                          );
                        },
                      ),

                    // Ligne de route
                    CustomPaint(
                      size: Size.infinite,
                      painter: _RouteLinePainter(),
                    ),

                    // Légende
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLegendItem(Colors.green, 'Pickup'),
                            const SizedBox(height: 4),
                            _buildLegendItem(const Color(0xFFFFCC00), 'Driver'),
                            const SizedBox(height: 4),
                            _buildLegendItem(Colors.red, 'Dropoff'),
                          ],
                        ),
                      ),
                    ),

                    // Badge ETA
                    if (_rideStatus == RideStatus.driverApproaching)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFCC00), Color(0xFFff9900)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFCC00).withOpacity(0.5),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Text(
                            'ETA: ${_eta.ceil()} min',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Boutons d'action de la carte
          Row(
            children: [
              Expanded(
                child: _buildMapActionButton(
                  icon: Icons.navigation,
                  label: 'Open in Maps',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMapActionButton(
                  icon: Icons.report_problem,
                  label: 'Report Issue',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarker(Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildCarMarker() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFFCC00),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFCC00).withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.directions_car,
        color: Colors.black,
        size: 24,
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0f0f0f),
          border: Border.all(color: const Color(0xFF333333)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        border: Border.all(color: const Color(0xFF333333)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          
          // Pickup
          _buildLocationItem(
            icon: Icons.location_on,
            iconColor: Colors.green,
            backgroundColor: Colors.green.withOpacity(0.2),
            label: 'PICKUP LOCATION',
            address: _rideData['pickup']['address'],
            subtitle: 'Scheduled: ${_rideData['pickup']['time']}',
          ),
          
          const SizedBox(height: 16),
          
          // Ligne de progression
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 48,
                  color: const Color(0xFF333333),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_rideData['dropoff']['distance']} • ${_rideData['dropoff']['estimatedDuration']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFa0a0a0),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Dropoff
          _buildLocationItem(
            icon: Icons.location_on,
            iconColor: Colors.red,
            backgroundColor: Colors.red.withOpacity(0.2),
            label: 'DROPOFF LOCATION',
            address: _rideData['dropoff']['address'],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String label,
    required String address,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFFa0a0a0),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFa0a0a0),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      children: [
        _buildCurrentStatus(),
        const SizedBox(height: 24),
        _buildDriverInfo(),
        const SizedBox(height: 24),
        _buildTripSummary(),
        const SizedBox(height: 24),
        if (_rideStatus != RideStatus.completed) _buildActionButtons(),
      ],
    );
  }

  Widget _buildCurrentStatus() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFCC00), Color(0xFFff9900)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_rideStatus == RideStatus.driverApproaching) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ETA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${_eta.ceil()} min',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Distance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${_distance.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ] else if (_rideStatus == RideStatus.arrived) ...[
            const Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.black),
                  SizedBox(height: 8),
                  Text(
                    'Driver Has Arrived!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your driver is waiting for you',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_rideStatus == RideStatus.inProgress) ...[
            Center(
              child: Column(
                children: [
                  const Icon(Icons.directions_car, size: 64, color: Colors.black),
                  const SizedBox(height: 8),
                  const Text(
                    'Ride in Progress',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(_elapsedTime),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDriverInfo() {
    final driver = _rideData['driver'];
    final vehicle = driver['vehicle'];
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        border: Border.all(color: const Color(0xFF333333)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Driver',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // Info du chauffeur
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.cyan],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getInitials(driver['name']),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${driver['rating']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFa0a0a0),
                          ),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(color: Color(0xFFa0a0a0)),
                        ),
                        Text(
                          '${driver['totalTrips']} trips',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFa0a0a0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF333333)),
          const SizedBox(height: 16),
          
          // Détails du véhicule
          _buildInfoRow('Vehicle', '${vehicle['make']} ${vehicle['model']}'),
          const SizedBox(height: 12),
          _buildInfoRow('Color', vehicle['color']),
          const SizedBox(height: 12),
          _buildInfoRow('Plate', vehicle['plate']),
          
          const SizedBox(height: 24),
          
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Action d'appel
                  },
                  icon: const Icon(Icons.phone, size: 20),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Action de message
                  },
                  icon: const Icon(Icons.message, size: 20),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF333333)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        border: Border.all(color: const Color(0xFF333333)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow('Ride ID', _rideData['id']),
          const SizedBox(height: 12),
          _buildInfoRow('Distance', _rideData['dropoff']['distance']),
          const SizedBox(height: 12),
          _buildInfoRow('Duration', _rideData['dropoff']['estimatedDuration']),
          
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF333333)),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fare',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFa0a0a0),
                ),
              ),
              Text(
                _rideData['fare'],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFCC00),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_rideStatus == RideStatus.driverApproaching)
          ElevatedButton(
            onPressed: () {
              setState(() {
                _rideStatus = RideStatus.inProgress;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFCC00),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Start Ride',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            // Action d'annulation
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red, width: 2),
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Cancel Ride',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFFa0a0a0),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }
}

/// Painter personnalisé pour la ligne de route
class _RouteLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFCC00)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.25, size.height * 0.25)
      ..lineTo(size.width * 0.75, size.height * 0.75);

    // Ligne en pointillés
    final dashPath = _createDashedPath(path, const <double>[10, 5]);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source, List<double> pattern) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final length = pattern[draw ? 0 : 1];
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
