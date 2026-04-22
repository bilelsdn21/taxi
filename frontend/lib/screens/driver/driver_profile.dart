import 'package:flutter/material.dart';
import '../auth/driver_layout.dart';
import '../../services/driver_api_service.dart';

class DriverProfile extends StatefulWidget {
  const DriverProfile({Key? key}) : super(key: key);

  @override
  _DriverProfileState createState() => _DriverProfileState();
}

class _DriverProfileState extends State<DriverProfile> {
  bool _isEditing = false;
  bool _isAvailable = true;

  Map<String, String> _profileData = {
    'name': '',
    'email': '',
    'phone': '',
  };

  Map<String, String> _vehicleData = {
    'make': '',
    'model': '',
    'year': '',
    'plate': '',
    'color': ''
  };

  Map<String, dynamic> _performance = {
    'totalTrips': 0,
    'acceptanceRate': '0%',
    'rejectionRate': '0%',
    'reliabilityScore': 0.0,
    'averageRating': 0.0,
  };

  final DriverApiService _apiService = DriverApiService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final profile = await _apiService.getProfile();
      Map<String, dynamic>? taxiData;
      try {
        taxiData = await _apiService.getTaxi();
      } catch (e) {
        taxiData = null;
      }
      
      setState(() {
        _profileData = {
          'name': profile['full_name'] ?? '',
          'email': profile['email'] ?? '',
          'phone': profile['phone'] ?? '',
        };
        if (taxiData != null && taxiData.isNotEmpty) {
           _vehicleData = {
             'make': taxiData['vehicle_brand'] ?? '',
             'model': taxiData['vehicle_model'] ?? '',
             'year': taxiData['vehicle_year']?.toString() ?? '',
             'plate': taxiData['plate_number'] ?? '',
             'color': taxiData['color'] ?? '',
           };
        }
        
        if (profile['driver_profile'] != null) {
          _performance['totalTrips'] = profile['driver_profile']['total_trips'] ?? 0;
          _performance['averageRating'] = profile['driver_profile']['average_rating'] ?? 0.0;
        }

        _isAvailable = profile['is_active'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    try {
      await _apiService.updateProfile({
         'full_name': _profileData['name'],
         'phone_number': _profileData['phone'],
      });
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update')),
      );
    }
  }

  Future<void> _toggleStatus() async {
    final newStatus = !_isAvailable;
    try {
      await _apiService.updateStatus(newStatus);
      setState(() {
        _isAvailable = newStatus;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status update failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DriverLayout(
      title: 'Profile',
      currentIndex: 4,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Profile 👤', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text('Manage your account', style: TextStyle(color: Color(0xFFA0A0A0))),
                    ],
                  ),
                ),
                if (!_isEditing)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 14),
                    label: const Text('Edit', style: TextStyle(color: Colors.white, fontSize: 12)),
                    onPressed: () => setState(() => _isEditing = true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      side: const BorderSide(color: Color(0xFF333333)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: const Color(0xFF1A1A1A),
                    ),
                  )
                else
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _handleSave,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          backgroundColor: const Color(0xFFFFCC00),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => setState(() => _isEditing = false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: const Color(0xFF1A1A1A),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Color(0xFFF87171), fontSize: 12)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Personal Information
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border.all(color: const Color(0xFF333333)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personal Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(_profileData['name']!.isNotEmpty ? _profileData['name']!.substring(0, 1).toUpperCase() : 'UI', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(width: 16),
                      if (_isEditing)
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.upload, color: Colors.white, size: 16),
                            label: const Text('Photo', style: TextStyle(color: Colors.white)),
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              side: const BorderSide(color: Color(0xFF333333)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        )
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildField('Full Name', _profileData['name']!, Icons.person, (val) => _profileData['name'] = val),
                  const SizedBox(height: 12),
                  _buildField('Email', _profileData['email']!, Icons.mail, (val) => _profileData['email'] = val),
                  const SizedBox(height: 12),
                  _buildField('Phone', _profileData['phone']!, Icons.phone, (val) => _profileData['phone'] = val),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Vehicle Information
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border.all(color: const Color(0xFF333333)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_car, color: Color(0xFFFFCC00), size: 20),
                      const SizedBox(width: 8),
                      const Text('Vehicle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildField('Make', _vehicleData['make']!, null, (val) => _vehicleData['make'] = val)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('Model', _vehicleData['model']!, null, (val) => _vehicleData['model'] = val)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildField('Year', _vehicleData['year']!, null, (val) => _vehicleData['year'] = val)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('Plate', _vehicleData['plate']!, null, (val) => _vehicleData['plate'] = val)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Documents', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  ...["Driver's License", "Registration", "Insurance"].map((doc) => Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F0F),
                          border: Border.all(color: const Color(0xFF333333)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(doc, style: const TextStyle(color: Colors.white, fontSize: 14)),
                            const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 16),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Performance & Actions at the bottom
            const Text('Performance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSmallPerfCard(Icons.local_taxi, 'Trips', '${_performance['totalTrips']}', Colors.white)),
                const SizedBox(width: 12),
                Expanded(child: _buildSmallPerfCard(Icons.check_circle_outline, 'Accept', _performance['acceptanceRate'], const Color(0xFF4ADE80))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildSmallPerfCard(Icons.trending_up, 'Reliable', '${_performance['reliabilityScore']}', const Color(0xFFFFCC00))),
                const SizedBox(width: 12),
                Expanded(child: _buildSmallPerfCard(Icons.star_border, 'Rating', '${_performance['averageRating']}', const Color(0xFFFFCC00))),
              ],
            ),

            const SizedBox(height: 32),
            const Text('Status & Actions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(_isAvailable ? Icons.flash_off : Icons.flash_on, color: Colors.black, size: 16),
                    label: Text(_isAvailable ? 'Go Offline' : 'Go Online', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _isAvailable ? const Color(0xFFFFCC00) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _toggleStatus,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white, size: 16),
                    label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFEF4444), // Red for logout
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48), // Padding at bottom for better scroll
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String value, IconData? icon, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFA0A0A0))),
        const SizedBox(height: 6),
        if (_isEditing)
          SizedBox(
            height: 40,
            child: TextField(
              controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F0F0F),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF333333))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF333333))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFCC00))),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              border: Border.all(color: const Color(0xFF333333)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: const Color(0xFFA0A0A0), size: 16),
                  const SizedBox(width: 8),
                ],
                Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSmallPerfCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: const Color(0xFF333333)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFA0A0A0))),
        ],
      ),
    );
  }
}
