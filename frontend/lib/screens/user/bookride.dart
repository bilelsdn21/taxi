/*import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class Book_ride extends StatefulWidget {
  const Book_ride({Key? key}) : super(key: key);

  @override
  _BookRideState createState() => _BookRideState();
}

class _BookRideState extends State<Book_ride> {
  TextEditingController _dateController = TextEditingController();
  TextEditingController _timeController = TextEditingController();

  LatLng? pickup;
  LatLng? dropoff;

  bool selectingPickup = false;
  bool selectingDropoff = false;
  bool isScheduled = false;

  List<String> selectedDays = [];
  final List<Map<String, String>> weekDays = [
    {"value": "Lundi", "label": "L"},
    {"value": "Mardi", "label": "Ma"},
    {"value": "Mercredi", "label": "Me"},
    {"value": "Jeudi", "label": "J"},
    {"value": "Vendredi", "label": "V"},
    {"value": "Samedi", "label": "S"},
    {"value": "Dimanche", "label": "D"},
  ];

  List<LatLng> route = [];
  List<Marker> markers = [];
  final MapController _mapController = MapController();
  double _currentZoom = 8.0;

  String message = "Veuillez choisir le point de départ";

  Future<void> getRoute() async {
    if (pickup == null || dropoff == null) return;

    String url = "https://router.project-osrm.org/route/v1/driving/"
        "${pickup!.longitude},${pickup!.latitude};"
        "${dropoff!.longitude},${dropoff!.latitude}"
        "?overview=full&geometries=geojson";

    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["routes"] != null && data["routes"].isNotEmpty) {
          List coords = data["routes"][0]["geometry"]["coordinates"];
          route.clear();
          for (var c in coords) {
            route.add(LatLng(c[1], c[0]));
          }
          setState(() {});
        }
      }
    } catch (e) {
      print("Erreur lors du chargement de la route: $e");
    }
  }

  void handleTap(LatLng point) {
    if (selectingPickup) {
      pickup = point;
      markers.removeWhere((m) => m.key == const ValueKey("pickup"));
      markers.add(
        Marker(
          key: const ValueKey("pickup"),
          point: point,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_pin, color: Colors.yellow, size: 40),
        ),
      );
      selectingPickup = false;
      message = "Point de départ choisi. Choisissez le point d'arrivée.";
    } else if (selectingDropoff) {
      dropoff = point;
      markers.removeWhere((m) => m.key == const ValueKey("dropoff"));
      markers.add(
        Marker(
          key: const ValueKey("dropoff"),
          point: point,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
        ),
      );
      selectingDropoff = false;
      message = "Point d'arrivée choisi. La route est affichée.";
      getRoute();
    }
    setState(() {});
  }

  void handleConfirmBooking() {
    if (pickup == null || dropoff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner les points de départ et d\'arrivée'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isScheduled && (_dateController.text.isEmpty || _timeController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner la date et l\'heure'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isScheduled && selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un jour'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Réservation confirmée avec succès!'),
        backgroundColor: Colors.green,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        pickup = null;
        dropoff = null;
        route.clear();
        markers.clear();
        isScheduled = false;
        _dateController.clear();
        _timeController.clear();
        selectedDays.clear();
        message = "Veuillez choisir le point de départ";
      });
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              width: screenWidth > 500 ? 900 : screenWidth * 0.95,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Book a Ride",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Schedule your next pickup in seconds",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    color: const Color.fromARGB(36, 143, 143, 102).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Scheduled Ride",
                                  style: TextStyle(color: Colors.white),
                                ),
                                Switch(
                                  value: isScheduled,
                                  onChanged: (value) {
                                    setState(() {
                                      isScheduled = value;
                                      if (!isScheduled) {
                                        selectedDays.clear();
                                        _dateController.clear();
                                        _timeController.clear();
                                      }
                                    });
                                  },
                                  activeColor: const Color(0xFFFFCC00),
                                  activeTrackColor: const Color(0xFFFFCC00).withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Pickup Location",
                                  style: TextStyle(color: Colors.white))),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  selectingPickup = true;
                                  selectingDropoff = false;
                                  message = "Cliquez sur la carte pour choisir le départ";
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFCC00),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.location_on, size: 20),
                              label: Text(
                                pickup != null
                                    ? "Modifier point de départ"
                                    : "Choisir point de départ",
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Dropoff Location",
                                  style: TextStyle(color: Colors.white))),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  selectingDropoff = true;
                                  selectingPickup = false;
                                  message = "Cliquez sur la carte pour choisir l'arrivée";
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFCC00),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.location_on, size: 20),
                              label: Text(
                                dropoff != null
                                    ? "Modifier point d'arrivée"
                                    : "Choisir point d'arrivée",
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          if (isScheduled)
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _dateController,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      hintText: "Date",
                                      suffixIcon: Icon(Icons.calendar_today),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(12)),
                                      ),
                                    ),
                                    onTap: () async {
                                      DateTime? pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(2026, 12, 31),
                                      );

                                      if (pickedDate != null) {
                                        setState(() {
                                          _dateController.text =
                                              "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _timeController,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      hintText: "Heure",
                                      suffixIcon: Icon(Icons.access_time),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(12)),
                                      ),
                                    ),
                                    onTap: () async {
                                      TimeOfDay? pickedTime = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );

                                      if (pickedTime != null) {
                                        setState(() {
                                          _timeController.text =
                                              "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),

                          if (isScheduled)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 15),
                                const Text("Jours de la semaine",
                                    style: TextStyle(color: Colors.white)),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  children: weekDays.map((day) {
                                    return FilterChip(
                                      label: Text(
                                        day["label"]!,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      selected: selectedDays.contains(day["value"]),
                                      onSelected: (value) {
                                        setState(() {
                                          value
                                              ? selectedDays.add(day["value"]!)
                                              : selectedDays.remove(day["value"]!);
                                        });
                                      },
                                      selectedColor: const Color(0xFFFFCC00),
                                      showCheckmark: false,
                                      backgroundColor: Colors.white.withOpacity(0.05),
                                      shape: const StadiumBorder(),
                                      side: BorderSide.none,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          const SizedBox(height: 15),

                          // Map container
                          Container(
                            height: 400,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    center: LatLng(36.8065, 10.1815),
                                    zoom: _currentZoom,
                                    onTap: (tapPos, point) => handleTap(point),
                                    onPositionChanged: (position, _) {
                                      _currentZoom = position.zoom;
                                    },
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                      userAgentPackageName: 'com.example.app',
                                    ),
                                    PolylineLayer(
                                      polylines: [
                                        Polyline(
                                          points: route,
                                          strokeWidth: 5,
                                          color: const Color(0xFFFFCC00),
                                        )
                                      ],
                                    ),
                                    MarkerLayer(markers: markers),
                                  ],
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Column(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _currentZoom =
                                                (_currentZoom + 1).clamp(0.0, 18.0);
                                            _mapController.move(_mapController.center, _currentZoom);
                                          });
                                        },
                                        child: const Icon(Icons.add),
                                        style: ElevatedButton.styleFrom(
                                          shape: const CircleBorder(),
                                          padding: const EdgeInsets.all(10),
                                          backgroundColor: Colors.black.withOpacity(0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _currentZoom =
                                                (_currentZoom - 1).clamp(0.0, 18.0);
                                            _mapController.move(_mapController.center, _currentZoom);
                                          });
                                        },
                                        child: const Icon(Icons.remove),
                                        style: ElevatedButton.styleFrom(
                                          shape: const CircleBorder(),
                                          padding: const EdgeInsets.all(10),
                                          backgroundColor: Colors.black.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: handleConfirmBooking,
                              icon: const Icon(Icons.check_circle, size: 24),
                              label: const Text(
                                'Confirm Booking',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFCC00),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}*/
