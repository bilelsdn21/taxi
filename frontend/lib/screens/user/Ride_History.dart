import 'package:flutter/material.dart';

class RideHistory extends StatefulWidget {
  const RideHistory({Key? key}) : super(key: key);

  @override
  State<RideHistory> createState() => _RideHistoryState();
}

class _RideHistoryState extends State<RideHistory> {
  int hoverIndex = -1;

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
                        "Ride History",
                        style: TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.history, color: Color(0xFFFFCC00), size: 30),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'View your past rides and statistics',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔥 STATISTICS WITH HOVER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  buildStatisticsHoverCard(
                    0,
                    "48",
                    "Total Rides",
                    Icons.directions_bike,
                    Colors.blueAccent,
                  ),

                  buildStatisticsHoverCard(
                    1,
                    "768",
                    "Total Spent",
                    Icons.attach_money,
                    Colors.greenAccent,
                  ),

                  buildStatisticsHoverCard(
                    2,
                    "4.8",
                    "Avg Rating",
                    Icons.star,
                    Colors.orangeAccent,
                  ),

                  buildStatisticsHoverCard(
                    3,
                    "12",
                    "Rides This Month",
                    Icons.calendar_today,
                    Colors.purpleAccent,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// 🔥 SCHEDULE WITH HOVER
            buildScheduleHoverCard(
              10,
              "Monday, Sep 20",
              "Driver: John Doe",
              "123 Main St",
              "456 Elm St",
              "2 days ago",
              "\$15.00",
              "12 mins",
              true,
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 STAT HOVER
  Widget buildStatisticsHoverCard(
    int index,
    String data,
    String title,
    IconData icon,
    Color color,
  ) {
    return MouseRegion(
      onEnter: (_) => setState(() => hoverIndex = index),
      onExit: (_) => setState(() => hoverIndex = -1),
      child: buildStatisticsCard(title, data, icon, color, hoverIndex == index),
    );
  }

  /// 🔥 SCHEDULE HOVER
  Widget buildScheduleHoverCard(
    int index,
    String title,
    String subtitle,
    String pickup,
    String dropoff,
    String days,
    String price,
    String duration,
    bool isCompleted,
  ) {
    return MouseRegion(
      onEnter: (_) => setState(() => hoverIndex = index),
      onExit: (_) => setState(() => hoverIndex = -1),
      child: buildScheduleCard(
        title,
        subtitle,
        pickup,
        dropoff,
        days,
        price,
        duration,
        isCompleted,
        hoverIndex == index,
      ),
    );
  }
}

/// 🔥 STAT CARD
Widget buildStatisticsCard(
  String title,
  String data,
  IconData icon,
  Color color,
  bool isHover,
) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: double.infinity,
    height: 90,
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

    transform: isHover ? (Matrix4.identity()..scale(1.03)) : Matrix4.identity(),

    decoration: BoxDecoration(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isHover ? const Color(0xFFFFCC00) : Colors.white12,
        width: 1.5,
      ),
      boxShadow: isHover
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
          : [],
    ),
    child: Row(
      children: [
        Icon(icon, size: 30, color: color),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(data, style: TextStyle(fontSize: 16, color: Colors.grey[400])),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// 🔥 SCHEDULE CARD
Widget buildScheduleCard(
  String title,
  String subtitle,
  String pickup,
  String dropoff,
  String days,
  String price,
  String duration,
  bool isCompleted,
  bool isHover,
) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: const EdgeInsets.all(16),

    transform: isHover ? (Matrix4.identity()..scale(1.02)) : Matrix4.identity(),

    decoration: BoxDecoration(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isHover ? const Color(0xFFFFCC00) : Colors.white12,
        width: 1.5,
      ),
    ),

    child: Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                if (isCompleted)
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

            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),

            const SizedBox(height: 10),

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
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

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
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white54, size: 14),
                const SizedBox(width: 6),
                Text(
                  duration,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),

        Positioned(
          top: 0,
          right: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 14,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.star,
                  color: Colors.orangeAccent,
                  size: 18,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
