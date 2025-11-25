import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../loginpage.dart';

class RoleGuard extends StatefulWidget {
  final UserRole allowedRole;
  final Widget child;
  const RoleGuard({super.key, required this.allowedRole, required this.child});

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  bool _checking = true;
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
			final prefs = await SharedPreferences.getInstance();
			final userDataJson = prefs.getString('userData');
			if (userDataJson == null) {
      _redirect();
      return;
    }
			final userData = json.decode(userDataJson);
			// استخدم ROLE بحروف كبيرة كما في الرد من السيرفر
			final role = (userData['ROLE'] ?? userData['role'])?.toString().toLowerCase();
    setState(() {
      _allowed = role == widget.allowedRole.name;
      _checking = false;
    });
    if (!_allowed) _redirect();
  }

  void _redirect() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _allowed ? widget.child : const SizedBox.shrink();
  }
}
