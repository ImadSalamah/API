import 'package:flutter/material.dart';
import '../dashboard/admin_dashboard.dart';
import '../Admin/add_user_page.dart';
import '../Admin/add_student.dart';
import '../Admin/edit_user_page.dart';
import '../Admin/assign_patients_admin_page.dart';
import '../Admin/booking_settings_page.dart';
import '../dashboard/doctors_management_page.dart';

class AdminSidebar extends StatelessWidget {
  final Color primaryColor;
  final Color accentColor;
  final String? userName;
  final String? userImageUrl;
  final VoidCallback? onLogout;
  final BuildContext parentContext;
  final bool collapsed;
  final String Function(BuildContext, String)? translate;
  final List<Map<String, dynamic>>? allUsers;

  const AdminSidebar({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    this.userName,
    this.userImageUrl,
    this.onLogout,
    required this.parentContext,
    this.collapsed = false,
    this.translate,
    this.allUsers,
    required String userRole,
  });

  /// ✅ الترجمة الافتراضية داخل السايد بار
  String _defaultTranslate(BuildContext context, String key) {
    final Map<String, Map<String, String>> translations = {
      'home': {'ar': 'الرئيسية', 'en': 'Home'},
      'manage_users': {'ar': 'إدارة المستخدمين', 'en': 'Manage Users'},
      'add_user': {'ar': 'إضافة مستخدم', 'en': 'Add User'},
      'add_user_student': {'ar': 'إضافة طالب طب اسنان', 'en': 'Add Dental Student'},
      'assign_patients': {'ar': 'تعيين المرضى للطلاب', 'en': 'Assign Patients to Students'},
      'manage_doctors': {'ar': 'إدارة الأطباء', 'en': 'Manage Doctors'},
      'booking_table': {'ar': 'جدول الحجوزات', 'en': 'Booking Table'},
      'admin': {'ar': 'مدير النظام', 'en': 'System Admin'},
    };

    final langCode = Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'ar';
    final localizedValue = translations[key]?[langCode];

    // حاول إرجاع نفس لغة الواجهة الحالية، ثم الرجوع للإنجليزية، ثم العربية، وأخيراً المفتاح نفسه
    return localizedValue ??
        translations[key]?['en'] ??
        translations[key]?['ar'] ??
        key;
  }

  /// ✅ دالة الترجمة مع fallback الصحيح
  String _getTranslation(BuildContext context, String key) {
    final result = translate?.call(context, key);

    // الحالات التي تعتبر فشل ترجمة من الأب:
    if (result == null || result.trim().isEmpty || result == key) {
      return _defaultTranslate(context, key);
    }

    return result;
  }

  List<Map<String, dynamic>> _getFeaturesList(BuildContext context) {
    final usersList = allUsers ?? [];

    return [
      {
        'icon': Icons.home,
        'title': _getTranslation(context, 'home'),
        'onTap': () {
          Navigator.pop(context);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminDashboard(),
            ),
            (route) => false,
          );
        },
      },
      {
        'icon': Icons.people,
        'title': _getTranslation(context, 'manage_users'),
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditUserPage(
                user: const {},
                usersList: usersList,
                userName: userName,
                userImageUrl: userImageUrl,
                translate: (context, key) => _getTranslation(context, key),
                onLogout: onLogout ?? () {},
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.person_add,
        'title': _getTranslation(context, 'add_user'),
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddUserPage(
                userName: userName,
                userImageUrl: userImageUrl,
                translate: (context, key) => _getTranslation(context, key),
                onLogout: onLogout ?? () {},
                allUsers: usersList,
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.person_add_alt_1,
        'title': _getTranslation(context, 'add_user_student'),
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddDentalStudentPage(
                userName: userName,
                userImageUrl: userImageUrl,
                translate: (context, key) => _getTranslation(context, key),
                onLogout: onLogout ?? () {},
                allUsers: usersList,
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.assignment_ind,
        'title': _getTranslation(context, 'assign_patients'),
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssignPatientsAdminPage(
                userName: userName,
                userImageUrl: userImageUrl,
                onLogout: onLogout,
                allUsers: usersList,
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.medical_services,
        'title': _getTranslation(context, 'manage_doctors'),
        'onTap': () {
          final doctors = usersList.where((user) =>
            (user['role'] == 'doctor' || user['ROLE'] == 'doctor')
          ).map((e) => Map<String, dynamic>.from(e)).toList();

          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorsManagementPage(
                doctors: doctors,
                userName: userName,
                userImageUrl: userImageUrl,
                translate: (context, key) => _getTranslation(context, key),
                onLogout: onLogout ?? () {},
                allUsers: usersList,
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.table_chart,
        'title': _getTranslation(context, 'booking_table'),
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BookingSettingsPage(),
            ),
          );
        },
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final features = _getFeaturesList(context);

    return Drawer(
      child: Column(
        children: [
          _buildHeaderSection(context),
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
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
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
      child: Column(
        children: [
          _buildUserAvatar(context),
          if (!collapsed) ...[
            const SizedBox(height: 12),
            Text(
              userName ?? _getTranslation(context, 'admin'),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getTranslation(context, 'admin'),
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    final hasValidImage = userImageUrl != null &&
        userImageUrl!.isNotEmpty &&
        userImageUrl!.startsWith('http');

    if (hasValidImage) {
      return CircleAvatar(
        radius: collapsed ? 20 : 36,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.network(
            userImageUrl!,
            width: collapsed ? 40 : 72,
            height: collapsed ? 40 : 72,
            fit: BoxFit.cover,
            errorBuilder: (context, _, __) => _buildDefaultAvatar(),
          ),
        ),
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: collapsed ? 20 : 36,
      backgroundColor: Colors.white,
      child: Icon(
        Icons.person,
        size: collapsed ? 20 : 36,
        color: accentColor,
      ),
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

  Widget _buildSidebarItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          leading: Icon(icon, color: primaryColor),
          title: collapsed
              ? null
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
          onTap: onTap,
        ),
      ),
    );
  }
}
