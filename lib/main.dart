import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'dart:convert';

import 'providers/language_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/secretary_provider.dart';

import '../loginpage.dart';
import 'dashboard/doctor_dashboard.dart';
import 'dashboard/nurse_dashboard.dart';
import 'dashboard/secretary_dashboard.dart';
import 'dashboard/student_dashboard.dart';
import 'dashboard/admin_dashboard.dart';
import 'dashboard/radiology_dashboard.dart';
import 'package:dcs/config/api_config.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// إعدادات API الجديدة (اضبط العنوان من ملف config/api_config.dart)
const String _apiBaseUrl = ApiConfig.baseUrl;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // إعداد الإشعارات المحلية
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
  
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
  
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => PatientProvider()),
        ChangeNotifierProvider(create: (context) => SecretaryProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      title: 'DC_AAUP',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      routes: {
        '/student-dashboard': (context) => const StudentDashboard(),
        '/doctor-dashboard': (context) => const SupervisorDashboard(),
        '/secretary-dashboard': (context) => const SecretaryDashboard(),
        '/nurse-dashboard': (context) => const NurseDashboard(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/radiology-dashboard': (context) => const RadiologyDashboard(),
      },
      locale: languageProvider.currentLocale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const LoginPage(),
    );
  }
}

// دالة للاستماع للإشعارات من Oracle بدلاً من Firebase
void listenForNotifications(String userId) async {
  // يمكنك استخدام تقنيات مختلفة للاستماع للإشعارات:
  
  // 1. Polling: طلب دوري للسيرفر للتحقق من وجود إشعارات جديدة
  // 2. WebSockets: اتصال مباشر ومستمر مع السيرفر
  // 3. Push Notifications: استخدام خدمات مثل FCM مع السيرفر
  
  // هنا مثال على الـ Polling (أبسط طريقة)
  if (kDebugMode) {
    print("بدء الاستماع للإشعارات للمستخدم: $userId");
  }
  
  // هذا مثال بسيط - في التطبيق الحقيقي تحتاج لتخزين آخر وقت تحقق
  // وتنفيذ آلية أكثر كفاءة
  _checkForNotifications(userId);
}

// دالة للتحقق من الإشعارات (Polling)
void _checkForNotifications(String userId) async {
  try {
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/notifications/$userId?unread=true'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> notifications = json.decode(response.body);
      
      for (var notification in notifications) {
        if (notification['read'] == false) {
          showLocalNotification(notification['title'], notification['message']);
          
          // تحديث حالة الإشعار كمقروء (اختياري)
          await http.patch(
            Uri.parse('$_apiBaseUrl/notifications/$userId/${notification['id']}'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'read': true}),
          );
        }
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('خطأ في جلب الإشعارات: $e');
    }
  }
  
  // التحقق مرة أخرى بعد فترة (مثال: كل 30 ثانية)
  Future.delayed(const Duration(seconds: 30), () {
    _checkForNotifications(userId);
  });
}

// دالة لعرض الإشعارات المحلية
void showLocalNotification(String? title, String? body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your_channel_id',
    'Notifications',
    channelDescription: 'Channel for app notifications',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );
  
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  
  await flutterLocalNotificationsPlugin.show(
    0,
    title ?? 'تنبيه',
    body ?? '',
    platformChannelSpecifics,
    payload: '',
  );
}

// دالة مساعدة للاتصال بالـ API
class ApiService {
  static const String baseUrl = _apiBaseUrl;

  static Future<http.Response> get(String endpoint) async {
    try {
      return await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    try {
      return await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    try {
      return await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> delete(String endpoint) async {
    try {
      return await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      rethrow;
    }
  }
}
