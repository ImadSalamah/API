import 'package:flutter/material.dart';
import 'admin_sidebar.dart';
import 'admin_translations.dart';

class AdminScaffold extends StatefulWidget {
  final Widget body;
  final String? title;
  final String? userName;
  final String? userImageUrl;
  final VoidCallback? onLogout;
  final Color primaryColor;
  final Color accentColor;
  final List<Map<String, dynamic>> allUsers; // إضافة هذا المتغير

  const AdminScaffold({
    super.key,
    required this.body,
    this.title,
    this.userName,
    this.userImageUrl,
    this.onLogout,
    required this.allUsers, // جعله required
    this.primaryColor = const Color(0xFF2A7A94),
    this.accentColor = const Color(0xFF4AB8D8),
  });

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  bool isSidebarOpen = false;

  String _translate(BuildContext context, String key) {
    final locale = Localizations.localeOf(context).languageCode;
    return adminTranslations[key]?[locale] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title ?? ''),
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            setState(() {
              isSidebarOpen = !isSidebarOpen;
            });
          },
        ),
        actions: [
          if (widget.onLogout != null)
            IconButton(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout, color: Colors.white),
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: widget.body),
          if (isSidebarOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    isSidebarOpen = false;
                  });
                },
                child: Container(
                  color: Colors.black.withAlpha(77),
                  alignment: Directionality.of(context) == TextDirection.rtl
                      ? Alignment.topRight
                      : Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () {},
                    child: SizedBox(
                      width: 260,
                      height: double.infinity,
                      child: Material(
                        elevation: 8,
                        child: Stack(
                          children: [
                            AdminSidebar(
                              primaryColor: widget.primaryColor,
                              accentColor: widget.accentColor,
                              userName: widget.userName,
                              userImageUrl: widget.userImageUrl,
                              onLogout: widget.onLogout ?? () {
                                if (mounted) {
                                  Navigator.of(context).pushReplacementNamed('/');
                                }
                              },
                              parentContext: context,
                              translate: _translate,
                              allUsers: widget.allUsers,
                              userRole: 'admin', // إضافة userRole هنا
                            ),
                            Positioned(
                              top: 8,
                              right: Directionality.of(context) == TextDirection.rtl ? null : 0,
                              left: Directionality.of(context) == TextDirection.rtl ? 0 : null,
                              child: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    isSidebarOpen = false;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
