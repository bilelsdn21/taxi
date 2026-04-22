import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class DriverApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api/driver';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/driver';
    return 'http://localhost:8000/api/driver';
  }
  final _storage = const FlutterSecureStorage();

  // On suppose que le token est sauvegardé lors du login
  // Si ce n'est pas le cas, pour tester, on peut ne pas l'utiliser ou le simuler
  Future<Map<String, String>> _getHeaders() async {
    // String? token = await _storage.read(key: 'token');
    return {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer $token', // Décommentez si l'auth est requise
    };
  }

  // --- Profil & Véhicule ---

  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(Uri.parse('$baseUrl/profile'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load profile');
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update profile');
    }
  }

  Future<Map<String, dynamic>> getTaxi() async {
    final response = await http.get(Uri.parse('$baseUrl/taxi'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load taxi info');
    }
  }

  Future<Map<String, dynamic>> updateStatus(bool isOnline) async {
    final response = await http.put(
      Uri.parse('$baseUrl/status'),
      headers: await _getHeaders(),
      body: json.encode({'is_online': isOnline}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update status');
    }
  }

  // --- Courses ---

  Future<List<dynamic>> getAvailableRides() async {
    final response = await http.get(Uri.parse('$baseUrl/rides/available'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load available rides');
    }
  }

  Future<List<dynamic>> getDriverHistory() async {
    final response = await http.get(Uri.parse('$baseUrl/rides/history'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load history');
    }
  }

  Future<Map<String, dynamic>> acceptRide(int requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rides/$requestId/accept'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to accept ride');
    }
  }

  Future<Map<String, dynamic>> cancelRide(int requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rides/$requestId/cancel'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to cancel ride');
    }
  }

  Future<Map<String, dynamic>> updateRideStatus(int requestId, String action) async {
    final response = await http.put(
      Uri.parse('$baseUrl/rides/$requestId/status'),
      headers: await _getHeaders(),
      body: json.encode({'action': action}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update ride status');
    }
  }

  Future<Map<String, dynamic>?> getActiveRide() async {
    final response = await http.get(Uri.parse('$baseUrl/rides/active'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      // FastAPI renvoie 'null' si l'endpoint retourne None
      if (jsonResponse == null) return null;
      return jsonResponse;
    } else {
      throw Exception('Failed to load active ride');
    }
  }
}
