// auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // 🔥 أضف هذا الاستيراد

class AuthService {
  // جلب التوكن من SharedPreferences
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      return null;
    }
  }

  // جلب معلومات المستخدم كاملة
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');
      if (userDataString != null) {
        return json.decode(userDataString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // جلب الـ USER_ID
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('USER_ID');
    } catch (e) {
      return null;
    }
  }

  // جلب الـ ROLE
  static Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('ROLE');
    } catch (e) {
      return null;
    }
  }

  // جلب الاسم الكامل
  static Future<String?> getFullName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('FULL_NAME');
    } catch (e) {
      return null;
    }
  }

  static Future<int> getIsDean() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('IS_DEAN') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // جلب البريد الإلكتروني
  static Future<String?> getEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('EMAIL');
    } catch (e) {
      return null;
    }
  }

  // التحقق إذا المستخدم مسجل دخول
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // تسجيل خروج وحذف البيانات
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('userData');
      await prefs.remove('USER_ID');
      await prefs.remove('ROLE');
      await prefs.remove('FULL_NAME');
      await prefs.remove('EMAIL');
      await prefs.remove('IS_DEAN');
    // ignore: empty_catches
    } catch (e) {
    }
  }

  // إنشاء headers مع التوكن
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
