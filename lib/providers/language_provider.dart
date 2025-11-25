// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import '../loginpage.dart' show UserRole;

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('ar');
  bool _isEnglish = false;
  UserRole? _currentUserRole;
  String? _currentUserId;
  String? _userName;
  String? _userImage;

  Locale get currentLocale => _currentLocale;
  bool get isEnglish => _isEnglish;
  UserRole? get currentUserRole => _currentUserRole;
  String? get currentUserId => _currentUserId;
  String? get userName => _userName;
  String? get userImage => _userImage;

  void setUserId(String userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  void toggleLanguage() {
    _isEnglish = !_isEnglish;
    _currentLocale = _isEnglish ? const Locale('en') : const Locale('ar');
    notifyListeners();
  }

  void setUserRole(UserRole role) {
    _currentUserRole = role;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _currentLocale = locale;
    notifyListeners();
  }

  void setUserData({
    required UserRole role,
    required String userId,
    String? userName,
    String? userImage,
  }) {
    _currentUserRole = role;
    _currentUserId = userId;
    _userName = userName;
    _userImage = userImage;
    notifyListeners();
  }

  UserRole? parseUserRole(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'secretary':
        return UserRole.secretary;
      case 'doctor':
        return UserRole.doctor;
      case 'patient':
        return UserRole.patient;
      case 'security':
        return UserRole.security;
      case 'dental_student':
        return UserRole.dental_student;
      case 'radiology':
        return UserRole.radiology;
      default:
        return null;
    }
  }

  void printProviderState() {
  }
}