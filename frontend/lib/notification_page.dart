import 'package:flutter/material.dart';

// Simple Notification Service for state management
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  List<Map<String, dynamic>> _notifications = [
    // Pending
    {
      'id': 'p1',
      'type': 'Pending',
      'title': 'MyKad Replacement Payment',
      'message': 'Payment of RM 10.00 is pending for your replacement request.',
      'time': '2 hours ago',
      'icon': Icons.payment,
      'color': Colors.orange,
      'hasAction': true,
      'isRead': false,
    },
    {
      'id': 'p2',
      'type': 'Pending',
      'title': 'LHDN Tax Assessment',
      'message': 'Please review your tax assessment for 2024.',
      'time': '1 day ago',
      'icon': Icons.receipt_long,
      'color': Colors.blue,
      'hasAction': true,
      'isRead': false,
    },
    // Complete
    {
      'id': 'c1',
      'type': 'Complete',
      'title': 'Passport Collection',
      'message': 'Your passport is ready for collection at UTC Pudu.',
      'time': '3 days ago',
      'icon': Icons.check_circle,
      'color': Colors.green,
      'hasAction': false,
      'isRead': true,
    },
    {
      'id': 'c2',
      'type': 'Complete',
      'title': 'Profile Update',
      'message': 'Your phone number has been successfully updated.',
      'time': '1 week ago',
      'icon': Icons.person,
      'color': Colors.purple,
      'hasAction': false,
      'isRead': true,
    },
    // Benefit
    {
      'id': 'b1',
      'type': 'Government Benefit',
      'title': 'Sumbangan Tunai Rahmah (STR)',
      'message': 'Phase 1 payment of RM 500 has been credited to your account.',
      'time': 'Yesterday',
      'icon': Icons.volunteer_activism,
      'color': Colors.pink,
      'hasAction': true,
      'isRead': false,
    },
    {
      'id': 'b2',
      'type': 'Government Benefit',
      'title': 'e-Madani Credit',
      'message': 'Claim your RM 100 e-wallet credit now.',
      'time': '2 days ago',
      'icon': Icons.account_balance_wallet,
      'color': Colors.teal,
      'hasAction': true,
      'isRead': false,
    },
    // Emergency
    {
      'id': 'e1',
      'type': 'Emergency',
      'title': 'Flood Alert',
      'message': 'Heavy rain warning in your registered area (Klang Valley).',
      'time': '1 hour ago',
      'icon': Icons.warning,
      'color': Colors.red,
      'hasAction': true,
      'isRead': false,
    },
  ];

  List<Map<String, dynamic>> getByType(String type) {
    return _notifications.where((n) => n['type'] == type).toList();
  }

  int get unreadCount => _notifications.where((n) => n['isRead'] == false).length;

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index != -1 && _notifications[index]['isRead'] == false) {
      _notifications[index]['isRead'] = true;
      notifyListeners();
    }
  }
}

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey[50], // Match app bg
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Notifications',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Complete'),
              Tab(text: 'Benefit'),
              Tab(text: 'Emergency'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            NotificationList(type: 'Pending'),
            NotificationList(type: 'Complete'),
            NotificationList(type: 'Government Benefit'),
            NotificationList(type: 'Emergency'),
          ],
        ),
      ),
    );
  }
}

class NotificationList extends StatefulWidget {
  final String type;

  const NotificationList({super.key, required this.type});

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NotificationService(),
      builder: (context, child) {
        final notifications = NotificationService().getByType(widget.type);

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No ${widget.type} notifications', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notif = notifications[index];
            final isEmergency = widget.type == 'Emergency';
            final isRead = notif['isRead'] as bool;
            
            return GestureDetector(
              onTap: () {
                NotificationService().markAsRead(notif['id']);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isEmergency ? Colors.red[50] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isEmergency ? Border.all(color: Colors.red[100]!, width: 1) : null,
                  boxShadow: [
                    BoxShadow(
                      color: isEmergency ? Colors.red.withOpacity(0.1) : Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Container
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isEmergency ? Colors.red : (notif['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: isEmergency 
                            ? [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Icon(
                        notif['icon'] as IconData, 
                        color: isEmergency ? Colors.white : (notif['color'] as Color), 
                        size: 20
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Unread Indicator
                              if (!isRead && !isEmergency) 
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              
                              if (isEmergency) 
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Icon(Icons.error, size: 16, color: Colors.red[700]),
                                ),
                              Expanded(
                                child: Text(
                                  notif['title'],
                                  style: TextStyle(
                                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold, // Bolder if unread
                                      fontSize: 15,
                                      color: isEmergency ? Colors.red[900] : Colors.black87
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notif['message'],
                            style: TextStyle(
                                color: isEmergency ? Colors.red[800] : (isRead ? Colors.grey[600] : Colors.black87), 
                                fontSize: 13,
                                fontWeight: isRead ? FontWeight.normal : FontWeight.w500
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            notif['time'],
                            style: TextStyle(
                                color: isEmergency ? Colors.red[400] : Colors.grey[400], 
                                fontSize: 11,
                                fontWeight: isEmergency ? FontWeight.w500 : FontWeight.normal
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (notif['hasAction'] == true)
                       Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isEmergency ? Colors.red : Colors.black,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isEmergency 
                                ? [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: const Text('View', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                       ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
