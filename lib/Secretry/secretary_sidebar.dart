import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../providers/secretary_provider.dart';
import '../dashboard/secretary_dashboard.dart';
import 'all_patients_page.dart';
import '../Shared/waiting_list_page.dart';
import '../Shared/add_patient_page.dart';
import '../Admin/booking_settings_page.dart';
import 'account_approv.dart';

class SecretarySidebar extends StatelessWidget {
  final Color primaryColor;
  final Color accentColor;
  final String? userName;
  final String? userImageUrl;
  final VoidCallback? onLogout;
  final BuildContext parentContext;
  final bool collapsed;
  final String Function(BuildContext, String) translate;
  final int pendingAccountsCount;
  final String userRole;

  const SecretarySidebar({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    this.userName,
    this.userImageUrl,
    this.onLogout,
    required this.parentContext,
    this.collapsed = false,
    required this.translate,
    this.pendingAccountsCount = 0,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final secretaryProvider = Provider.of<SecretaryProvider>(context);
    double sidebarWidth = collapsed ? 60 : 250;
    if (MediaQuery.of(context).size.width < 700 && !collapsed) {
      sidebarWidth = 200;
    }

    return Drawer(
      child: Container(
        width: sidebarWidth,
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: primaryColor),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  (userImageUrl != null && userImageUrl!.isNotEmpty)
                      ? CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          backgroundImage: userImageUrl!.startsWith('data:image')
                              ? MemoryImage(base64Decode(userImageUrl!.split(',').last))
                              : NetworkImage(userImageUrl!) as ImageProvider,
                        )
                      : (secretaryProvider.imageBase64.isNotEmpty
                          ? CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white,
                              child: ClipOval(
                                child: Image.memory(
                                  base64Decode(secretaryProvider.imageBase64),
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person, size: 40, color: accentColor),
                            )),
                  if (!collapsed) ...[
                    const SizedBox(height: 10),
                    Text(
                      (userName != null && userName!.isNotEmpty)
                          ? userName!
                          : (secretaryProvider.fullName.isNotEmpty
                              ? secretaryProvider.fullName
                              : translate(context, 'secretary')),
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
                      translate(context, 'secretary'),
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
            _buildSidebarItem(
              context,
              icon: Icons.home,
              label: Localizations.localeOf(context).languageCode == 'ar' ? 'الرئيسية' : 'Home',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  parentContext,
                  MaterialPageRoute(builder: (context) => const SecretaryDashboard()),
                  (route) => false,
                );
              },
            ),
            _buildSidebarItem(
              context,
              icon: Icons.folder,
              label: Localizations.localeOf(context).languageCode == 'ar' ? 'ملفات المرضى' : 'Patient Files',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  parentContext,
                  MaterialPageRoute(builder: (context) => const PatientFilesPage(userRole: 'secretary')),
                );
              },
            ),
            _buildSidebarItem(
              context,
              icon: Icons.person_add,
              label: Localizations.localeOf(context).languageCode == 'ar' ? 'إضافة مريض' : 'Add Patient',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  parentContext,
                  MaterialPageRoute(builder: (context) => const AddPatientPage()),
                );
              },
            ),
            _buildSidebarItem(
              context,
              icon: Icons.verified_user,
              label: Localizations.localeOf(context).languageCode == 'ar' ? 'الموافقة على الحسابات' : 'Approve Accounts',
              badgeCount: pendingAccountsCount,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  parentContext,
                  MaterialPageRoute(builder: (context) => const AccountApprovalPage()),
                );
              },
            ),
            _buildSidebarItem(
              context,
              icon: Icons.list_alt,
              label: Localizations.localeOf(context).languageCode == 'ar' ? 'قائمة الانتظار' : 'Waiting List',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  parentContext,
                  MaterialPageRoute(
                    builder: (context) =>
                        const WaitingListPage(userRole: 'secretary'),
                  ),
                );
              },
            ),
            _buildSidebarItem(
              context,
              icon: Icons.calendar_today,
              label: Localizations.localeOf(context).languageCode == 'ar' ? 'جدول الحجوزات' : 'Booking Schedule',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  parentContext,
                  MaterialPageRoute(
                    builder: (context) => const BookingSettingsPage(),
                  ),
                );
              },
            ),
            const Divider(),
          
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    int badgeCount = 0,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Stack(
        children: [
          Icon(icon, color: iconColor ?? primaryColor),
          if (badgeCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: collapsed ? null : Text(label),
      onTap: onTap,
      contentPadding: collapsed ? const EdgeInsets.symmetric(horizontal: 12) : null,
      minLeadingWidth: 0,
      horizontalTitleGap: collapsed ? 0 : null,
    );
  }
}
