import 'package:flutter/material.dart';
import '../auth/driver_layout.dart';
import '../../services/driver_api_service.dart';

class DriverRequests extends StatefulWidget {
  const DriverRequests({Key? key}) : super(key: key);

  @override
  _DriverRequestsState createState() => _DriverRequestsState();
}

class _DriverRequestsState extends State<DriverRequests> {
  int? _expandedRequestId;

  final DriverApiService _apiService = DriverApiService();
  List<Map<String, dynamic>> _urgentRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final data = await _apiService.getAvailableRides();
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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
    // The exact same highly optimized flex layout from dashboard
    return DriverLayout(
      title: 'Requests',
      currentIndex: 1,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Urgent Requests 🔥', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Action required immediately on these requests', style: TextStyle(color: Color(0xFFA0A0A0))),
            const SizedBox(height: 24),
            
            if (_urgentRequests.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Text("No urgent requests at the moment.", style: TextStyle(color: Color(0xFFA0A0A0))),
                ),
              ),

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
                            gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(req['userName'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                              Text(req['userType'], style: const TextStyle(fontSize: 14, color: Color(0xFFA0A0A0)), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('${req['distance']} • ${req['duration']}', style: const TextStyle(fontSize: 12, color: Color(0xFFA0A0A0)), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              border: Border.all(color: const Color(0xFF333333)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text('Scheduled', style: TextStyle(fontSize: 10, color: Color(0xFFA0A0A0))),
                                Text(req['time'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFCC00)), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.1),
                              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text('EXPIRES IN', style: TextStyle(fontSize: 10, color: Color(0xFFF87171))),
                                Text(formatTime(req['expiresIn']), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF87171)), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 16),
                      Container(height: 1, color: const Color(0xFF333333)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withOpacity(0.1),
                          border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFF4ADE80), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('PICKUP LOCATION', style: TextStyle(fontSize: 10, color: Color(0xFF4ADE80))),
                                  Text(req['pickup'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFF87171), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('DROPOFF LOCATION', style: TextStyle(fontSize: 10, color: Color(0xFFF87171))),
                                  Text(req['dropoff'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            )
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
                            icon: const Icon(Icons.info_outline, color: Color(0xFFFFCC00), size: 12),
                            label: Text(isExpanded ? 'Hide' : 'Details', style: const TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () => toggleRequestDetails(req['id']),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              side: const BorderSide(color: Color(0xFFFFCC00)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle, color: Colors.white, size: 12),
                            label: const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () async {
                              try {
                                await _apiService.acceptRide(req['id']);
                                setState(() {
                                  _urgentRequests.removeWhere((r) => r['id'] == req['id']);
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Course acceptée !'),
                                      backgroundColor: Color(0xFF22C55E),
                                    ),
                                  );
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
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              backgroundColor: const Color(0xFF22C55E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 3,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.cancel, color: Color(0xFFF87171), size: 12),
                            label: const Text('Reject', style: TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () async {
                              setState(() {
                                _urgentRequests.removeWhere((r) => r['id'] == req['id']);
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Request rejected')),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
