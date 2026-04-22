import 'package:flutter/material.dart';
import '../auth/driver_layout.dart';
import '../../services/driver_api_service.dart';

class DriverHistory extends StatefulWidget {
  const DriverHistory({Key? key}) : super(key: key);

  @override
  _DriverHistoryState createState() => _DriverHistoryState();
}

class _DriverHistoryState extends State<DriverHistory> {
  String _searchTerm = "";
  String _filterStatus = "all";
  String _dateRange = "all";

  final DriverApiService _apiService = DriverApiService();
  List<Map<String, dynamic>> _rides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await _apiService.getDriverHistory();
      setState(() {
        _rides = data.map((e) => {
          'id': e['id'],
          'date': e['date'],
          'pickup': e['pickup'],
          'dropoff': e['dropoff'],
          'duration': e['duration'],
          'rating': e['rating'],
          'status': e['status'],
          'passenger': e['passenger'],
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRides = _rides.where((ride) {
      final matchesSearch = ride['id'].toLowerCase().contains(_searchTerm.toLowerCase()) ||
          ride['pickup'].toLowerCase().contains(_searchTerm.toLowerCase()) ||
          ride['dropoff'].toLowerCase().contains(_searchTerm.toLowerCase()) ||
          ride['passenger'].toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesStatus = _filterStatus == 'all' || ride['status'] == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();

    int completedCount = 0;
    int cancelledCount = 0;
    double totalRating = 0;
    
    for (var r in filteredRides) {
      if (r['status'] == 'completed') {
        completedCount++;
        if (r['rating'] > 0) {
          totalRating += r['rating'];
        }
      } else if (r['status'] == 'cancelled') {
        cancelledCount++;
      }
    }
    
    double avgRating = completedCount > 0 ? totalRating / completedCount : 0.0;

    return DriverLayout(
      title: 'History',
      currentIndex: 3,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text('Ride History 📜', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Complete record of all your rides', style: TextStyle(color: Color(0xFFA0A0A0))),
            const SizedBox(height: 24),

            // Stats (2x2 grid for mobile)
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Rides', '${filteredRides.length}', Colors.white)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Completed', '$completedCount', const Color(0xFF4ADE80))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Cancelled', '$cancelledCount', const Color(0xFFF87171))),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Avg Rating', avgRating.toStringAsFixed(1), Colors.white, icon: Icons.star, iconColor: const Color(0xFFFFCC00))),
              ],
            ),
            const SizedBox(height: 24),

            // Filters
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border.all(color: const Color(0xFF333333)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) => setState(() => _searchTerm = val),
                    decoration: InputDecoration(
                      hintText: 'Search ID, location, or passenger...',
                      hintStyle: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFFA0A0A0)),
                      filled: true,
                      fillColor: const Color(0xFF0F0F0F),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFCC00))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Splitting the Dropdowns into a single column so they NEVER overthrow spacing on width!
                  DropdownButtonFormField<String>(
                    value: _filterStatus,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1A1A1A),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F0F0F),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Status', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'completed', child: Text('Completed', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) => setState(() => _filterStatus = val!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _dateRange,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1A1A1A),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F0F0F),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Time', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'today', child: Text('Today', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'week', child: Text('This Week', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'month', child: Text('This Month', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) => setState(() => _dateRange = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rides List
            if (filteredRides.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Text('No rides found matching your criteria', style: TextStyle(color: Color(0xFFA0A0A0))),
                ),
              )
            else
              ...filteredRides.map((ride) => _buildRideCard(ride)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color valueColor, {IconData? icon, Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: const Color(0xFF333333)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFFA0A0A0))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor), overflow: TextOverflow.ellipsis)),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, color: iconColor, size: 20),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
    bool isCompleted = ride['status'] == 'completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: const Color(0xFF333333)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ride['id'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('${ride['date']} • ${ride['passenger']}', style: const TextStyle(fontSize: 12, color: Color(0xFFA0A0A0)), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF22C55E).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  ride['status'].toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: isCompleted ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Route Locations Column
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              border: Border.all(color: const Color(0xFF333333)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.circle, color: Color(0xFF4ADE80), size: 10),
                    const SizedBox(width: 8),
                    Expanded(child: Text(ride['pickup'], style: const TextStyle(fontSize: 14, color: Colors.white), overflow: TextOverflow.ellipsis)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Container(
                    height: 12,
                    width: 2,
                    color: const Color(0xFF333333),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.circle, color: Color(0xFFF87171), size: 10),
                    const SizedBox(width: 8),
                    Expanded(child: Text(ride['dropoff'], style: const TextStyle(fontSize: 14, color: Colors.white), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Footer Stats
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Color(0xFFA0A0A0)),
                    const SizedBox(width: 4),
                    Text(ride['duration'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              if (isCompleted && ride['rating'] > 0) ...[
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${ride['rating']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(width: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            size: 14,
                            color: index < ride['rating'] ? const Color(0xFFFFCC00) : const Color(0xFF333333),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
