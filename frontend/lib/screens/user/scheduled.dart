import 'package:flutter/material.dart';

class Scheduled extends StatefulWidget {
  const Scheduled({super.key});

  @override
  State<Scheduled> createState() => _ScheduledState();
}

class _ScheduledState extends State<Scheduled> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Scheduled',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Row(
                            children: const [
                              Text(
                                'Rides',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.calendar_month,
                                color: Color(0xFFFFCC00),
                                size: 28,
                              ),
                            ],
                          ),
                        ],
                      ),

                      /// BUTTON
                      ElevatedButton(
                         onPressed: () {
    Navigator.pushNamed(context, '/user/schedule'); 
  },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
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
                              vertical: 8,
                            ),
                            child: Text(
                              "+ New\nSchedule",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// DESCRIPTION
                  const Text(
                    'Manage your recurring and upcoming rides',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  const SizedBox(height: 20),

                  /// CARDS
                  buildScheduledDashboard(
                    '2',
                    'Active Schedules',
                    Colors.greenAccent,
                  ),
                  buildScheduledDashboard('1', 'Pending', Color(0xFFFFCC00)),

                  buildScheduledDashboard('12', 'This Week', Colors.blueAccent),
                  const SizedBox(height: 20),
                  buildScheduleCard(
                    'Morning Commute',
                    'Driver: John Doe',
                    '123 Main St',
                    '456 Oak Ave',
                    '8:00 AM',
                    'Mon, Wed, Fri',
                    true,
                    true,
                  ),
                  buildScheduleCard(
                    'Airport Dropoff',
                    'Driver: Jane Smith',
                    '789 Pine Rd',
                    'Airport Terminal 1',
                    '5:00 PM',
                    'Tomorrow',
                    false,
                    false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CARD WIDGET
Widget buildScheduledDashboard(
  String title,
  String subtitle,
  Color titleColor,
) {
  return Container(
    width: double.infinity,
    height: 90,
    margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
      ],
    ),
  );
}

Widget buildScheduleCard(
  String title,
  String subtitle,
  String pickup,
  String dropoff,
  String time,
  String days,
  bool isRecurring,
  bool isActive,
) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white12),
    ),
    child: Stack(
      children: [
        /// 🔥 CONTENT
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE + BADGES
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),

                if (isRecurring)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Recurring',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 10,
                      ),
                    ),
                  ),

                const SizedBox(width: 6),

                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            /// DRIVER
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(height: 10),

            /// PICKUP
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.orangeAccent,
                  size: 14,
                ),
                const SizedBox(width: 6),
                const Text(
                  "Pickup:",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    pickup,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            /// DROPOFF
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.deepOrange,
                  size: 14,
                ),
                const SizedBox(width: 6),
                const Text(
                  "Dropoff:",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    dropoff,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),

            /// TIME + DAYS
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Colors.orangeAccent,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),

                const SizedBox(width: 15),

                const Icon(
                  Icons.calendar_today,
                  color: Colors.orangeAccent,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    days,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),

        /// 🔥 ACTIONS TOP RIGHT
        Positioned(
          top: 0,
          right: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.redAccent,
                  size: 18,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.info, color: Colors.white, size: 18),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
