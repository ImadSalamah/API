import 'package:flutter/material.dart';

class RadiologySidebar extends StatelessWidget {
  final Color primaryColor;
  final Color accentColor;
  final String userName;
  final VoidCallback onHome;
  final VoidCallback onWaitingList;
  final VoidCallback onReports;
  final VoidCallback onClose;
  final bool collapsed;
  final String lang;
  final Map<String, Map<String, String>> localizedStrings;

  const RadiologySidebar({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    required this.userName,
    required this.onHome,
    required this.onWaitingList,
    required this.onReports,
    required this.onClose,
    this.collapsed = false,
    required this.lang,
    required this.localizedStrings,
  });

  Map<String, Map<String, String>> get _defaultTranslations => const {
        'home': {'ar': 'الرئيسية', 'en': 'Home'},
        'waiting_list': {'ar': 'قائمة الانتظار', 'en': 'Waiting List'},
        'xray_reports': {'ar': 'تقارير الأشعة', 'en': 'X-Ray Reports'},
        'xray_technician': {'ar': 'فني الأشعة', 'en': 'Radiology Technician'},
        'close': {'ar': 'إغلاق', 'en': 'Close'},
      };

  @override
  Widget build(BuildContext context) {
    double sidebarWidth = collapsed ? 60 : 260;
    if (MediaQuery.of(context).size.width < 700 && !collapsed) {
      sidebarWidth = 200;
    }
    final features = _getFeaturesList(context);

    return Drawer(
      child: Container(
        width: sidebarWidth,
        color: Colors.white,
        child: Column(
          children: [
            _buildHeaderSection(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ..._buildFeaturesSection(context, features),
                  const Divider(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _t(String key) {
    final provided = localizedStrings[key]?[lang];
    if (provided != null && provided.trim().isNotEmpty && provided != key) {
      return provided;
    }
    final langCode = lang == 'en' ? 'en' : 'ar';
    final defaults = _defaultTranslations[key];
    return defaults?[langCode] ?? defaults?['en'] ?? defaults?['ar'] ?? key;
  }

  List<Map<String, dynamic>> _getFeaturesList(BuildContext context) {
    return [
      {
        'icon': Icons.dashboard,
        'title': _t('home'),
        'onTap': () {
          Navigator.pop(context);
          onHome();
        },
      },
      {
        'icon': Icons.list_alt,
        'title': _t('waiting_list'),
        'onTap': () {
          Navigator.pop(context);
          onWaitingList();
        },
      },
      {
        'icon': Icons.assignment,
        'title': _t('xray_reports'),
        'onTap': () {
          Navigator.pop(context);
          onReports();
        },
      },
    ];
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildDefaultAvatar(),
              if (!collapsed) ...[
                const SizedBox(height: 10),
                Text(
                  userName.isNotEmpty ? userName : _t('xray_technician'),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  _t('xray_technician'),
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onClose,
              tooltip: _t('close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: collapsed ? 18 : 32,
      backgroundColor: Colors.white,
      child: Icon(Icons.person, size: collapsed ? 18 : 32, color: accentColor),
    );
  }

  List<Widget> _buildFeaturesSection(BuildContext context, List<Map<String, dynamic>> features) {
    return features.map((feature) {
      return _buildSidebarItem(
        context,
        icon: feature['icon'],
        label: feature['title'],
        onTap: feature['onTap'],
      );
    }).toList();
  }

  Widget _buildSidebarItem(BuildContext context, {required IconData icon, required String label, VoidCallback? onTap, Color? iconColor, Color? textColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? primaryColor),
      title: collapsed ? null : Text(label, style: TextStyle(color: textColor ?? Colors.black)),
      onTap: onTap,
      contentPadding: collapsed ? const EdgeInsets.symmetric(horizontal: 12) : null,
      minLeadingWidth: 0,
      horizontalTitleGap: collapsed ? 0 : null,
    );
  }
}
