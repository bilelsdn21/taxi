import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool rideConfirm = false;
  bool driverAlert = false;
  bool promoOffers = false;
  bool scheduleReminder = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: SingleChildScrollView(
        child: Column(
          children: [
            /// HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Text(
                        "My Profile Settings",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.person, color: Colors.purple),
                    ],
                  ),

                  SizedBox(height: 5),

                  Text(
                    "Manage your account and preferences",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            /// PROFILE CARD
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFCC00), Color(0xFFFF9900)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    "https://picsum.photos/200",
                    height: 80,
                    width: 80,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "John DOE",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const Text(
                    "Member since January 2026",
                    style: TextStyle(fontSize: 14),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      profileStat("48", "Total Rides"),
                      const SizedBox(width: 15),
                      profileStat("4.9", "Rating"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            /// PERSONAL INFORMATION
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Personal Information",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  profileInfo(Icons.person, "Full Name", "John Doe"),
                  const SizedBox(height: 15),

                  profileInfo(Icons.email, "Email", "john.doe@example.com"),
                  const SizedBox(height: 15),

                  profileInfo(Icons.phone, "Phone", "+1 (555) 123-4567"),
                  const SizedBox(height: 15),

                  profileInfo(
                    Icons.location_on,
                    "Home Address",
                    "123 Main St, New York, NY 10001",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            /// PAYMENT SECTION
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text(
                    "Payment Methods",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(width: 10),

                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFCC00), Color(0xFFFF9900)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          "+ Add Card",
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            /// NOTIFICATIONS
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.notifications, color: Color(0xFFFFCC00)),
                      SizedBox(width: 8),
                      Text(
                        "Notification Preferences",
                        style: TextStyle(
                          color: Color(0xFFFFCC00),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  settingItem(
                    "Ride confirmations",
                    "Get notified when your ride is confirmed",
                    rideConfirm,
                    (value) {
                      setState(() {
                        rideConfirm = value;
                      });
                    },
                  ),

                  const Divider(color: Colors.white10),

                  settingItem(
                    "Driver arrival alerts",
                    "Alert when driver is nearby",
                    driverAlert,
                    (value) {
                      setState(() {
                        driverAlert = value;
                      });
                    },
                  ),

                  const Divider(color: Colors.white10),

                  settingItem(
                    "Promotional offers",
                    "Receive special deals and discounts",
                    promoOffers,
                    (value) {
                      setState(() {
                        promoOffers = value;
                      });
                    },
                  ),

                  const Divider(color: Colors.white10),

                  settingItem(
                    "Schedule reminders",
                    "Remind me 15 minutes before scheduled rides",
                    scheduleReminder,
                    (value) {
                      setState(() {
                        scheduleReminder = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Security & Privacy",
                    style: TextStyle(
                      color: Color(0xFFFFCC00),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  securityItem(
                    "Change Password",
                    "Update your account password",
                  ),

                  const SizedBox(height: 10),

                  securityItem(
                    "Two-Factor Authentication",
                    "Add an extra layer of security",
                  ),

                  const SizedBox(height: 10),

                  securityItem(
                    "Privacy Settings",
                    "Manage your data and privacy",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// PROFILE STAT
Widget profileStat(String number, String label) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.2),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}

/// PROFILE INFO
Widget profileInfo(IconData icon, String title, String value) {
  return Row(
    children: [
      Icon(icon, color: const Color(0xFFFFCC00)),

      const SizedBox(width: 12),

      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ],
  );
}

/// SETTING ITEM
Widget settingItem(
  String title,
  String subtitle,
  bool value,
  Function(bool) onChanged,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),

        Switch(
          value: value,
          activeColor: const Color(0xFFFFCC00),
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

/// SECURITY ITEM
Widget securityItem(String title, String subtitle) {
  return _SecurityItem(title: title, subtitle: subtitle);
}

class _SecurityItem extends StatefulWidget {
  final String title;
  final String subtitle;

  const _SecurityItem({required this.title, required this.subtitle});

  @override
  State<_SecurityItem> createState() => _SecurityItemState();
}

class _SecurityItemState extends State<_SecurityItem> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          isHover = true;
        });
      },

      onExit: (_) {
        setState(() {
          isHover = false;
        });
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),

          border: Border.all(
            color: isHover ? const Color(0xFFFFCC00) : Colors.white12,
          ),
        ),

        child: Row(
          children: [
            const Icon(Icons.security, color: Color(0xFFFFCC00)),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    widget.subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }
}
