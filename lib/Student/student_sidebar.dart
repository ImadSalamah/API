import 'package:flutter/material.dart';
import '../dashboard/student_dashboard.dart';
import '../Student/examined_patients_page.dart';
import '../Student/student_add_patient_page.dart';
import '../Student/student_xray_upload_page.dart';

class StudentSidebar extends StatelessWidget {
  final Color primaryColor;
  final String? studentName;
  final String? studentImageUrl;
  final String? studentId;
  final List<String> allowedFeatures;

  const StudentSidebar({
    super.key,
    this.primaryColor = const Color(0xFF2A7A94),
    this.studentName,
    this.studentImageUrl,
    this.studentId,
    this.allowedFeatures = const [],
  });

  bool _isFeatureAllowed(String feature) {
    if (allowedFeatures.isEmpty) return true;
    if (allowedFeatures.contains(feature)) return true;
    // Backward compatible aliases
    if (feature == 'examined_patients' && allowedFeatures.contains('view_examinations')) return true;
    if (feature == 'upload_xray' && allowedFeatures.contains('xray_upload')) return true;
    return false;
  }

  String _translate(BuildContext context, String ar, String en) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? ar : en;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: primaryColor),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                studentImageUrl != null && studentImageUrl!.isNotEmpty
                    ? CircleAvatar(
                        radius: 32,
                        backgroundImage: NetworkImage(studentImageUrl!),
                      )
                    : CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 40, color: primaryColor),
                      ),
                const SizedBox(height: 10),
                Text(studentName ?? 'الطالب', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          // الرئيسية أول عنصر
          ListTile(
            leading: Icon(Icons.home, color: primaryColor),
            title: Text(_translate(context, 'الرئيسية', 'Home')),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const StudentDashboard()),
                (route) => false,
              );
            },
          ),
          if (_isFeatureAllowed('examined_patients'))
            ListTile(
              leading: Icon(Icons.assignment, color: primaryColor),
              title: Text(_translate(context, 'عرض الفحوصات', 'View Examinations')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentExaminedPatientsPage(
                      studentName: studentName,
                      studentImageUrl: studentImageUrl,
                      userAllowedFeatures: allowedFeatures,
                    ),
                  ),
                );
              },
            ),
          if (_isFeatureAllowed('add_patient'))
            ListTile(
              leading: Icon(Icons.person_add, color: primaryColor),
              title: Text(_translate(context, 'إضافة مريض', 'Add Patient')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StudentAddPatientPage()),
                );
              },
            ),
          if (_isFeatureAllowed('upload_xray'))
            ListTile(
              leading: Icon(Icons.cloud_upload, color: primaryColor),
              title: Text(_translate(context, 'رفع صور الأشعة', 'Upload X-ray')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentXrayUploadPage(
                      studentId: studentId ?? 'unknown_student_id',
                      studentName: studentName,
                      studentImageUrl: studentImageUrl,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
