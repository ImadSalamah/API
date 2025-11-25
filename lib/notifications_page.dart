// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'dart:convert';
import 'Secretry/account_approv.dart';
import 'package:dcs/config/api_config.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    // استبدل userId بمعرف المستخدم الحقيقي إذا توفر
    const userId = 'dummyUserId';
    final url = Uri.parse('${ApiConfig.baseUrl}/notifications/$userId');
    final response = await http.get(url);
    final List<Map<String, dynamic>> notifs = [];
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      for (final notif in data) {
        notifs.add(Map<String, dynamic>.from(notif));
      }
      notifs.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
    }
    setState(() {
      notifications = notifs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(child: Text('لا يوجد إشعارات'))
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          notif['read'] == false ? Icons.notifications_active : Icons.notifications,
                          color: notif['read'] == false ? Colors.red : Colors.grey,
                        ),
                        title: Text(notif['title'] ?? ''),
                        subtitle: Text(notif['message'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (notif['read'] == false)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: GestureDetector(
                                  onTap: () async {
                                    // استبدل userId بمعرف المستخدم الحقيقي إذا توفر
                                    const userId = 'dummyUserId';
                                    final url = Uri.parse('${ApiConfig.baseUrl}/notifications/$userId/${notif['id']}');
                                    await http.patch(url, body: json.encode({'read': true}), headers: {'Content-Type': 'application/json'});
                                    setState(() {
                                      notifications[index]['read'] = true;
                                    });
                                    Navigator.pop(context, {'showBanner': true, 'bannerMessage': 'تمت قراءة الإشعار بنجاح'});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'تم',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ),
                              ),
                            if (notif['read'] == false)
                              const Text('جديد', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        onTap: () async {

                          if (notif['type'] == 'pending_account' && notif['userId'] != null) {
                            if (notif['read'] == false) {
                              const userId = 'dummyUserId';
                              final url = Uri.parse('${ApiConfig.baseUrl}/notifications/$userId/${notif['id']}');
                              await http.patch(url, body: json.encode({'read': true}), headers: {'Content-Type': 'application/json'});
                              setState(() {
                                notifications[index]['read'] = true;
                              });
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AccountApprovalPage(
                                  initialUserId: notif['userId'],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
