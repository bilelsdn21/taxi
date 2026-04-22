import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserLayout extends StatelessWidget {
  final Widget child;

  const UserLayout({super.key, required this.child});

  Future<void> handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, "/");
  }

  void navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, "/user");
        break;
      case 1:
        Navigator.pushReplacementNamed(context, "/user/bookride");
        break;
      case 2:
        Navigator.pushReplacementNamed(context, "/user/profile");
        break;
      case 3:
        Navigator.pushReplacementNamed(context, "/user/scheduled");
        break;
      case 4:
        Navigator.pushReplacementNamed(context, "/user/history");
        break;
      case 5:
        Navigator.pushReplacementNamed(context, "/user/track_ride");
        break;
      case 6:
        Navigator.pushReplacementNamed(context, "/user/incident_rapport");
        break;
    }
  }

  int getCurrentIndex(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    switch (route) {
      case "/home":
        return 0;
      case "/user/bookride":
        return 1;
      case "/user/profile":
        return 2;
      case "/user/scheduled":
        return 3;
      case "/user/history":
        return 4;
      case "/user/track_ride":
        return 5;
      case "/user/incident_rapport":
        return 6;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = getCurrentIndex(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),

      // 🔝 HEADER
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFCC00), Color(0xFFFF9900)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_car, color: Colors.black),
            ),
            const SizedBox(width: 10),
            const Text("SmartPickup", style: TextStyle(color: Colors.white),),
          ],
        ),
        actions: [
    IconButton(
      icon: const Icon(Icons.notifications, color: Colors.white), // 🔔 en blanc
      onPressed: () {},
    ),
    IconButton(
      icon: const Icon(Icons.logout, color: Colors.white), // logout en blanc
      onPressed: () {
        handleLogout(context); // ton handleLogout
        Navigator.pushReplacementNamed(context, "/"); // redirection vers login
      },
    ),
  ],
      ),

      // 📄 CONTENT
      body: child,

      // 📱 BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F0F0F),
        selectedItemColor: const Color(0xFFFFCC00),
        unselectedItemColor: Colors.grey,
        currentIndex: currentIndex,
        onTap: (index) => navigate(context, index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: "Book"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Scheduled"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: "Reports"),
        ],
      ),
    );
  }
}