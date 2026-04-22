import 'package:flutter/material.dart';

/// Modèle de notification
class NotificationModel {
  final int id;
  final String type; // 'success', 'warning', 'info', 'error'
  final String title;
  final String message;
  final String time;
  bool read;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.read = false,
  });
}

/// Widget de notifications
/// Équivalent de Notifications.tsx en React
class NotificationsWidget extends StatefulWidget {
  final String userType; // 'user' ou 'driver'

  const NotificationsWidget({
    Key? key,
    this.userType = 'user',
  }) : super(key: key);

  @override
  State<NotificationsWidget> createState() => _NotificationsWidgetState();
}

class _NotificationsWidgetState extends State<NotificationsWidget>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late List<NotificationModel> _notifications;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _initializeNotifications();
  }

  void _initializeNotifications() {
    if (widget.userType == 'user') {
      _notifications = [
        NotificationModel(
          id: 1,
          type: 'success',
          title: 'Ride Confirmed',
          message: 'Your ride for tomorrow at 8:00 AM has been confirmed',
          time: '5 min ago',
          read: false,
        ),
        NotificationModel(
          id: 2,
          type: 'info',
          title: 'Driver En Route',
          message: 'Your driver is on the way. ETA: 5 minutes',
          time: '15 min ago',
          read: false,
        ),
        NotificationModel(
          id: 3,
          type: 'warning',
          title: 'Reminder',
          message: 'Your scheduled ride starts in 1 hour',
          time: '1 hour ago',
          read: true,
        ),
        NotificationModel(
          id: 4,
          type: 'success',
          title: 'Ride Completed',
          message: 'Thank you for riding with us! Please rate your experience',
          time: '2 hours ago',
          read: true,
        ),
        NotificationModel(
          id: 5,
          type: 'error',
          title: 'Ride Cancelled',
          message: 'Your ride scheduled for 3:00 PM has been cancelled',
          time: 'Yesterday',
          read: true,
        ),
      ];
    } else {
      _notifications = [
        NotificationModel(
          id: 1,
          type: 'info',
          title: 'New Ride Request',
          message: 'Sarah Williams requested a ride. Expires in 2:30',
          time: 'Just now',
          read: false,
        ),
        NotificationModel(
          id: 2,
          type: 'warning',
          title: 'Scheduled Ride Reminder',
          message: 'You have a scheduled ride starting in 30 minutes',
          time: '5 min ago',
          read: false,
        ),
        NotificationModel(
          id: 3,
          type: 'error',
          title: 'Ride Cancelled',
          message: 'John Smith cancelled the ride scheduled for 2:00 PM',
          time: '1 hour ago',
          read: false,
        ),
        NotificationModel(
          id: 4,
          type: 'success',
          title: 'Performance Update',
          message: 'Great work! Your acceptance rate increased to 94.2%',
          time: '3 hours ago',
          read: true,
        ),
      ];
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int get _unreadCount =>
      _notifications.where((n) => !n.read).length;

  void _toggleDropdown() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _markAsRead(int id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index].read = true;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.read = true;
      }
    });
  }

  void _deleteNotification(int id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.access_time;
      case 'error':
        return Icons.error;
      default:
        return Icons.directions_car;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.yellow;
      case 'error':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _getBackgroundColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green.withOpacity(0.2);
      case 'warning':
        return Colors.yellow.withOpacity(0.2);
      case 'error':
        return Colors.red.withOpacity(0.2);
      default:
        return Colors.blue.withOpacity(0.2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Bouton de notification (icône cloche)
        _buildBellButton(),

        // Dropdown des notifications
        if (_isOpen) ...[
          // Backdrop pour fermer le dropdown
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleDropdown,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          // Panel de notifications
          Positioned(
            top: 48,
            right: 0,
            child: _buildDropdownPanel(),
          ),
        ],
      ],
    );
  }

  Widget _buildBellButton() {
    return InkWell(
      onTap: _toggleDropdown,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          border: Border.all(
            color: _isOpen ? const Color(0xFFFFCC00) : const Color(0xFF333333),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications,
              color: Colors.white,
              size: 20,
            ),
            if (_unreadCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownPanel() {
    return FadeTransition(
      opacity: _animationController,
      child: ScaleTransition(
        scale: _scaleAnimation,
        alignment: Alignment.topRight,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: 384,
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              border: Border.all(color: const Color(0xFF333333)),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(),

                // Liste des notifications
                Flexible(
                  child: _buildNotificationsList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF333333)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_unreadCount unread',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFa0a0a0),
                ),
              ),
            ],
          ),
          if (_unreadCount > 0)
            InkWell(
              onTap: _markAllAsRead,
              child: Row(
                children: const [
                  Icon(
                    Icons.check,
                    size: 16,
                    color: Color(0xFFFFCC00),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Mark all read',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFFFCC00),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (_notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.notifications_none,
                size: 48,
                color: Color(0xFFa0a0a0),
              ),
              SizedBox(height: 12),
              Text(
                'No notifications',
                style: TextStyle(
                  color: Color(0xFFa0a0a0),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _notifications.length,
      separatorBuilder: (context, index) => const Divider(
        color: Color(0xFF333333),
        height: 1,
      ),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return InkWell(
      onTap: () => _markAsRead(notification.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: !notification.read
            ? const Color(0xFF0f0f0f).withOpacity(0.5)
            : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getBackgroundColor(notification.type),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(notification.type),
                color: _getIconColor(notification.type),
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!notification.read)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFCC00),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFa0a0a0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.time,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF555555),
                    ),
                  ),
                ],
              ),
            ),

            // Bouton de suppression
            IconButton(
              icon: const Icon(
                Icons.close,
                size: 16,
                color: Color(0xFFa0a0a0),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _deleteNotification(notification.id),
            ),
          ],
        ),
      ),
    );
  }
}
