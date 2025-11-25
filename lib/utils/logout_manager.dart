import 'package:flutter/material.dart';

import '../auth_service.dart';
import '../loginpage.dart' show LoginPage;

Future<void> logoutAndNavigateToLogin(BuildContext context) async {
  await AuthService.logout();
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}
